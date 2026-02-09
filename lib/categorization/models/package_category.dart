/// Package category model
library;

/// Package category information
class PackageCategory {
  /// Creates a package category
  const PackageCategory({
    required this.name,
    required this.categories,
    required this.primaryCategory,
    required this.source,
    required this.confidence,
    required this.fetchedAt,
  });

  /// Create from JSON
  factory PackageCategory.fromJson(Map<String, dynamic> json) {
    try {
      final name = json['name']?.toString() ?? 'unknown';
      final categoriesList =
          List<String>.from(json['categories'] ?? <String>['Other']);
      final primaryCategory = json['primaryCategory']?.toString() ?? 'Other';
      final source = json['source']?.toString() ?? 'error';
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
      final fetchedAtStr = json['fetchedAt']?.toString();

      return PackageCategory(
        name: name,
        categories: categoriesList,
        primaryCategory: primaryCategory,
        source: source,
        confidence: confidence,
        fetchedAt: fetchedAtStr != null
            ? DateTime.tryParse(fetchedAtStr) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      // Return fallback on any parsing error
      return PackageCategory(
        name: json['name']?.toString() ?? 'unknown',
        categories: const <String>['Other'],
        primaryCategory: 'Other',
        source: 'error',
        confidence: 0.0,
        fetchedAt: DateTime.now(),
      );
    }
  }

  /// Package name
  final String name;

  /// All categories for this package
  final List<String> categories;

  /// Primary category
  final String primaryCategory;

  /// Source of the data (firestore, fluttergems, heuristic)
  final String source;

  /// Confidence score (0.0 to 1.0)
  final double confidence;

  /// When this data was fetched
  final DateTime fetchedAt;

  /// Convert to JSON for caching
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'categories': categories,
        'primaryCategory': primaryCategory,
        'source': source,
        'confidence': confidence,
        'fetchedAt': fetchedAt.toIso8601String(),
      };
}
