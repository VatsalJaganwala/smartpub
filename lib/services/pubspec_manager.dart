/// Pubspec Manager
///
/// Handles reading and writing pubspec.yaml files while preserving comments,
/// formatting, and structure. Only modifies dependency sections when needed.
library;

import 'dart:io';
import 'package:yaml/yaml.dart';
import '../categorization/grouping_service.dart';
import '../core/config.dart';

/// Manager for pubspec.yaml file operations
class PubspecManager {
  /// Read and parse pubspec.yaml file
  static Future<PubspecData> readPubspec() async {
    final File file = File(FileConfig.pubspecFile);

    if (!file.existsSync()) {
      throw Exception('${FileConfig.pubspecFile} not found');
    }

    final String content = await file.readAsString();
    final Map yaml = Map<dynamic, dynamic>.from(
      loadYaml(content) ?? <dynamic, dynamic>{}
    );

    return PubspecData(
      originalContent: content,
      yaml: yaml,
    );
  }

  /// Apply dependency changes to pubspec.yaml while preserving structure
  static Future<bool> applyChanges(List<DependencyChange> changes) async {
    try {
      final pubspecData = await readPubspec();
      final lines = pubspecData.originalContent.split('\n');

      // Find dependency sections
      final dependenciesSection =
          _findSection(lines, AnalysisConfig.dependenciesSection);
      final devDependenciesSection =
          _findSection(lines, AnalysisConfig.devDependenciesSection);

      // Apply changes
      for (final change in changes) {
        switch (change.action) {
          case ChangeAction.remove:
            _removeDependency(lines, change.packageName, dependenciesSection,
                devDependenciesSection);
            break;
          case ChangeAction.moveToDevDependencies:
            _moveDependency(lines, change.packageName, dependenciesSection,
                devDependenciesSection);
            break;
          case ChangeAction.moveToDependencies:
            _moveDependency(lines, change.packageName, devDependenciesSection,
                dependenciesSection);
            break;
          case ChangeAction.removeFromDependencies:
            if (dependenciesSection != null) {
              _removeDependencyFromSection(
                  lines, change.packageName, dependenciesSection);
            }
            break;
          case ChangeAction.removeFromDevDependencies:
            if (devDependenciesSection != null) {
              _removeDependencyFromSection(
                  lines, change.packageName, devDependenciesSection);
            }
            break;
        }
      }

      // Write updated content
      final updatedContent = lines.join('\n');
      final file = File(FileConfig.pubspecFile);
      await file.writeAsString(updatedContent);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Find a section in the pubspec lines
  static SectionInfo? _findSection(List<String> lines, String sectionName) {
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

  /// Remove a dependency from the appropriate section
  static void _removeDependency(List<String> lines, String packageName,
      SectionInfo? dependenciesSection, SectionInfo? devDependenciesSection) {
    // Try to remove from dependencies section
    if (dependenciesSection != null) {
      _removeDependencyFromSection(lines, packageName, dependenciesSection);
    }

    // Try to remove from dev_dependencies section
    if (devDependenciesSection != null) {
      _removeDependencyFromSection(lines, packageName, devDependenciesSection);
    }
  }

  /// Remove a dependency from a specific section
  static void _removeDependencyFromSection(
      List<String> lines, String packageName, SectionInfo section) {
    for (int i = section.startIndex + 1; i <= section.endIndex; i++) {
      if (i >= lines.length) break;

      final line = lines[i];
      // Check if this line contains the package
      if (_lineContainsPackage(line, packageName)) {
        // Find all lines that belong to this dependency (including multi-line dependencies)
        final dependencyLines = findDependencyLines(lines, i, section.endIndex);

        // Remove all lines belonging to this dependency (in reverse order to maintain indices)
        for (int j = dependencyLines.length - 1; j >= 0; j--) {
          lines.removeAt(dependencyLines[j]);
          section.endIndex--;
        }
        break;
      }
    }
  }

  /// Move a dependency between sections
  static void _moveDependency(List<String> lines, String packageName,
      SectionInfo? fromSection, SectionInfo? toSection) {
    if (fromSection == null || toSection == null) return;

    List<String>? dependencyLines;

    // Find and remove from source section
    for (int i = fromSection.startIndex + 1; i <= fromSection.endIndex; i++) {
      if (i >= lines.length) break;

      final line = lines[i];
      if (_lineContainsPackage(line, packageName)) {
        // Find all lines that belong to this dependency (including multi-line dependencies)
        final dependencyLineIndices =
            findDependencyLines(lines, i, fromSection.endIndex);

        // Extract the dependency lines
        dependencyLines =
            dependencyLineIndices.map((int index) => lines[index]).toList();

        // Remove all lines belonging to this dependency (in reverse order to maintain indices)
        for (int j = dependencyLineIndices.length - 1; j >= 0; j--) {
          lines.removeAt(dependencyLineIndices[j]);
          fromSection.endIndex--;
        }
        break;
      }
    }

    // Add to target section
    if (dependencyLines != null && dependencyLines.isNotEmpty) {
      // Ensure target section exists
      if (toSection.name == AnalysisConfig.devDependenciesSection) {
        _ensureDevDependenciesSection(lines);
        // Re-find the section after creation
        final updatedSection =
            _findSection(lines, AnalysisConfig.devDependenciesSection);
        if (updatedSection != null) {
          toSection = updatedSection;
        }
      }

      // Find the best place to insert in the target section
      int insertIndex = toSection.endIndex + 1;

      // Try to maintain alphabetical order
      for (int i = toSection.startIndex + 1; i <= toSection.endIndex; i++) {
        if (i >= lines.length) break;

        final line = lines[i];
        if (_isDependencyLine(line)) {
          final existingPackage = _extractPackageName(line);
          if (existingPackage != null &&
              packageName.compareTo(existingPackage) < 0) {
            insertIndex = i;
            break;
          }
        }
      }

      // Insert all dependency lines
      for (int j = 0; j < dependencyLines.length; j++) {
        lines.insert(insertIndex + j, dependencyLines[j]);
        toSection.endIndex++;
      }
    }
  }

  /// Check if a line contains a specific package
  static bool _lineContainsPackage(String line, String packageName) {
    final trimmed = line.trim();
    return trimmed.startsWith('$packageName:') && _isDependencyLine(line);
  }

  /// Check if a line is a dependency line (not a comment or section header)
  static bool _isDependencyLine(String line) {
    final trimmed = line.trim();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('#') &&
        trimmed.contains(':') &&
        (line.startsWith('  ') || line.startsWith('\t')); // Indented
  }

  /// Extract package name from a dependency line
  static String? _extractPackageName(String line) {
    final trimmed = line.trim();
    final colonIndex = trimmed.indexOf(':');
    if (colonIndex > 0) {
      return trimmed.substring(0, colonIndex);
    }
    return null;
  }

  /// Find all lines that belong to a dependency (including multi-line dependencies)
  static List<int> findDependencyLines(
      List<String> lines, int startIndex, int sectionEndIndex) {
    final dependencyLines = <int>[startIndex];
    final startLine = lines[startIndex];
    final baseIndentation = _getIndentation(startLine);

    // Check if this is a multi-line dependency
    // Look for lines that are more indented than the package name line
    for (int i = startIndex + 1;
        i <= sectionEndIndex && i < lines.length;
        i++) {
      final line = lines[i];
      final currentIndentation = _getIndentation(line);

      // If this line is more indented than the package line, it belongs to this dependency
      if (currentIndentation > baseIndentation && line.trim().isNotEmpty) {
        dependencyLines.add(i);
      } else if (line.trim().isEmpty) {
        // Empty line - could be part of the dependency or separator
        // Only include if the next non-empty line is still part of this dependency
        bool includeEmptyLine = false;
        for (int j = i + 1; j <= sectionEndIndex && j < lines.length; j++) {
          final nextLine = lines[j];
          if (nextLine.trim().isNotEmpty) {
            final nextIndentation = _getIndentation(nextLine);
            if (nextIndentation > baseIndentation) {
              includeEmptyLine = true;
            }
            break;
          }
        }
        if (includeEmptyLine) {
          dependencyLines.add(i);
        } else {
          break; // Empty line followed by same/less indented line - end of dependency
        }
      } else {
        // If we hit a line with same or less indentation, we've reached the next dependency
        break;
      }
    }

    return dependencyLines;
  }

  /// Get the indentation level of a line
  static int _getIndentation(String line) {
    int indentation = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ' ') {
        indentation++;
      } else if (line[i] == '\t') {
        indentation += 2; // Count tab as 2 spaces
      } else {
        break;
      }
    }
    return indentation;
  }

  /// Create dev_dependencies section if it doesn't exist
  static void _ensureDevDependenciesSection(List<String> lines) {
    // Check if dev_dependencies section exists
    final devSection =
        _findSection(lines, AnalysisConfig.devDependenciesSection);
    if (devSection != null) return;

    // Find dependencies section to add dev_dependencies after it
    final depsSection = _findSection(lines, AnalysisConfig.dependenciesSection);
    if (depsSection != null) {
      // Add dev_dependencies section after dependencies
      final insertIndex = depsSection.endIndex + 1;
      lines.insert(insertIndex, '');
      lines.insert(insertIndex + 1, 'dev_dependencies:');
    } else {
      // Add at the end of file
      lines.add('');
      lines.add('dev_dependencies:');
    }
  }
}

/// Data structure for pubspec content
class PubspecData {
  PubspecData({
    required this.originalContent,
    required this.yaml,
  });
  final String originalContent;
  final Map yaml;
}

/// Represents a change to be made to dependencies
class DependencyChange {
  DependencyChange({
    required this.packageName,
    required this.action,
    this.version,
  });
  final String packageName;
  final ChangeAction action;
  final String? version;
}

/// Types of changes that can be made to dependencies
enum ChangeAction {
  remove,
  moveToDevDependencies,
  moveToDependencies,
  removeFromDependencies,
  removeFromDevDependencies,
}
