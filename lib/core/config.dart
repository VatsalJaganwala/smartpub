/// SmartPub Configuration
///
/// Contains all constants, configuration values, and settings used throughout
/// the SmartPub application.
library;

/// Application information and metadata
class AppConfig {
  /// Application name
  static const String appName = 'SmartPub';

  /// Current version of the application
  static const String version = '1.0.8';

  /// Application description
  static const String description = 'Flutter Dependency Analyzer';

  /// Application tagline
  static const String tagline = 'The smart way to manage Flutter dependencies.';

  /// Full application title
  static String get fullTitle => '$appName - $description';

  /// Repository URL
  static const String repositoryUrl =
      'https://github.com/VatsalJaganwala/smartpub';

  /// Initialize configuration (now a no-op as version is hardcoded to prevent reading wrong pubspec)
  static Future<void> initialize() async {}
}

/// File and directory constants
class FileConfig {
  /// Main pubspec file name
  static const String pubspecFile = 'pubspec.yaml';

  /// Backup file extension
  static const String backupExtension = '.bak';

  /// Full backup file name
  static const String backupFile = '$pubspecFile$backupExtension';

  /// Directories to scan for Dart files
  static const List<String> scanDirectories = <String>[
    'lib/',
    'test/',
    'bin/',
    'tool/',
  ];

  /// Dart file extension
  static const String dartExtension = '.dart';
}

/// CLI output and formatting constants
class OutputConfig {
  /// Emojis used in output
  static const String packageEmoji = '📦';
  static const String infoEmoji = 'ℹ️';
  static const String errorEmoji = '❌';
  static const String successEmoji = '✅';
  static const String warningEmoji = '⚠️';
  static const String searchEmoji = '🔍';
  static const String fixEmoji = '🧹';
  static const String constructionEmoji = '🚧';

  /// Status indicators
  static const String usedIndicator = '✅';
  static const String testOnlyIndicator = '🧩';
  static const String unusedIndicator = '⚠️';

  /// Output prefixes for non-colored mode
  static const String infoPrefix = 'INFO:';
  static const String errorPrefix = 'ERROR:';
  static const String warningPrefix = 'WARNING:';
}

/// Dependency analysis configuration
class AnalysisConfig {
  /// Import pattern regex for detecting package imports
  static const String importPattern =
      r'import\s+[\x27\x22]package:([^/\x27\x22]+)';

  /// Pubspec sections to analyze
  static const String dependenciesSection = 'dependencies';
  static const String devDependenciesSection = 'dev_dependencies';

  /// Flutter SDK dependency name
  static const String flutterSdk = 'flutter';

  /// Common test-only packages that should be in dev_dependencies
  static const List<String> testOnlyPackages = <String>[
    'test',
    'flutter_test',
    'mockito',
    'build_runner',
    'json_annotation',
    'json_serializable',
    'freezed',
    'build_verify',
  ];
}

/// Package categorization for organization feature
class PackageCategories {
  /// Widget-related packages
  static const String widgets = 'widgets';
  static const List<String> widgetPackages = <String>[
    'cached_network_image',
    'flutter_svg',
    'lottie',
    'shimmer',
    'carousel_slider',
    'flutter_staggered_grid_view',
    'photo_view',
    'flutter_spinkit',
  ];

  /// API and networking packages
  static const String api = 'api';
  static const List<String> apiPackages = <String>[
    'http',
    'dio',
    'retrofit',
    'chopper',
    'graphql_flutter',
    'web_socket_channel',
  ];

  /// State management packages
  static const String stateManagement = 'state management';
  static const List<String> statePackages = <String>[
    'flutter_bloc',
    'bloc',
    'provider',
    'riverpod',
    'flutter_riverpod',
    'get',
    'mobx',
    'flutter_mobx',
    'redux',
    'flutter_redux',
  ];

  /// Database and storage packages
  static const String database = 'database';
  static const List<String> databasePackages = <String>[
    'sqflite',
    'hive',
    'hive_flutter',
    'shared_preferences',
    'path_provider',
    'sembast',
    'drift',
    'floor',
  ];

  /// Testing packages
  static const String testing = 'testing';
  static const List<String> testingPackages = <String>[
    'test',
    'flutter_test',
    'mockito',
    'mocktail',
    'fake_async',
    'integration_test',
  ];

