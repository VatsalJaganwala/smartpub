/// SmartPub Dependency Analyzer
///
/// Core analysis engine that scans Dart files and detects dependency usage
/// patterns to identify unused, misplaced, and duplicate dependencies.
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:glob/glob.dart';
import '../core/config.dart';
import '../core/models/dependency_info.dart';
import '../core/models/smartpub_config.dart';

/// Main dependency analyzer class
class DependencyAnalyzer {
  DependencyAnalyzer({this.config = const SmartpubConfig()});

  /// Config settings from smartpub.yaml
  final SmartpubConfig config;

  /// Analyze dependencies in the current project
  Future<AnalysisResult> analyze() async {
    final File pubspecFile = File(FileConfig.pubspecFile);

    if (!pubspecFile.existsSync()) {
      throw Exception('${FileConfig.pubspecFile} not found');
    }

    // Parse pubspec.yaml
    final String pubspecContent = await pubspecFile.readAsString();
    final Map pubspec = Map<dynamic, dynamic>.from(
        loadYaml(pubspecContent) ?? <dynamic, dynamic>{});

    // Extract dependencies
    final Map<String, dynamic> dependencies = _extractDependencies(pubspec);
    final Map<String, dynamic> devDependencies =
        _extractDevDependencies(pubspec);

    // Scan Dart files for imports
    final Map<String, PackageUsage> usageMap = await _scanDartFiles();

    // Analyze each dependency
    final List<DependencyInfo> results = <DependencyInfo>[];

    // Analyze regular dependencies
    for (final String dep in dependencies.keys) {
      final PackageUsage? usage = usageMap[dep];

      if (dep == AnalysisConfig.flutterSdk) {
        final DependencyInfo info = DependencyInfo(
          name: dep,
          version: 'sdk: flutter',
          section: DependencySection.dependencies,
          status: DependencyStatus.used,
          usedInLib: true,
          usedInTest: false,
          usedInBin: false,
          usedInTool: false,
        );
        results.add(info);
        continue;
      }

      final DependencyInfo info = DependencyInfo(
        name: dep,
        version: dependencies[dep].toString(),
        section: DependencySection.dependencies,
        status: _determineDependencyStatus(dep, usage),
        usedInLib: usage?.usedInLib ?? false,
        usedInTest: usage?.usedInTest ?? false,
        usedInBin: usage?.usedInBin ?? false,
        usedInTool: usage?.usedInTool ?? false,
      );
      results.add(info);
    }

    // Analyze dev dependencies
    for (final String dep in devDependencies.keys) {
      final PackageUsage? usage = usageMap[dep];

      if (dep == AnalysisConfig.flutterSdk) {
        final DependencyInfo info = DependencyInfo(
          name: dep,
          version: 'sdk: flutter',
          section: DependencySection.devDependencies,
          status: DependencyStatus.used,
          usedInLib: true,
          usedInTest: false,
          usedInBin: false,
          usedInTool: false,
        );
        results.add(info);
        continue;
      }

      final DependencyInfo info = DependencyInfo(
        name: dep,
        version: devDependencies[dep].toString(),
        section: DependencySection.devDependencies,
        status: _determineDevDependencyStatus(dep, usage),
        usedInLib: usage?.usedInLib ?? false,
        usedInTest: usage?.usedInTest ?? false,
        usedInBin: usage?.usedInBin ?? false,
        usedInTool: usage?.usedInTool ?? false,
      );
      results.add(info);
    }

    // Check for duplicates
    final List<DuplicateDependency> duplicates =
        _findDuplicates(dependencies, devDependencies, usageMap);

    return AnalysisResult(
      dependencies: results,
      duplicates: duplicates,
      totalScanned: results.length,
    );
  }

