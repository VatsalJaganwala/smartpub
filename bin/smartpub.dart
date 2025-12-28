#!/usr/bin/env dart

/// SmartPub CLI Entry Point
///
/// A Flutter dependency analyzer that helps developers clean and organize
/// their pubspec.yaml dependencies by detecting unused, misplaced, and
/// duplicate packages.
///
/// Usage:
///   dart run smartpub [options]
///   smartpub [options] (if globally activated)

import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:smartpub/core/analyzer.dart';
import 'package:smartpub/core/config.dart';
import 'package:smartpub/core/models/dependency_info.dart';
import 'package:smartpub/services/apply_service.dart';
import 'package:smartpub/services/backup_service.dart';
import 'package:smartpub/services/update_checker.dart';
import 'package:smartpub/categorization/gems_integration.dart';
import 'package:smartpub/categorization/grouping_service.dart';
import 'package:smartpub/ui/cli_output.dart';
import 'package:smartpub/ui/interactive_service.dart';
import 'package:smartpub/ui/interactive_grouping_service.dart';

/// Main entry point for the SmartPub CLI tool
void main(List<String> arguments) async {
  final cli = SmartPubCLI();
  await cli.run(arguments);
}

/// SmartPub CLI handler class
class SmartPubCLI {
  /// Run the CLI with provided arguments
  Future<void> run(List<String> arguments) async {
    final parser = _createArgParser();

    try {
      final results = parser.parse(arguments);
      await _handleCommand(results, parser);
    } catch (e) {
      _printError('Error: $e');
      _showHelp(parser);
      exit(ExitCodes.error);
    }
  }

  /// Create and configure the argument parser
  ArgParser _createArgParser() => ArgParser()
    ..addFlag(CommandConfig.helpFlag,
        abbr: CommandConfig.helpAbbr,
        help: 'Show help information',
        negatable: false)
    ..addFlag(CommandConfig.versionFlag,
        abbr: CommandConfig.versionAbbr,
        help: 'Show version information',
        negatable: false)
    ..addFlag(CommandConfig.analyseFlag,
        abbr: CommandConfig.analyseAbbr,
        help: 'Analyze dependencies without making changes',
        negatable: false)
    ..addFlag(CommandConfig.applyFlag,
        abbr: CommandConfig.applyAbbr,
        help: 'Apply fixes automatically',
        negatable: false)
    ..addFlag(CommandConfig.interactiveFlag,
        abbr: CommandConfig.interactiveAbbr,
        help: 'Interactive mode - prompt before changes',
        negatable: false)
    ..addFlag(CommandConfig.restoreFlag,
        abbr: CommandConfig.restoreAbbr,
        help: 'Restore pubspec.yaml from backup',
        negatable: false)
    ..addFlag(CommandConfig.updateFlag,
        abbr: CommandConfig.updateAbbr,
        help: 'Update SmartPub to the latest version',
        negatable: false)
    ..addFlag(CommandConfig.noColorFlag,
        help: 'Disable colored output', negatable: false)
    // New categorization flags
    ..addFlag(CommandConfig.avoidGemsFlag,
        help: 'Use FlutterGems for package categorization', defaultsTo: true)
    ..addFlag(CommandConfig.updateCacheFlag,
        help: 'Force update local cache from Firestore', negatable: false)
    ..addFlag(CommandConfig.refreshRemoteFlag,
        help: 'Refresh remote data sources', negatable: false)
    ..addFlag(CommandConfig.fetchGemsFallbackFlag,
        help: 'Allow fallback to realtime FlutterGems fetch', negatable: false)
    ..addFlag(CommandConfig.suggestFlag,
        help: 'Submit suggestions for missing packages', negatable: false)
    ..addFlag(CommandConfig.groupFlag,
        abbr: CommandConfig.groupAbbr,
        help: 'Group dependencies by categories',
        negatable: false)
    ..addFlag(CommandConfig.noTelemetryFlag,
        help: 'Disable telemetry collection', negatable: false);

