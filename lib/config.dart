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
  static const String version = '1.0.0';

  /// Application description
  static const String description = 'Flutter Dependency Analyzer';

  /// Application tagline
  static const String tagline = 'The smart way to manage Flutter dependencies.';

  /// Full application title
  static const String fullTitle = '$appName - $description';

  /// Repository URL
  static const String repositoryUrl =
      'https://github.com/VatsalJaganwala/smartpub';
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
    if (widgetPackages.contains(packageName)) return widgets;
    if (apiPackages.contains(packageName)) return api;
    if (statePackages.contains(packageName)) return stateManagement;
    if (databasePackages.contains(packageName)) return database;
    if (utilityPackages.contains(packageName)) return utilities;
    if (testingPackages.contains(packageName)) return testing;
    if (devToolPackages.contains(packageName)) return devTools;
    return miscellaneous;
  }
}

/// CLI command configuration
class CommandConfig {
  /// Available command line flags
  static const String helpFlag = 'help';
  static const String versionFlag = 'version';
  static const String analyseFlag = 'analyse';
  static const String applyFlag = 'apply';
  static const String interactiveFlag = 'interactive';
  static const String noColorFlag = 'no-color';
  static const String organizeFlag = 'organize';
  static const String ciFlag = 'ci';
  static const String restoreFlag = 'restore';
  static const String updateFlag = 'update';

  /// Command abbreviations
  static const String helpAbbr = 'h';
  static const String versionAbbr = 'v';
  static const String analyseAbbr = 'a';
  static const String applyAbbr = 'p';
  static const String interactiveAbbr = 'i';
  static const String organizeAbbr = 'o';
  static const String restoreAbbr = 'r';
  static const String updateAbbr = 'u';
}

/// Exit codes for different scenarios
class ExitCodes {
  /// Success - no issues found
  static const int success = 0;

  /// General error
  static const int error = 1;

  /// Issues found (for CI mode)
  static const int issuesFound = 1;

  /// File not found
  static const int fileNotFound = 2;

  /// Invalid arguments
  static const int invalidArguments = 3;
}
