/// FlutterGems Integration
///
/// Provides package categorization using FlutterGems as the primary source,
/// with Firestore as a canonical cache and local caching for performance.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

import '../core/config.dart';

/// Package categorization service using FlutterGems data
class GemsIntegration {
  /// Creates a new GemsIntegration instance
  ///
  /// By default, FlutterGems integration is enabled when grouping packages.
  /// Users can disable it using the --no-use-gems flag.
  GemsIntegration({
    this.useGems = CategorizationConfig.defaultUseGems,
    this.updateCache = CategorizationConfig.defaultUpdateCache,
    this.fetchGemsFallback = CategorizationConfig.defaultFetchGemsFallback,
    this.firestoreProjectId = CategorizationConfig.defaultFirestoreProjectId,
  });

  /// Creates a GemsIntegration instance with gems integration disabled
  ///
  /// This factory constructor is used when the user explicitly disables
  /// FlutterGems integration via command line flags.
  factory GemsIntegration.disabled() {
    return GemsIntegration(
      useGems: false,
      updateCache: false,
      fetchGemsFallback: false,
    );
  }

  /// Creates a GemsIntegration instance from command line arguments
  ///
  /// This factory constructor should be used by the CLI to create instances
  /// based on user-provided flags, with proper defaults.
  factory GemsIntegration.fromArgs({
    bool? useGems,
    bool? updateCache,
    bool? fetchGemsFallback,
    String? firestoreProjectId,
  }) {
    return GemsIntegration(
      useGems: useGems ?? CategorizationConfig.defaultUseGems,
      updateCache: updateCache ?? CategorizationConfig.defaultUpdateCache,
      fetchGemsFallback:
          fetchGemsFallback ?? CategorizationConfig.defaultFetchGemsFallback,
      firestoreProjectId:
          firestoreProjectId ?? CategorizationConfig.defaultFirestoreProjectId,
    );
  }

  /// Whether to use FlutterGems categorization (default: true)
  final bool useGems;

  /// Whether to force update local cache from Firestore (default: false)
  final bool updateCache;

  /// Whether to allow fallback to realtime FlutterGems fetch (default: false)
  final bool fetchGemsFallback;

  /// Firestore project ID for package data
  final String firestoreProjectId;

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

  /// Local cache data
  Map<String, PackageCategory>? _localCache;

  /// Initialize the gems integration service
  Future<void> initialize() async {
    if (!useGems) return;

    await _ensureCacheDirectory();
    await _loadLocalCache();

    if (updateCache) {
      await _refreshCacheFromFirestore();
    }
  }

  /// Classify a package and return its primary category
  Future<String> classifyPackage(String packageName) async {
    if (!useGems) {
      return _inferCategoryByName(packageName);
    }

    // Step 1: Check local cache first
    if (_localCache != null && _localCache!.containsKey(packageName)) {
      final cached = _localCache![packageName]!;
      if (_isCacheValid(cached.fetchedAt)) {
        return cached.primaryCategory;
      }
    }

    // Step 2: Try Firestore
    final firestoreDoc = await _fetchFirestorePackage(packageName);
    if (firestoreDoc != null) {
      await _writeToLocalCache(packageName, firestoreDoc);
      return firestoreDoc.primaryCategory;
    }

    // Step 3: Fallback to realtime FlutterGems if enabled
    if (fetchGemsFallback) {
      final gemsCategories = await _fetchFlutterGemsPage(packageName);
      if (gemsCategories != null && gemsCategories.isNotEmpty) {
        final primaryCategory = _choosePrimaryCategory(gemsCategories);

        final packageCategory = PackageCategory(
          name: packageName,
          categories: gemsCategories,
          primaryCategory: primaryCategory,
          source: 'fluttergems',
          confidence: 0.8,
          fetchedAt: DateTime.now(),
        );

        // Save to both local cache and Firebase
        await _writeToLocalCache(packageName, packageCategory);
        await _saveToFirestore(packageCategory);

        return primaryCategory;
      }
    }

    // Final fallback to heuristics
    final inferredCategory = _inferCategoryByName(packageName);

    final heuristicCategory = PackageCategory(
      name: packageName,
      categories: <String>[inferredCategory],
      primaryCategory: inferredCategory,
      source: 'heuristic',
      confidence: 0.5,
      fetchedAt: DateTime.now(),
    );

    // Save heuristic result to local cache only (not Firebase)
    await _writeToLocalCache(packageName, heuristicCategory);

    return inferredCategory;
  }