  /// Handle the parsed command and execute appropriate action
  Future<void> _handleCommand(ArgResults results, ArgParser parser) async {
    // Configure colors
    if (results[CommandConfig.noColorFlag] as bool) {
      ansiColorDisabled = true;
    }

    // Handle help
    if (results[CommandConfig.helpFlag] as bool) {
      _showHelp(parser);
      return;
    }

    // Handle version
    if (results[CommandConfig.versionFlag] as bool) {
      _showVersion();
      return;
    }

    // Handle restore
    if (results[CommandConfig.restoreFlag] as bool) {
      await _handleRestore();
      return;
    }

    // Handle update
    if (results[CommandConfig.updateFlag] as bool) {
      await _handleUpdate();
      return;
    }

    // Verify pubspec.yaml exists
    if (!_pubspecExists()) {
      _printError('${FileConfig.pubspecFile} not found in current directory');
      exit(ExitCodes.fileNotFound);
    }

    // Execute main functionality
    await _executeAnalysis(results);
  }

  /// Execute the dependency analysis based on provided flags
  Future<void> _executeAnalysis(ArgResults results) async {
    _printWelcome();

    // Check for updates in background (only for global installations)
    await _checkForUpdatesInBackground();

    final isAnalyse = results[CommandConfig.analyseFlag] as bool;
    final shouldApply = results[CommandConfig.applyFlag] as bool;
    final isInteractive = results[CommandConfig.interactiveFlag] as bool;
    final noColor = results[CommandConfig.noColorFlag] as bool;

    // New categorization flags
    final useGems = !(results[CommandConfig.avoidGemsFlag] as bool);
    final updateCache = results[CommandConfig.updateCacheFlag] as bool;
    final refreshRemote = results[CommandConfig.refreshRemoteFlag] as bool;
    final fetchGemsFallback =
        results[CommandConfig.fetchGemsFallbackFlag] as bool;
    final suggest = results[CommandConfig.suggestFlag] as bool;
    final group = results[CommandConfig.groupFlag] as bool;
    final noTelemetry = results[CommandConfig.noTelemetryFlag] as bool;

    // Create output formatter
    final output = CLIOutput(noColor: noColor);

    try {
      // Initialize gems integration if grouping is enabled
      GemsIntegration? gemsIntegration;
      GroupingService? groupingService;

      if (group) {
        gemsIntegration = GemsIntegration(
          updateCache: updateCache || refreshRemote,
          fetchGemsFallback: true,
        );

        output.printInfo('🔄 Initializing package categorization...');
        await gemsIntegration.initialize();

        // Load group overrides
        final groupOverrides = await loadGroupOverrides();
        groupingService = GroupingService(
          gemsIntegration: gemsIntegration,
          groupOverrides: groupOverrides,
        );
      }

      // Create analyzer and run analysis
      final analyzer = DependencyAnalyzer();
      output.printInfo('${OutputConfig.searchEmoji} Scanning dependencies...');

      final analysisResult = await analyzer.analyze();

      // Handle grouping if requested
      if (group && groupingService != null) {
        await _handleGrouping(
          analysisResult,
          groupingService,
          output,
          shouldApply,
          isInteractive,
        );
        return;
      }

      if (isInteractive) {
        // Interactive mode - analyze and prompt for changes
        output.printDryRunResults(analysisResult);

        if (analysisResult.hasIssues) {
          print('');
          output.printInfo(
              '🤝 Interactive mode: Review each change before applying');

          final applyResult = await ApplyService.applyInteractive(
            analysisResult,
            InteractiveService.promptYesNo,
          );

          if (applyResult.success) {
            if (applyResult.hasChanges) {
              output.printBackupCreated();
              applyResult.changes.forEach(output.printSuccess);
              output.printSuccess(
                  '${OutputConfig.successEmoji} pubspec.yaml updated successfully');
            } else {
              output.printInfo('No changes were made');
            }
          } else {
            output.printError(applyResult.error ?? 'Failed to apply changes');
          }
        } else {
          output.printInfo(
              '✨ No issues found - your dependencies are perfectly organized!');
        }
      } else if (shouldApply) {
        // Auto-apply mode
        output.printDryRunResults(analysisResult);

        if (analysisResult.hasIssues) {
          print('');
          output
              .printInfo('🚀 Auto-apply mode: Fixing all issues automatically');

          final applyResult = await ApplyService.applyFixes(analysisResult);

          if (applyResult.success) {
            if (applyResult.hasChanges) {
              output.printBackupCreated();
              applyResult.changes.forEach(output.printSuccess);
              output.printSuccess(
                  '${OutputConfig.successEmoji} pubspec.yaml updated successfully');
            } else {
              output.printInfo('No changes were made');
            }
          } else {
            output.printError(applyResult.error ?? 'Failed to apply changes');
          }
        } else {
          output.printInfo(
              '✨ No issues found - your dependencies are perfectly organized!');
        }
      } else if (isAnalyse) {
        // Analyse mode - show analysis without making changes
        output.printDryRunResults(analysisResult);
      } else {
        // Default behavior - show analysis (same as --analyse)
        output.printDryRunResults(analysisResult);
      }

      // Exit with appropriate code
      if (analysisResult.hasIssues) {
        exit(ExitCodes.issuesFound);
      } else {
        exit(ExitCodes.success);
      }
    } catch (e) {
      output.printError('Analysis failed: $e');
      exit(ExitCodes.error);
    }
  }