  /// Utility packages
  static const String utilities = 'utilities';
  static const List<String> utilityPackages = <String>[
    'intl',
    'uuid',
    'crypto',
    'convert',
    'collection',
    'meta',
    'equatable',
    'dartz',
    'rxdart',
  ];

  /// Development tools
  static const String devTools = 'dev tools';
  static const List<String> devToolPackages = <String>[
    'build_runner',
    'json_serializable',
    'json_annotation',
    'freezed',
    'freezed_annotation',
    'flutter_lints',
    'very_good_analysis',
  ];

  /// Miscellaneous category for unknown packages
  static const String miscellaneous = 'miscellaneous';

  /// All categories in order
  static const List<String> allCategories = <String>[
    widgets,
    api,
    stateManagement,
    database,
    utilities,
    testing,
    devTools,
    miscellaneous,
  ];

  /// Get category for a package name
  static String getCategoryForPackage(String packageName) {
    if (widgetPackages.contains(packageName)) {
      return widgets;
    }
    if (apiPackages.contains(packageName)) {
      return api;
    }
    if (statePackages.contains(packageName)) {
      return stateManagement;
    }
    if (databasePackages.contains(packageName)) {
      return database;
    }
    if (utilityPackages.contains(packageName)) {
      return utilities;
    }
    if (testingPackages.contains(packageName)) {
      return testing;
    }
    if (devToolPackages.contains(packageName)) {
      return devTools;
    }
    return miscellaneous;
  }
}

/// CLI command configuration
class CommandConfig {
  /// Available command line flags
  static const String helpFlag = 'help';
  static const String versionFlag = 'version';
  static const String analyseFlag = 'analyse';
  static const String cleanFlag = 'clean';
  static const String applyFlag = 'apply'; // Deprecated, use cleanFlag
  static const String interactiveFlag = 'interactive';
  static const String noColorFlag = 'no-color';
  static const String organizeFlag = 'organize';
  static const String ciFlag = 'ci';
  static const String restoreFlag = 'restore';
  static const String updateFlag = 'update';

  // New categorization flags
  static const String avoidGemsFlag = 'avoid-gems';
  static const String updateCacheFlag = 'update-cache';
  static const String refreshRemoteFlag = 'refresh-remote';
  static const String fetchGemsFallbackFlag = 'fetch-gems-fallback';
  static const String suggestFlag = 'suggest';
  static const String groupFlag = 'group';
  static const String noTelemetryFlag = 'no-telemetry';

  /// Command abbreviations
  static const String helpAbbr = 'h';
  static const String versionAbbr = 'v';
  static const String analyseAbbr = 'a';
  static const String cleanAbbr = 'c';
  static const String applyAbbr = 'p'; // Deprecated, use cleanAbbr
  static const String interactiveAbbr = 'i';
  static const String organizeAbbr = 'o';
  static const String restoreAbbr = 'r';
  static const String updateAbbr = 'u';

  // New categorization abbreviations
  static const String groupAbbr = 'g';
}

/// Categorization configuration and defaults
class CategorizationConfig {
  /// Cache configuration - uses user-level cache directory
  static const String userCacheDirectory = '.smartpub';
  static const String cacheFileName = 'category_cache.json';
  static const int cacheTtlDays = 30;
}

/// Exit codes for different scenarios
///
/// Follows Unix convention and matches `dart analyze`, `dependency_validator`:
///   0 = clean / success
///   1 = violations found (CI should fail the build)
///   2 = tool error (bad config, missing pubspec.yaml, no backup, parse failure)
///   3 = invalid CLI arguments
class ExitCodes {
  /// Success — no violations found, or violations were fixed successfully.
  static const int success = 0;

  /// Violations found — unused deps, wrong section, or duplicates detected.
  /// Also used when an apply operation itself fails (couldn't fix the issues).
  static const int violationsFound = 1;

  /// Tool error — missing pubspec.yaml, no backup exists, parse failure,
  /// or any unrecoverable internal error.
  static const int toolError = 2;

  /// Invalid CLI arguments (unknown flag, incompatible option combination).
  static const int invalidArguments = 3;
}