  /// Extract dependencies from pubspec
  Map<String, dynamic> _extractDependencies(Map pubspec) {
    final dynamic deps = pubspec[AnalysisConfig.dependenciesSection];
    if (deps == null || deps is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(deps);
  }

  /// Extract dev dependencies from pubspec
  Map<String, dynamic> _extractDevDependencies(Map pubspec) {
    final dynamic deps = pubspec[AnalysisConfig.devDependenciesSection];
    if (deps == null || deps is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(deps);
  }

  /// Scan all Dart files for package imports
  Future<Map<String, PackageUsage>> _scanDartFiles() async {
    final Map<String, PackageUsage> usageMap = <String, PackageUsage>{};
    final RegExp importRegex = RegExp(AnalysisConfig.importPattern);

    // Compile exclude globs
    final List<Glob> excludeGlobs =
        config.exclude.map((String pattern) => Glob(pattern)).toList();

    // Scan each directory
    for (final String dir in FileConfig.scanDirectories) {
      final Directory directory = Directory(dir);
      if (!directory.existsSync()) continue;

      // Recursively find all Dart files
      await for (final FileSystemEntity entity
          in directory.list(recursive: true)) {
        if (entity is File && entity.path.endsWith(FileConfig.dartExtension)) {
          // Check if file is excluded
          final String relativePath = path.relative(entity.path);
          final String normalizedPath =
              relativePath.replaceAll(path.separator, '/');
          if (excludeGlobs.any((Glob glob) => glob.matches(normalizedPath))) {
            continue;
          }

          final String content = await entity.readAsString();
          final Iterable<RegExpMatch> matches = importRegex.allMatches(content);

          for (final RegExpMatch match in matches) {
            final String? packageName = match.group(1);
            if (packageName == null) continue;

            final PackageUsage usage = usageMap.putIfAbsent(
              packageName,
              () => PackageUsage(packageName: packageName),
            );

            // Determine which directory this file is in
            final String relativePath = path.relative(entity.path);

            if (relativePath.startsWith('lib${path.separator}') ||
                relativePath.startsWith('lib/')) {
              usage.usedInLib = true;
            } else if (relativePath.startsWith('test${path.separator}') ||
                relativePath.startsWith('test/')) {
              usage.usedInTest = true;
            } else if (relativePath.startsWith('bin${path.separator}') ||
                relativePath.startsWith('bin/')) {
              usage.usedInBin = true;
            } else if (relativePath.startsWith('tool${path.separator}') ||
                relativePath.startsWith('tool/')) {
              usage.usedInTool = true;
            }
          }
        }
      }
    }

    return usageMap;
  }

  /// Determine the status of a dependency based on usage
  DependencyStatus _determineDependencyStatus(
      String packageName, PackageUsage? usage) {
    if (config.ignore.contains(packageName)) {
      return DependencyStatus.used;
    }

    if (usage == null) {
      return config.checks.unused
          ? DependencyStatus.unused
          : DependencyStatus.used;
    }

    // If used in lib/ or bin/, it should stay in main dependencies
    // bin/ usage means it's needed for the executable, so it stays in dependencies
    if (usage.usedInLib || usage.usedInBin) {
      return DependencyStatus.used;
    }

    // If only used in test/ or tool/, it should be in dev_dependencies
    if (usage.usedInTest || usage.usedInTool) {
      return config.checks.promotions
          ? DependencyStatus.testOnly
          : DependencyStatus.used;
    }

    return config.checks.unused
        ? DependencyStatus.unused
        : DependencyStatus.used;
  }

  /// Determine the status of a dev dependency based on usage
  /// For dev dependencies, we only care if they should be moved to dependencies
  DependencyStatus _determineDevDependencyStatus(
      String packageName, PackageUsage? usage) {
    if (config.ignore.contains(packageName)) {
      return DependencyStatus.used;
    }

    if (usage == null) {
      // For dev dependencies, unused is acceptable - return used to avoid flagging
      return DependencyStatus.used;
    }

    // If used in lib/ or bin/, it should be moved to main dependencies
    if (usage.usedInLib || usage.usedInBin) {
      return config.checks.promotions
          ? DependencyStatus.testOnly
          : DependencyStatus
              .used; // This will trigger "move to dependencies" recommendation
    }

    // If only used in test/ or tool/, it's correctly placed in dev_dependencies
    // If unused, it's also acceptable for dev dependencies
    return DependencyStatus.used;
  }

  /// Find duplicate dependencies (in both dependencies and dev_dependencies)
  List<DuplicateDependency> _findDuplicates(Map<String, dynamic> deps,
      Map<String, dynamic> devDeps, Map<String, PackageUsage> usageMap) {
    final List<DuplicateDependency> duplicates = <DuplicateDependency>[];

    for (final String dep in deps.keys) {
      if (devDeps.containsKey(dep) && dep != AnalysisConfig.flutterSdk) {
        final PackageUsage? usage = usageMap[dep];
        final DependencySection recommendedSection =
            _getRecommendedSection(dep, usage);

        duplicates.add(DuplicateDependency(
          name: dep,
          dependenciesVersion: deps[dep].toString(),
          devDependenciesVersion: devDeps[dep].toString(),
          recommendedSection: recommendedSection,
          usage: usage,
        ));
      }
    }

    return duplicates;
  }

  /// Get recommended section for a duplicate dependency
  DependencySection _getRecommendedSection(
      String packageName, PackageUsage? usage) {
    if (usage == null) {
      // If unused, recommend dev_dependencies (safer default)
      return DependencySection.devDependencies;
    }

    // If used in lib/, it should be in dependencies
    if (usage.usedInLib) {
      return DependencySection.dependencies;
    }

    // If only used in test/, bin/, or tool/, it should be in dev_dependencies
    if (usage.usedInTest || usage.usedInBin || usage.usedInTool) {
      return DependencySection.devDependencies;
    }

    // Default to dev_dependencies for unused
    return DependencySection.devDependencies;
  }
}

/// Package usage tracking
class PackageUsage {
  PackageUsage({required this.packageName});

  final String packageName;
  bool usedInLib = false;
  bool usedInTest = false;
  bool usedInBin = false;
  bool usedInTool = false;

  bool get isUsed => usedInLib || usedInTest || usedInBin || usedInTool;
}

/// Analysis result container
class AnalysisResult {
  AnalysisResult({
    required this.dependencies,
    required this.duplicates,
    required this.totalScanned,
  });

  final List<DependencyInfo> dependencies;
  final List<DuplicateDependency> duplicates;
  final int totalScanned;

  /// Get dependencies by status
  List<DependencyInfo> getDependenciesByStatus(DependencyStatus status) =>
      dependencies.where((DependencyInfo dep) => dep.status == status).toList();

  /// Get used dependencies
  List<DependencyInfo> get usedDependencies =>
      getDependenciesByStatus(DependencyStatus.used);

  /// Get test-only dependencies
  List<DependencyInfo> get testOnlyDependencies =>
      getDependenciesByStatus(DependencyStatus.testOnly);

  /// Get unused dependencies
  List<DependencyInfo> get unusedDependencies =>
      getDependenciesByStatus(DependencyStatus.unused);

  /// Check if there are any issues
  bool get hasIssues {
    // Check for dependencies that need action
    final bool needsAction =
        dependencies.any((DependencyInfo dep) => dep.needsAction);
    return needsAction || duplicates.isNotEmpty;
  }
}

/// Information about a duplicate dependency
class DuplicateDependency {
  DuplicateDependency({
    required this.name,
    required this.dependenciesVersion,
    required this.devDependenciesVersion,
    required this.recommendedSection,
    this.usage,
  });

  final String name;
  final String dependenciesVersion;
  final String devDependenciesVersion;
  final DependencySection recommendedSection;
  final PackageUsage? usage;

  /// Get usage description
  String get usageDescription {
    if (usage == null) return 'unused';

    final List<String> locations = <String>[];
    if (usage!.usedInLib) locations.add('lib');
    if (usage!.usedInTest) locations.add('test');
    if (usage!.usedInBin) locations.add('bin');
    if (usage!.usedInTool) locations.add('tool');

    if (locations.isEmpty) return 'unused';
    return 'used in ${locations.join(', ')}';
  }

  /// Get recommendation message
  String get recommendationMessage {
    final String sectionName =
        recommendedSection == DependencySection.dependencies
            ? 'dependencies'
            : 'dev_dependencies';
    return 'Keep in $sectionName ($usageDescription)';
  }

  /// Whether versions are different
  bool get hasVersionConflict => dependenciesVersion != devDependenciesVersion;
}