  /// Check if pubspec.yaml exists in current directory
  bool _pubspecExists() => File(FileConfig.pubspecFile).existsSync();

  /// Handle restore command
  Future<void> _handleRestore() async {
    _printWelcome();

    if (!BackupService.backupExists()) {
      _printError('No backup file found (${FileConfig.backupFile})');
      exit(ExitCodes.fileNotFound);
    }

    // Get backup info
    final backupInfo = await BackupService.getBackupInfo();
    if (backupInfo != null) {
      if (!ansiColorDisabled) {
        final cyan = AnsiPen()..cyan();
        print(cyan('📋 Backup Information:'));
        print(cyan('   File: ${backupInfo.path}'));
        print(cyan('   Size: ${backupInfo.formattedSize}'));
        print(cyan('   Modified: ${backupInfo.formattedLastModified}'));
      } else {
        print('Backup Information:');
        print('   File: ${backupInfo.path}');
        print('   Size: ${backupInfo.formattedSize}');
        print('   Modified: ${backupInfo.formattedLastModified}');
      }
      print('');
    }

    // Restore from backup
    final success = await BackupService.restoreFromBackup();

    if (success) {
      if (!ansiColorDisabled) {
        final green = AnsiPen()..green();
        print(green(
            '${OutputConfig.successEmoji} Successfully restored ${FileConfig.pubspecFile} from backup'));
      } else {
        print(
            'SUCCESS: Successfully restored ${FileConfig.pubspecFile} from backup');
      }
      exit(ExitCodes.success);
    } else {
      _printError('Failed to restore from backup');
      exit(ExitCodes.error);
    }
  }