  /// Get all categories for a package (for interactive overrides)
  Future<List<String>> getPackageCategories(String packageName) async {
    if (!useGems) {
      return <String>[_inferCategoryByName(packageName)];
    }

    // Step 1: Check local cache first
    if (_localCache != null && _localCache!.containsKey(packageName)) {
      final cached = _localCache![packageName]!;
      if (_isCacheValid(cached.fetchedAt)) {
        return cached.categories;
      }
    }

    // Step 2: Try Firestore
    final firestoreDoc = await _fetchFirestorePackage(packageName);
    if (firestoreDoc != null) {
      await _writeToLocalCache(packageName, firestoreDoc);
      return firestoreDoc.categories;
    }

    // Step 3: Fallback to realtime FlutterGems if enabled
    if (fetchGemsFallback) {
      final gemsCategories = await _fetchFlutterGemsPage(packageName);
      if (gemsCategories != null && gemsCategories.isNotEmpty) {
        final primaryCategory = _choosePrimaryCategory(gemsCategories);

        final packageCategory = PackageCategory(
          name: packageName,
          categories: gemsCategories,
          primaryCategory: primaryCategory,
          source: 'fluttergems',
          confidence: 0.8,
          fetchedAt: DateTime.now(),
        );

        // Save to both local cache and Firebase
        await _writeToLocalCache(packageName, packageCategory);
        await _saveToFirestore(packageCategory);

        return gemsCategories;
      }
    }

    // Final fallback to heuristics
    final inferredCategory = _inferCategoryByName(packageName);

    final heuristicCategory = PackageCategory(
      name: packageName,
      categories: <String>[inferredCategory],
      primaryCategory: inferredCategory,
      source: 'heuristic',
      confidence: 0.5,
      fetchedAt: DateTime.now(),
    );

    // Save heuristic result to local cache only (not Firebase)
    await _writeToLocalCache(packageName, heuristicCategory);

    return <String>[inferredCategory];
  }

