/// Package Grouping Service
///
/// Handles grouping of dependencies by categories and rendering grouped
/// pubspec.yaml with category comment headers.
library;

import 'dart:io';
import 'package:yaml/yaml.dart';
import '../core/config.dart';
import '../core/models/dependency_info.dart';
import '../categorization/gems_integration.dart';

/// Service for grouping dependencies by categories
class GroupingService {
  GroupingService({
    required this.gemsIntegration,
    this.groupOverrides,
  });

  /// Gems integration service
  final GemsIntegration gemsIntegration;

  /// Local overrides for package categories
  final Map<String, String>? groupOverrides;

  /// Group dependencies by categories
  Future<GroupedDependencies> groupDependencies(
    List<DependencyInfo> dependencies,
  ) async {
    final grouped = <String, List<DependencyInfo>>{};
    final categoryOrder = <String>[];

    for (final dep in dependencies) {
      String category;

      // Check for local override first
      if (groupOverrides != null && groupOverrides!.containsKey(dep.name)) {
        category = groupOverrides![dep.name]!;
      } else {
        // Use gems integration to classify
        category = await gemsIntegration.classifyPackage(dep.name);
      }

      // Add to grouped map
      if (!grouped.containsKey(category)) {
        grouped[category] = <DependencyInfo>[];
        categoryOrder.add(category);
      }
      grouped[category]!.add(dep);
    }

    // Sort packages within each category alphabetically
    for (final categoryDeps in grouped.values) {
      categoryDeps.sort((a, b) => a.name.compareTo(b.name));
    }

    // Sort categories by priority
    categoryOrder.sort(_compareCategoryPriority);

    return GroupedDependencies(
      grouped: grouped,
      categoryOrder: categoryOrder,
    );
  }

  /// Generate grouped pubspec.yaml content
  Future<String> generateGroupedPubspec(
    GroupedDependencies groupedDeps,
    GroupedDependencies groupedDevDeps,
  ) async {
    final pubspecFile = File(FileConfig.pubspecFile);
    if (!pubspecFile.existsSync()) {
      throw Exception('${FileConfig.pubspecFile} not found');
    }

    final originalContent = await pubspecFile.readAsString();
    final lines = originalContent.split('\n');

    // Find dependency sections
    final dependenciesSection = _findSection(lines, 'dependencies');
    final devDependenciesSection = _findSection(lines, 'dev_dependencies');

    // Replace dev_dependencies section first (to avoid index shifting issues)
    if (devDependenciesSection != null && groupedDevDeps.grouped.isNotEmpty) {
      _replaceDependencySection(
        lines,
        devDependenciesSection,
        groupedDevDeps,
        'dev_dependencies',
      );
    }

    // Re-find dependencies section after potential changes
    final updatedDependenciesSection = _findSection(lines, 'dependencies');

    // Replace dependencies section
    if (updatedDependenciesSection != null && groupedDeps.grouped.isNotEmpty) {
      _replaceDependencySection(
        lines,
        updatedDependenciesSection,
        groupedDeps,
        'dependencies',
      );
    }

    return lines.join('\n');
  }

  /// Generate preview of grouped dependencies
  String generatePreview(
    GroupedDependencies groupedDeps,
    GroupedDependencies groupedDevDeps,
  ) {
    final buffer = StringBuffer();

    if (groupedDeps.grouped.isNotEmpty) {
      buffer.writeln('dependencies:');
      _writeGroupedSection(buffer, groupedDeps);
      buffer.writeln();
    }

    if (groupedDevDeps.grouped.isNotEmpty) {
      buffer.writeln('dev_dependencies:');
      _writeGroupedSection(buffer, groupedDevDeps);
    }

    return buffer.toString();
  }

  /// Write grouped section to buffer
  void _writeGroupedSection(StringBuffer buffer, GroupedDependencies grouped) {
    for (final category in grouped.categoryOrder) {
      final deps = grouped.grouped[category]!;
      if (deps.isEmpty) continue;

      // Add category comment header
      buffer.writeln('  # $category');

      for (final dep in deps) {
        buffer.writeln('  ${dep.name}: ${dep.version}');
      }

      // Add empty line between categories (except for last)
      if (category != grouped.categoryOrder.last) {
        buffer.writeln();
      }
    }
  }

