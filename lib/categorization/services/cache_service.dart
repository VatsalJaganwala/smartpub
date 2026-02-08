/// Local cache service for package categories
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../../core/config.dart';
import '../models/package_category.dart';

/// Service for managing local package category cache
class CacheService {
  /// Local cache data
  Map<String, PackageCategory>? _cache;

  /// Local cache directory (user-level)
  static String get _userCacheDir {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    return path.join(homeDir, CategorizationConfig.userCacheDirectory);
  }

  /// Local cache file path
  static String get _cacheFilePath =>
      path.join(_userCacheDir, CategorizationConfig.cacheFileName);

  /// Cache TTL in days
  static const int _cacheTtlDays = CategorizationConfig.cacheTtlDays;

  /// Initialize cache
  Future<void> initialize() async {
    await _ensureCacheDirectory();
    await _loadCache();
  }

  /// Get package from cache
  PackageCategory? get(String packageName) => _cache?[packageName];

  /// All cached package names (for refresh-from-remote flows)
  List<String> get keys => _cache?.keys.toList() ?? [];

  /// Check if cache entry is valid
  bool isValid(PackageCategory category) {
    final now = DateTime.now();
    final difference = now.difference(category.fetchedAt);
    return difference.inDays < _cacheTtlDays;
  }

  /// Save package to cache
  Future<void> save(String packageName, PackageCategory category) async {
    _cache ??= {};
    _cache![packageName] = category;
    await _writeCache();
  }

  /// Clear the cache
  Future<void> clear() async {
    _cache = {};
    final file = File(_cacheFilePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Ensure cache directory exists
  Future<void> _ensureCacheDirectory() async {
    final dir = Directory(_userCacheDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  /// Load cache from file
  Future<void> _loadCache() async {
    final file = File(_cacheFilePath);
    if (!file.existsSync()) {
      _cache = {};
      return;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      _cache = {};
      for (final entry in json.entries) {
        _cache![entry.key] = PackageCategory.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    } on Exception {
      _cache = {};
    }
  }

  /// Write cache to file
  Future<void> _writeCache() async {
    if (_cache == null) return;

    final file = File(_cacheFilePath);
    final json = <String, dynamic>{};

    for (final entry in _cache!.entries) {
      json[entry.key] = entry.value.toJson();
    }

    try {
      await file.writeAsString(jsonEncode(json));
    } on Exception {
      // Silently fail - cache write is not critical
    }
  }

  /// Get cache file path
  static String get cacheFilePath => _cacheFilePath;
}