  /// Ensure cache directory exists
  Future<void> _ensureCacheDirectory() async {
    final dir = Directory(_userCacheDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
  }

  /// Load local cache from file
  Future<void> _loadLocalCache() async {
    final file = File(_cacheFilePath);

    if (!file.existsSync()) {
      _localCache = <String, PackageCategory>{};
      return;
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      _localCache = <String, PackageCategory>{};
      for (final entry in json.entries) {
        _localCache![entry.key] = PackageCategory.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }
    } catch (e) {
      // If cache is corrupted, start fresh
      _localCache = <String, PackageCategory>{};
    }
  }

  /// Write package data to local cache
  Future<void> _writeToLocalCache(
    String packageName,
    PackageCategory packageCategory,
  ) async {
    _localCache ??= <String, PackageCategory>{};
    _localCache![packageName] = packageCategory;

    final file = File(_cacheFilePath);

    final json = <String, dynamic>{};
    for (final entry in _localCache!.entries) {
      json[entry.key] = entry.value.toJson();
    }

    try {
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      // Silently fail - cache write is not critical
    }
  }

  /// Check if cache entry is still valid
  bool _isCacheValid(DateTime fetchedAt) {
    final now = DateTime.now();
    final difference = now.difference(fetchedAt);
    return difference.inDays < _cacheTtlDays;
  }

  /// Clear the user cache
  static Future<void> clearCache() async {
    try {
      final homeDir = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      final cacheDir =
          path.join(homeDir, CategorizationConfig.userCacheDirectory);
      final cacheFile = path.join(cacheDir, CategorizationConfig.cacheFileName);
      final file = File(cacheFile);

      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Get cache file path for external access
  static String get cacheFilePath {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final cacheDir =
        path.join(homeDir, CategorizationConfig.userCacheDirectory);
    return path.join(cacheDir, CategorizationConfig.cacheFileName);
  }

  /// Fetch package data from Firestore
  Future<PackageCategory?> _fetchFirestorePackage(String packageName) async {
    try {
      final url = 'https://firestore.googleapis.com/v1/projects/'
          '$firestoreProjectId/databases/(default)/documents/'
          'packages/$packageName';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 404) {
        return null; // Package not found in Firestore
      }

      if (response.statusCode != 200) {
        return null; // Other error
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = json['fields'] as Map<String, dynamic>;

      return PackageCategory(
        name: _extractStringValue(fields['name']),
        categories: _extractArrayValue(fields['categories']),
        primaryCategory: _extractStringValue(fields['primaryCategory']),
        source: 'firestore',
        confidence: _extractDoubleValue(fields['confidence']) ?? 0.9,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      return null; // Network or parsing error
    }
  }

  /// Save package data to Firestore
  /// Note: This requires proper Firestore security rules and authentication
  Future<void> _saveToFirestore(PackageCategory packageCategory) async {
    try {
      // For public write access, you need to configure Firestore security rules
      // to allow unauthenticated writes to the packages collection:
      // 
      // rules_version = '2';
      // service cloud.firestore {
      //   match /databases/{database}/documents {
      //     match /packages/{packageId} {
      //       allow read: if true;
      //       allow write: if true; // WARNING: This allows public writes
      //     }
      //   }
      // }
      
      final url = 'https://firestore.googleapis.com/v1/projects/'
          '$firestoreProjectId/databases/(default)/documents/'
          'packages?documentId=${packageCategory.name}';

      final firestoreDoc = <String, dynamic>{
        'fields': <String, dynamic>{
          'name': <String, String>{'stringValue': packageCategory.name},
          'categories': <String, dynamic>{
            'arrayValue': <String, dynamic>{
              'values': packageCategory.categories
                  .map((cat) => <String, String>{'stringValue': cat})
                  .toList(),
            }
          },
          'primaryCategory': <String, String>{
            'stringValue': packageCategory.primaryCategory
          },
          'source': <String, String>{'stringValue': packageCategory.source},
          'confidence': <String, double>{
            'doubleValue': packageCategory.confidence
          },
          'fetchedAt': <String, String>{
            'timestampValue': packageCategory.fetchedAt.toIso8601String()
          },
        }
      };

      // Try to create new document
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(firestoreDoc),
      );

      // If document already exists (409 conflict), try to update it
      if (response.statusCode == 409) {
        final updateUrl = 'https://firestore.googleapis.com/v1/projects/'
            '$firestoreProjectId/databases/(default)/documents/'
            'packages/${packageCategory.name}';
        
        await http.patch(
          Uri.parse(updateUrl),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: jsonEncode(firestoreDoc),
        );
      }
    } catch (e) {
      // Silently fail - Firebase write is not critical for CLI functionality
      // Common reasons for failure:
      // 1. Firestore security rules don't allow public writes
      // 2. Network connectivity issues
      // 3. Invalid project ID or configuration
    }
  }

  /// Refresh local cache from Firestore for all cached packages
  Future<void> _refreshCacheFromFirestore() async {
    if (_localCache == null || _localCache!.isEmpty) return;

    final List<String> packageNames = _localCache!.keys.toList();
    for (final String packageName in packageNames) {
      final PackageCategory? firestoreDoc =
          await _fetchFirestorePackage(packageName);
      if (firestoreDoc != null) {
        await _writeToLocalCache(packageName, firestoreDoc);
      }
    }
  }

  /// Fetch categories from FlutterGems page (realtime fallback)
  Future<List<String>?> _fetchFlutterGemsPage(String packageName) async {
    try {
      final url = 'https://fluttergems.dev/packages/$packageName/';

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'User-Agent':
              'SmartPub/1.0 (+https://github.com/VatsalJaganwala/smartpub)',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final category = _extractFlutterGemsCategory(response.body);
      if (category != null && category.isNotEmpty) {
        return <String>[category];
      } else {
        return null;
      }
    } catch (e) {
      return null; // Network or parsing error
    }
  }

  /// Extract category from FlutterGems HTML using proper HTML parsing
  String? _extractFlutterGemsCategory(String html) {
    try {
      final document = html_parser.parse(html);

      // Find table rows
      final rows = document.querySelectorAll('table tr');
      for (final row in rows) {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 3) {
          final label = cells[0].text.trim();
          if (label == 'Category') {
            final categoryAnchor = cells[2].querySelector('a');
            final category = categoryAnchor?.text.trim();
            if (category != null && category.isNotEmpty) {
              return category;
            }
          }
        }
      }

      // Fallback: try to extract from page title
      final titleElement = document.querySelector('title');
      if (titleElement != null) {
        final title = titleElement.text;
        final titleMatch =
            RegExp(r'in\s+([^|]+?)\s+category', caseSensitive: false)
                .firstMatch(title);
        if (titleMatch != null) {
          final category = titleMatch.group(1)?.trim();
          if (category != null && category.isNotEmpty) {
            return category;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Choose primary category from a list of categories
  String _choosePrimaryCategory(List<String> categories) {
    if (categories.isEmpty) return 'Miscellaneous';

    // Priority order for primary categories
    const List<String> priorityOrder = <String>[
      'State Management',
      'Networking',
      'HTTP Clients',
      'Database',
      'Storage',
      'UI Components',
      'Widgets',
      'Navigation',
      'Authentication',
      'Testing',
      'Development Tools',
      'Utilities',
    ];

    for (final String priority in priorityOrder) {
      if (categories.contains(priority)) {
        return priority;
      }
    }

    return categories.first;
  }

  /// Infer category by package name using heuristics
  String _inferCategoryByName(String packageName) {
    final String name = packageName.toLowerCase();

    // UI/Widgets (check first to catch specific packages)
    if (name == 'cached_network_image' ||
        name == 'flutter_svg' ||
        name.contains('widget') ||
        name.startsWith('ui_') ||
        name.endsWith('_ui') ||
        name.contains('icon') ||
        name.contains('animation') ||
        name.contains('carousel') ||
        name.contains('shimmer') ||
        name.contains('lottie')) {
      return 'UI Components';
    }

    // State Management
    if (name.contains('bloc') ||
        name.contains('provider') ||
        name.contains('riverpod') ||
        name.contains('redux') ||
        name.contains('mobx') ||
        name.contains('get')) {
      return 'State Management';
    }

    // Database/Storage
    if (name.contains('sqflite') ||
        name.contains('hive') ||
        name.contains('shared_preferences') ||
        name.contains('path_provider') ||
        name.contains('database') ||
        name.contains('storage')) {
      return 'Database';
    }

    // Testing
    if (name.contains('test') ||
        name.contains('mock') ||
        name.contains('fake')) {
      return 'Testing';
    }

    // Development Tools
    if (name.contains('build_runner') ||
        name.contains('json_serializable') ||
        name.contains('freezed') ||
        name.contains('lint') ||
        name.contains('analysis')) {
      return 'Development Tools';
    }

    // Networking (check after UI to avoid conflicts)
    if (name.contains('http') ||
        name.contains('dio') ||
        name.contains('network') ||
        name.contains('api') ||
        name.contains('rest') ||
        name.contains('graphql')) {
      return 'Networking';
    }

    return 'Utilities';
  }

  /// Extract string value from Firestore field
  String _extractStringValue(Map<String, dynamic>? field) {
    if (field == null) return '';
    return field['stringValue'] as String? ?? '';
  }

  /// Extract array value from Firestore field
  List<String> _extractArrayValue(Map<String, dynamic>? field) {
    if (field == null) return <String>[];
    final Map<String, dynamic>? arrayValue =
        field['arrayValue'] as Map<String, dynamic>?;
    if (arrayValue == null) return <String>[];
    final List? values = arrayValue['values'] as List<dynamic>?;
    if (values == null) return <String>[];

    return values
        .map((dynamic v) =>
            (v as Map<String, dynamic>)['stringValue'] as String? ?? '')
        .where((String s) => s.isNotEmpty)
        .toList();
  }

  /// Extract double value from Firestore field
  double? _extractDoubleValue(Map<String, dynamic>? field) {
    if (field == null) return null;
    final doubleValue = field['doubleValue'];
    if (doubleValue != null) return doubleValue as double;
    final intValue = field['integerValue'];
    if (intValue != null) return (intValue as int).toDouble();
    return null;
  }
}

/// Package category information
class PackageCategory {
  PackageCategory({
    required this.name,
    required this.categories,
    required this.primaryCategory,
    required this.source,
    required this.confidence,
    required this.fetchedAt,
  });

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
}
