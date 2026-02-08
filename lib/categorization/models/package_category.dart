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
  factory PackageCategory.fromJson(Map<String, dynamic> json) =>
      PackageCategory(
        name: json['name'] as String,
        categories: (json['categories'] as List<dynamic>).cast<String>(),
        primaryCategory: json['primaryCategory'] as String,
        source: json['source'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

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
