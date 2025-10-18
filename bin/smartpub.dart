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
import 'package:args/args.dart';
import 'package:ansicolor/ansicolor.dart';
import 'package:smartpub/config.dart';
import 'package:smartpub/analyzer.dart';
import 'package:smartpub/cli_output.dart';
import 'package:smartpub/backup_service.dart';
import 'package:smartpub/apply_service.dart';
import 'package:smartpub/interactive_service.dart';

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
  ArgParser _createArgParser() {
    return ArgParser()
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
      ..addFlag(CommandConfig.noColorFlag,
          help: 'Disable colored output', negatable: false);
  }

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

    final isAnalyse = results[CommandConfig.analyseFlag] as bool;
    final shouldApply = results[CommandConfig.applyFlag] as bool;
    final isInteractive = results[CommandConfig.interactiveFlag] as bool;
    final noColor = results[CommandConfig.noColorFlag] as bool;

    // Create output formatter
    final output = CLIOutput(noColor: noColor);

    try {
      // Create analyzer and run analysis
      final analyzer = DependencyAnalyzer();
      output.printInfo('${OutputConfig.searchEmoji} Scanning dependencies...');

      final analysisResult = await analyzer.analyze();

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
              for (final change in applyResult.changes) {
                output.printSuccess(change);
              }
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
              for (final change in applyResult.changes) {
                output.printSuccess(change);
              }
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
  bool _pubspecExists() {
    return File(FileConfig.pubspecFile).existsSync();
  }

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

  /// Display help information
  void _showHelp(ArgParser parser) {
    print('''
${OutputConfig.packageEmoji} ${AppConfig.fullTitle}

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
  smartpub --${CommandConfig.noColorFlag}             # Disable colored output

For more information, visit: ${AppConfig.repositoryUrl}
''');
  }

  /// Display version information
  void _showVersion() {
    print('${AppConfig.appName} v${AppConfig.version}');
    print(AppConfig.description);
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
