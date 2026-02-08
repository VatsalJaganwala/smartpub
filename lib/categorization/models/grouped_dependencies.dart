/// Grouped dependencies model
library;

import '../../core/models/dependency_info.dart';

/// Grouped dependencies data structure
class GroupedDependencies {
  /// Creates grouped dependencies
  const GroupedDependencies({
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