  /// Handle update command
  Future<void> _handleUpdate() async {
    _printWelcome();

    if (!ansiColorDisabled) {
      final blue = AnsiPen()..blue();
      print(blue('🔄 Checking for updates...'));
    } else {
      print('Checking for updates...');
    }

    // Check if globally installed
    final isGlobal = await UpdateChecker.isGloballyInstalled();
    if (!isGlobal) {
      _printError(
          'SmartPub is not globally installed. Please install it first with:');
      print('dart pub global activate smartpub');
      exit(ExitCodes.error);
    }

    // Check for updates
    final updateInfo = await UpdateChecker.checkForUpdates(useCache: false);

    if (!updateInfo.isSuccessful) {
      _printError('Failed to check for updates: ${updateInfo.error}');
      exit(ExitCodes.error);
    }

    if (!updateInfo.hasUpdate) {
      if (!ansiColorDisabled) {
        final green = AnsiPen()..green();
        print(green(
            '${OutputConfig.successEmoji} SmartPub is already up to date (${updateInfo.currentVersion})'));
      } else {
        print(
            'SUCCESS: SmartPub is already up to date (${updateInfo.currentVersion})');
      }
      exit(ExitCodes.success);
    }

    // Update available
    if (!ansiColorDisabled) {
      final yellow = AnsiPen()..yellow();
      print(yellow(
          '${OutputConfig.warningEmoji} Update available: ${updateInfo.latestVersion} (current: ${updateInfo.currentVersion})'));
      print(yellow('🔄 Updating SmartPub...'));
    } else {
      print(
          'Update available: ${updateInfo.latestVersion} (current: ${updateInfo.currentVersion})');
      print('Updating SmartPub...');
    }

    // Run update
    final success = await UpdateChecker.runUpdate();

    if (success) {
      if (!ansiColorDisabled) {
        final green = AnsiPen()..green();
        print(green(
            '${OutputConfig.successEmoji} Successfully updated SmartPub to ${updateInfo.latestVersion}'));
      } else {
        print(
            'SUCCESS: Successfully updated SmartPub to ${updateInfo.latestVersion}');
      }

      // Clear cache after successful update
      await UpdateChecker.clearCache();
      exit(ExitCodes.success);
    } else {
      _printError('Failed to update SmartPub. Please try manually:');
      print('dart pub global activate smartpub');
      exit(ExitCodes.error);
    }
  }

  /// Display help information
  void _showHelp(ArgParser parser) {
    print('''
${OutputConfig.packageEmoji} ${AppConfig.fullTitle}
The smart way to manage Flutter dependencies.

Analyze, clean, and organize dependencies in your ${FileConfig.pubspecFile} file.

USAGE:
  smartpub [options]

OPTIONS:
${parser.usage}

EXAMPLES:
  smartpub                        # Run basic analysis
  smartpub --${CommandConfig.analyseFlag}             # Analyze dependencies without making changes
  smartpub --${CommandConfig.interactiveFlag}         # Review and apply changes interactively
  smartpub --${CommandConfig.applyFlag}               # Apply fixes automatically
  smartpub --${CommandConfig.restoreFlag}             # Restore pubspec.yaml from backup
  smartpub --${CommandConfig.updateFlag}              # Update SmartPub to the latest version
  smartpub --${CommandConfig.noColorFlag}             # Disable colored output
  
  # Package Categorization Examples:
  smartpub --${CommandConfig.groupFlag}               # Preview dependency grouping by categories
  smartpub --${CommandConfig.groupFlag} --${CommandConfig.applyFlag}        # Apply dependency grouping
  smartpub --${CommandConfig.groupFlag} --${CommandConfig.interactiveFlag}  # Interactive grouping mode
  smartpub --${CommandConfig.updateCacheFlag}         # Update local category cache
  smartpub --${CommandConfig.fetchGemsFallbackFlag}   # Enable FlutterGems fallback for missing packages

For more information, visit: ${AppConfig.repositoryUrl}
''');
  }

  /// Display version information
  void _showVersion() {
    print('${AppConfig.appName} v${AppConfig.version}');
    print(AppConfig.description);
  }

  /// Check for updates in background and display notification if available
  Future<void> _checkForUpdatesInBackground() async {
    // Run update check in background without blocking main execution
    await UpdateChecker.checkForUpdates().then((UpdateInfo updateInfo) {
      if (updateInfo.hasUpdate && updateInfo.isSuccessful) {
        // Display update notification
        if (!ansiColorDisabled) {
          final yellow = AnsiPen()..yellow();
          print(yellow(updateInfo.updateMessage));
        } else {
          print(
              'Update available: ${updateInfo.latestVersion} (current: ${updateInfo.currentVersion})');
          print('Run smartpub --update to update.');
        }
        print('');
      }
    }).catchError((error) {
      // Silently ignore update check errors to not disrupt main functionality
    });
  }

