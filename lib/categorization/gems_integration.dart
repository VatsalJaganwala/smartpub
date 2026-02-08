/// Package Categorization Integration
///
/// Provides package categorization with retrieval order:
/// **Local cache → API**. Data fetched from API is cached locally.
library;

import 'dart:io';
import 'package:path/path.dart' as path;

import '../core/config.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/package_categorizer.dart';

// Re-export for backward compatibility
export 'models/package_category.dart';

/// Package categorization using API with local cache
class GemsIntegration {
  /// Creates a new GemsIntegration instance
  GemsIntegration()
      : _cacheService = CacheService(),
        _apiService = const ApiService() {
    _categorizer = PackageCategorizer(
      cacheService: _cacheService,
      apiService: _apiService,
    );
  }

  late final CacheService _cacheService;
  late final ApiService _apiService;
  late final PackageCategorizer _categorizer;

  /// Initialize the integration service (load local cache)
  Future<void> initialize() async {
    await _categorizer.initialize();
  }

  /// Classify a package and return its primary category
  /// Retrieval order: local cache → API
  Future<String> classifyPackage(String packageName) async =>
      _categorizer.classifyPackage(packageName);

  /// Get all categories for a package
  /// Retrieval order: local cache → API
  Future<List<String>> getPackageCategories(String packageName) async =>
      _categorizer.getPackageCategories(packageName);

  /// Clear the user cache file
  static Future<void> clearCache() async {
    try {
      final String homeDir = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      final String cacheDir =
          path.join(homeDir, CategorizationConfig.userCacheDirectory);
      final String cacheFile =
          path.join(cacheDir, CategorizationConfig.cacheFileName);
      final File file = File(cacheFile);

      if (file.existsSync()) {
        await file.delete();
      }
    } on Exception {
      // Silently fail
    }
  }

  /// Get cache file path for external access
  static String get cacheFilePath {
    final String homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final String cacheDir =
        path.join(homeDir, CategorizationConfig.userCacheDirectory);
    return path.join(cacheDir, CategorizationConfig.cacheFileName);
  }
}
