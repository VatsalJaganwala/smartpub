/// String Constants
///
/// Contains all user-facing strings, messages, and text used throughout
/// the SmartPub application for consistency and easy localization.
library;

import 'config.dart';

/// Application strings and messages
class Strings {
  // App Info
  static const String appTitle = '📦 SmartPub - Flutter Dependency Analyzer';
  static String appVersion = 'SmartPub v${AppConfig.version}';

  // Analysis Messages
  static const String scanningDependencies = '🔍 Scanning dependencies...';
  static const String analyzingDependencies = '🔬 Analyzing dependencies...';
  static const String noIssuesFound = '✨ No issues found!';
  static const String issuesFound = '⚠️  Issues found';

  // Grouping Messages
  static const String initializingCategorization =
      '🔧 Initializing categorization...';
  static const String groupingByCategories = '📊 Grouping by categories...';
  static const String applyingGrouping = '🚀 Applying grouping...';
  static const String groupingSuccess = '✅ Dependencies grouped successfully';
  static const String groupingMode =
      '🗂️  Grouping dependencies by category (no removals)';

  // Interactive Mode
  static const String interactiveMode = '🤝 Interactive mode';
  static const String interactiveModeReview =
      '🤝 Interactive mode: Review each change';
  static const String interactiveCategoryOverride =
      '🤝 Interactive Category Override Mode';
  static const String overridePrompt =
      'Press Enter to keep suggested category, or type a new category name.';
  static const String overrideQuestion = 'Override any package categories?';
  static const String overridesSaved =
      '✅ Overrides saved to group-overrides.yaml';
  static const String savingOverrides =
      '📝 Saving overrides to group-overrides.yaml...';

  // Preview and Results
  static const String preview = '📋 Preview:';
  static const String availableCategories = '📋 Available Categories:';

  // Instructions
  static const String useCleanToApply = 'Use --clean to apply grouping';
  static const String useCleanToApplyShown =
      'Use --clean to apply the grouping shown above';
  static const String runWithGroupClean = 'Run with --group --clean to apply';
  static const String useRestoreToRevert =
      'Use --restore to revert to the original pubspec.yaml';

  // Hints
  static const String hintInteractiveWithClean =
      '💡 Hint: --interactive is used with --clean for reviewing changes';

  // Warnings and Disclaimers
  static const String betaWarning = '⚠️  Beta: Use --restore if issues occur';
  static const String flutterGemsCredit =
      '📦 Categories powered by FlutterGems';

  // Backup Messages
  static const String backupCreated = '💾 Backup created: pubspec.yaml.bak';
  static const String backupFailed = 'Failed to create backup';
  static const String restoringBackup = '🔄 Restoring from backup...';
  static const String restoreSuccess = '✅ Restored successfully';
  static const String restoreFailed = 'Failed to restore backup';
  static const String noBackupFound = 'No backup file found';

  // Apply Messages
  static const String autoApplyingFixes = '🚀 Auto-applying fixes...';
  static const String applyingChanges = '🔧 Applying changes...';
  static const String changesApplied = '✅ Changes applied successfully';
  static const String noChangesToApply = 'No changes to apply';

  // Error Messages
  static const String pubspecNotFound = 'pubspec.yaml not found';
  static const String failedToApplyGrouping = 'Failed to apply grouping';
  static const String failedToReadPubspec = 'Failed to read pubspec.yaml';
  static const String failedToWritePubspec = 'Failed to write pubspec.yaml';
  static const String operationFailed = 'Operation failed';

  // Dependency Status
  static const String unusedDependencies = '⚠️  Unused dependencies';
  static const String misplacedDependencies = '🔄 Misplaced dependencies';
  static const String duplicateDependencies = '🔁 Duplicate dependencies';
  static const String testOnlyInMain = '🧩 Test-only packages in dependencies';

  // Category Override Feedback
  static String overrideApplied(String packageName, String category) =>
      '  → Override: $packageName → $category';

  static String keepingCategory(String category) => '  ✓ Keeping: $category';

  static String suggestedCategory(String category) => 'suggested: $category';

  // Progress Messages
  static String packagesInCategories(int packages, int categories) =>
      '📈 $packages packages in $categories categories';

  static String progressCounter(int current, int total) => '[$current/$total]';

  // Telemetry Messages
  static const String telemetryEnabled = '📊 Anonymous usage data collected';
  static const String telemetryDisabled = '🔒 Telemetry disabled';
  static const String telemetryOptOut =
      'Use --no-telemetry to disable telemetry';

  // Help and Version
  static const String showingHelp = 'Showing help information';
  static const String showingVersion = 'Showing version information';

  // CI Mode
  static const String ciMode = '🤖 CI Mode: Failing on issues';
  static const String ciModeIssuesFound = 'Issues found in CI mode';

  // Update Messages
  static const String checkingForUpdates = '🔄 Checking for updates...';
  static const String updateAvailable = '🆕 Update available';
  static const String upToDate = '✅ You are up to date';

  // Emojis (for consistency)
  static const String emojiPackage = '📦';
  static const String emojiInfo = 'ℹ️';
  static const String emojiError = '❌';
  static const String emojiSuccess = '✅';
  static const String emojiWarning = '⚠️';
  static const String emojiSearch = '🔍';
  static const String emojiFix = '🧹';
  static const String emojiConstruction = '🚧';
  static const String emojiRocket = '🚀';
  static const String emojiFolder = '🗂️';
  static const String emojiChart = '📊';
  static const String emojiClipboard = '📋';
  static const String emojiHandshake = '🤝';
  static const String emojiGear = '🔧';
  static const String emojiCheckmark = '✓';
  static const String emojiArrow = '→';
  static const String emojiBullet = '•';

  // Category Names (for reference)
  static const List<String> categoryNames = [
    'State Management',
    'Networking',
    'HTTP Clients',
    'Database',
    'Storage',
    'UI Components',
    'Widgets',
    'Navigation',
    'Authentication',
    'Firebase',
    'Animation',
    'Charts',
    'Forms',
    'Maps',
    'Camera',
    'Image Processing',
    'Audio',
    'Video',
    'Testing',
    'Development Tools',
    'Utilities',
    'Miscellaneous',
  ];
}
