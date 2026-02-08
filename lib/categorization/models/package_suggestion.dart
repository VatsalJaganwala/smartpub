/// Package suggestion model
library;

/// Package suggestion data structure
class PackageSuggestion {
  /// Creates a package suggestion
  const PackageSuggestion({
    required this.packageName,
    required this.categories,
    this.notes,
  });

  /// Package name
  final String packageName;

  /// Suggested categories
  final List<String> categories;

  /// Optional notes
  final String? notes;
}