  /// Print welcome message
  void _printWelcome() {
    if (!ansiColorDisabled) {
      final title = AnsiPen()..blue(bold: true);
      print(title('${OutputConfig.packageEmoji} ${AppConfig.fullTitle}'));
    } else {
      print(AppConfig.fullTitle);
    }
    print('');
  }

  /// Handle grouping functionality
  Future<void> _handleGrouping(
    AnalysisResult analysisResult,
    GroupingService groupingService,
    CLIOutput output,
    bool shouldApply,
    bool isInteractive,
  ) async {
    output.printInfo('📊 Grouping dependencies by categories...');

    // Separate dependencies by section
    final regularDeps = analysisResult.dependencies
        .where((dep) => dep.section == DependencySection.dependencies)
        .toList();
    final devDeps = analysisResult.dependencies
        .where((dep) => dep.section == DependencySection.devDependencies)
        .toList();

    // Group dependencies
    final groupedDeps = await groupingService.groupDependencies(regularDeps);
    final groupedDevDeps = await groupingService.groupDependencies(devDeps);

    // Generate preview
    final preview =
        groupingService.generatePreview(groupedDeps, groupedDevDeps);

    output.printInfo('📋 Grouped Dependencies Preview:');
    print('');
    print(preview);

    // Show summary
    final totalPackages =
        groupedDeps.totalPackages + groupedDevDeps.totalPackages;
    final totalCategories =
        groupedDeps.categoryCount + groupedDevDeps.categoryCount;

    output.printInfo(
        '📈 Summary: $totalPackages packages in $totalCategories categories');

    if (shouldApply) {
      // Apply grouping
      output.printInfo('🚀 Applying grouping to pubspec.yaml...');

      // Create backup
      final backupSuccess = await BackupService.createBackup();
      if (!backupSuccess) {
        output.printError('Failed to create backup');
        exit(ExitCodes.error);
      }

      try {
        final groupedContent = await groupingService.generateGroupedPubspec(
          groupedDeps,
          groupedDevDeps,
        );

        final pubspecFile = File(FileConfig.pubspecFile);
        await pubspecFile.writeAsString(groupedContent);

        output.printBackupCreated();
        output.printSuccess(
            '${OutputConfig.successEmoji} Dependencies grouped successfully');
      } catch (e) {
        output.printError('Failed to apply grouping: $e');
        exit(ExitCodes.error);
      }
    } else if (isInteractive) {
      // Interactive mode - allow category overrides
      await _handleInteractiveGrouping(groupingService, output);
    }
  }

  /// Handle interactive grouping with category overrides
  Future<void> _handleInteractiveGrouping(
    GroupingService groupingService,
    CLIOutput output,
  ) async {
    output.printInfo('🤝 Interactive grouping mode');

    final shouldOverride = InteractiveGroupingService.promptYesNo(
      'Would you like to override any package categories?',
      defaultValue: false,
    );

    if (shouldOverride) {
      final interactiveService = InteractiveGroupingService(
        gemsIntegration: groupingService.gemsIntegration,
      );

      interactiveService.showAvailableCategories();

      // Get all dependencies for override prompting
      final analyzer = DependencyAnalyzer();
      final analysisResult = await analyzer.analyze();

      await interactiveService.promptForOverrides(analysisResult.dependencies);

      output.printInfo(
          '✅ Overrides saved. Run with --group --apply to apply grouping.');
    } else {
      output.printInfo('Use --apply to apply the grouping shown above');
      output.printInfo(
          'To override categories later, edit group-overrides.yaml and run again');
    }
  }

  /// Print error message
  void _printError(String message) {
    if (!ansiColorDisabled) {
      final red = AnsiPen()..red();
      stderr.writeln(red('${OutputConfig.errorEmoji} $message'));
    } else {
      stderr.writeln('${OutputConfig.errorPrefix} $message');
    }
  }
}
