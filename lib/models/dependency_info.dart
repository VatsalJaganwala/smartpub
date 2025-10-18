/// Dependency Information Model
///
/// Contains information about a single dependency including its usage status,
/// location, and recommendations for optimization.
library;

/// Information about a single dependency
class DependencyInfo {

  DependencyInfo({
    required this.name,
    required this.version,
    required this.section,
    required this.status,
    required this.usedInLib,
    required this.usedInTest,
    required this.usedInBin,
    required this.usedInTool,
  });
  /// Package name
  final String name;

  /// Package version
  final String version;

  /// Which section it's currently in (dependencies or dev_dependencies)
  final DependencySection section;

  /// Current usage status
  final DependencyStatus status;

  /// Whether it's used in lib/ directory
  final bool usedInLib;

  /// Whether it's used in test/ directory
  final bool usedInTest;

  /// Whether it's used in bin/ directory
  final bool usedInBin;

  /// Whether it's used in tool/ directory
  final bool usedInTool;

  /// Get usage description
  String get usageDescription {
    final locations = <String>[];
    if (usedInLib) locations.add('lib');
    if (usedInTest) locations.add('test');
    if (usedInBin) locations.add('bin');
    if (usedInTool) locations.add('tool');

    if (locations.isEmpty) return 'unused';
    return 'used in ${locations.join(', ')}';
  }

  /// Get recommendation for this dependency
  String get recommendation {
    switch (status) {
      case DependencyStatus.used:
        return 'Keep in dependencies';
      case DependencyStatus.testOnly:
        if (section == DependencySection.dependencies) {
          return 'Move to dev_dependencies';
        } else {
          return 'Correctly placed in dev_dependencies';
        }
      case DependencyStatus.unused:
        return 'Remove (unused)';
    }
  }

  /// Whether this dependency needs action
  bool get needsAction => status == DependencyStatus.unused ||
        (status == DependencyStatus.testOnly &&
            section == DependencySection.dependencies);
}

/// Dependency status enumeration
enum DependencyStatus {
  /// Used in lib/ directory - properly placed
  used,

  /// Only used in test/, bin/, or tool/ - should be in dev_dependencies
  testOnly,

  /// Not used anywhere - should be removed
  unused,
}

/// Dependency section enumeration
enum DependencySection {
  /// Regular dependencies section
  dependencies,

  /// Development dependencies section
  devDependencies,
}

/// Extension to get display names for enums
extension DependencyStatusExtension on DependencyStatus {
  String get displayName {
    switch (this) {
      case DependencyStatus.used:
        return 'Used';
      case DependencyStatus.testOnly:
        return 'Test Only';
      case DependencyStatus.unused:
        return 'Unused';
    }
  }
}

extension DependencySectionExtension on DependencySection {
  String get displayName {
    switch (this) {
      case DependencySection.dependencies:
        return 'dependencies';
      case DependencySection.devDependencies:
        return 'dev_dependencies';
    }
  }
}
