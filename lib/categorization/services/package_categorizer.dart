/// Simple package categorization service
library;

import '../models/package_category.dart';
import 'api_service.dart';
import 'cache_service.dart';

/// Categorizes packages using: **local cache → API**.
class PackageCategorizer {
  /// Creates a package categorizer
  PackageCategorizer({
    required this.cacheService,
    required this.apiService,
  });

  /// Local cache service
  final CacheService cacheService;

  /// API service
  final ApiService apiService;

  /// Initialize the categorizer (load local cache)
  Future<void> initialize() async {
    await cacheService.initialize();
  }

  /// Classify a package and return its primary category
  /// Order: local cache → API
  Future<String> classifyPackage(String packageName) async {
    // Step 1: Check local cache first
    final PackageCategory? cached = cacheService.get(packageName);
    if (cached != null && cacheService.isValid(cached)) {
      return cached.primaryCategory;
    }

    // Step 2: Fetch from API (API has built-in heuristic fallback)
    final PackageCategory? apiCategory =
        await apiService.fetchPackage(packageName);
    if (apiCategory != null) {
      await cacheService.save(packageName, apiCategory);
      return apiCategory.primaryCategory;
    }

    // Fallback if API fails
    return 'Miscellaneous';
  }

  /// Get all categories for a package
  /// Order: local cache → API
  Future<List<String>> getPackageCategories(String packageName) async {
    // Step 1: Check local cache first
    final PackageCategory? cached = cacheService.get(packageName);
    if (cached != null && cacheService.isValid(cached)) {
      return cached.categories;
    }

    // Step 2: Fetch from API (API has built-in heuristic fallback)
    final PackageCategory? apiCategory =
        await apiService.fetchPackage(packageName);
    if (apiCategory != null) {
      await cacheService.save(packageName, apiCategory);
      return apiCategory.categories;
    }

    // Fallback if API fails
    return <String>['Miscellaneous'];
  }

  /// Clear the local cache
  Future<void> clearCache() async {
    await cacheService.clear();
  }
}