  /// Replace dependency section with grouped version
  void _replaceDependencySection(
    List<String> lines,
    SectionInfo section,
    GroupedDependencies grouped,
    String sectionName,
  ) {
    // Remove existing dependency lines (keep section header)
    final linesToRemove = <int>[];
    for (int i = section.startIndex + 1; i <= section.endIndex; i++) {
      if (i < lines.length) {
        final line = lines[i];
        // Only remove lines that are dependencies or empty lines within the section
        if (line.trim().isEmpty ||
            (line.startsWith('  ') && !line.trim().startsWith('#')) ||
            (line.startsWith('\t') && !line.trim().startsWith('#'))) {
          linesToRemove.add(i);
        }
      }
    }

    // Remove lines in reverse order to maintain indices
    for (int i = linesToRemove.length - 1; i >= 0; i--) {
      lines.removeAt(linesToRemove[i]);
    }

    // Add grouped dependencies
    int insertIndex = section.startIndex + 1;

    for (final category in grouped.categoryOrder) {
      final deps = grouped.grouped[category]!;
      if (deps.isEmpty) continue;

      // Add category comment header
      lines.insert(insertIndex++, '  # $category');

      for (final dep in deps) {
        lines.insert(insertIndex++, '  ${dep.name}: ${dep.version}');
      }

      // Add empty line between categories (except for last)
      if (category != grouped.categoryOrder.last) {
        lines.insert(insertIndex++, '');
      }
    }
  }

  /// Find a section in the pubspec lines
  SectionInfo? _findSection(List<String> lines, String sectionName) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      // Check if this line is the section header (no indentation)
      if (line.trim() == '$sectionName:' &&
          !line.startsWith(' ') &&
          !line.startsWith('\t')) {
        // Find the end of this section
        int endIndex = lines.length - 1;

        for (int j = i + 1; j < lines.length; j++) {
          final nextLine = lines[j];
          // If we hit a line that starts at column 0 and isn't empty/comment, it's a new section
          if (nextLine.isNotEmpty &&
              !nextLine.startsWith(' ') &&
              !nextLine.startsWith('\t') &&
              !nextLine.startsWith('#') &&
              nextLine.trim().endsWith(':')) {
            endIndex = j - 1;
            break;
          }
        }

        return SectionInfo(
          name: sectionName,
          startIndex: i,
          endIndex: endIndex,
        );
      }
    }
    return null;
  }

  /// Compare category priority for sorting
  int _compareCategoryPriority(String a, String b) {
    const priorityOrder = [
      'State Management',
      'Networking',
      'HTTP Clients',
      'Database',
      'Storage',
      'UI Components',
      'Widgets',
      'Navigation',
      'Authentication',
      'Firebase',
      'Animation',
      'Charts',
      'Forms',
      'Maps',
      'Camera',
      'Image Processing',
      'Audio',
      'Video',
      'Testing',
      'Development Tools',
      'Utilities',
      'Miscellaneous',
    ];

    final indexA = priorityOrder.indexOf(a);
    final indexB = priorityOrder.indexOf(b);

    // If both categories are in the priority list, use their order
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }

    // If only one is in the priority list, it comes first
    if (indexA != -1) return -1;
    if (indexB != -1) return 1;

    // If neither is in the priority list, sort alphabetically
    return a.compareTo(b);
  }
}

/// Grouped dependencies data structure
class GroupedDependencies {
  GroupedDependencies({
    required this.grouped,
    required this.categoryOrder,
  });

  /// Dependencies grouped by category
  final Map<String, List<DependencyInfo>> grouped;

  /// Order of categories
  final List<String> categoryOrder;

  /// Get total number of packages
  int get totalPackages => grouped.values
      .fold(0, (int sum, List<DependencyInfo> deps) => sum + deps.length);

  /// Get number of categories
  int get categoryCount => grouped.length;
}

/// Section information for pubspec parsing
class SectionInfo {
  SectionInfo({
    required this.name,
    required this.startIndex,
    required this.endIndex,
  });

  /// Section name
  final String name;

  /// Start line index
  final int startIndex;

  /// End line index
  int endIndex;
}

/// Load group overrides from file
Future<Map<String, String>?> loadGroupOverrides() async {
  final file = File('group-overrides.yaml');
  if (!file.existsSync()) {
    return null;
  }

  try {
    final content = await file.readAsString();
    final yaml = loadYaml(content) as Map?;

    if (yaml == null) return null;

    final overrides = <String, String>{};
    for (final entry in yaml.entries) {
      overrides[entry.key.toString()] = entry.value.toString();
    }

    return overrides;
  } catch (e) {
    return null;
  }
}

/// Save group overrides to file
Future<void> saveGroupOverrides(Map<String, String> overrides) async {
  final file = File('group-overrides.yaml');

  final buffer = StringBuffer();
  buffer.writeln('# Package category overrides');
  buffer.writeln('# Format: package_name: Category Name');
  buffer.writeln();

  final sortedKeys = overrides.keys.toList()..sort();
  for (final key in sortedKeys) {
    buffer.writeln('$key: ${overrides[key]}');
  }

  await file.writeAsString(buffer.toString());
}
