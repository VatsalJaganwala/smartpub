#!/usr/bin/env dart

/// SmartPub CLI - Flutter Dependency Analyzer
///
/// Simple command-line interface for dependency management
library;

import 'dart:io';

import 'package:ansicolor/ansicolor.dart';
import 'package:args/args.dart';
import 'package:smartpub/categorization/gems_integration.dart';
import 'package:smartpub/categorization/grouping_service.dart';
import 'package:smartpub/core/analyzer.dart';
import 'package:smartpub/core/config.dart';
import 'package:smartpub/core/models/dependency_info.dart';
import 'package:smartpub/core/strings.dart';
import 'package:smartpub/services/apply_service.dart';
import 'package:smartpub/services/backup_service.dart';
import 'package:smartpub/services/update_checker.dart';
import 'package:smartpub/ui/cli_output.dart';
import 'package:smartpub/ui/interactive_grouping_service.dart';
import 'package:smartpub/ui/interactive_service.dart';

void main(List<String> arguments) async {
  await AppConfig.initialize();

  final SmartPubCLI cli = SmartPubCLI();
  await cli.run(arguments);
}

/// Main CLI handler
class SmartPubCLI {
  SmartPubCLI() {
    _output = CLIOutput();
  }

  late final CLIOutput _output;

  /// Run the CLI with given arguments
  Future<void> run(List<String> arguments) async {
    final ArgParser parser = _buildParser();

    try {
      final ArgResults args = parser.parse(arguments);

      // Handle system commands first (these run alone)
      if (args['help'] == true) {
        _printHelp();
        return;
      }

      if (args['version'] == true) {
        _printVersion();
        return;
      }

      // Disable colors if requested
      if (args['no-color'] == true) {
        _output = CLIOutput(noColor: true);
      }

      // Get command (default to 'check')
      final String command = args.rest.isEmpty ? 'check' : args.rest.first;

      // Handle system commands (these run alone)
      if (command == 'restore') {
        await _restoreBackup();
        return;
      }

      if (command == 'update') {
        await _updateSmartPub();
        return;
      }

      // Get options
      final bool apply = args['apply'] == true;
      final bool interactive = args['interactive'] == true;
      final bool failOnViolations = args['no-fail-on-violations'] != true;

      // Validate command + option combinations
      _validateUsage(command, apply, interactive);

      // Route to appropriate handler
      await _handleCommand(command, apply, interactive,
          failOnViolations: failOnViolations);
    } on FormatException catch (e) {
      _output.printError('Invalid arguments: ${e.message}');
      print('');
      _printHelp();
      exit(ExitCodes.invalidArguments);
    } on Exception catch (e) {
      _output.printError('Error: $e');
      exit(ExitCodes.toolError);
    }
  }

  /// Build argument parser
  ArgParser _buildParser() {
    return ArgParser()
      ..addFlag('help',
          abbr: 'h', help: 'Show help information', negatable: false)
      ..addFlag('version',
          abbr: 'v', help: 'Show version information', negatable: false)
      ..addFlag('apply', help: 'Apply changes automatically', negatable: false)
      ..addFlag('interactive',
          help: 'Review and confirm changes interactively', negatable: false)
      ..addFlag('no-color', help: 'Disable colored output', negatable: false)
      ..addFlag(
        'no-fail-on-violations',
        help:
            'Exit 0 even when violations are found (warn-only mode for CI migration).\n'
            'By default smartpub exits 1 when violations are detected.',
        negatable: false,
      );
  }

  /// Validate command and option combinations
  void _validateUsage(String command, bool apply, bool interactive) {
    // --apply and --interactive cannot be used together
    if (apply && interactive) {
      _output.printError('❌ Cannot use --apply and --interactive together');
      print(
          '   Choose one: auto mode (--apply) or interactive mode (--interactive)');
      exit(ExitCodes.invalidArguments);
    }

    // check does not support --apply or --interactive
    if (command == 'check') {
      if (apply) {
        _output.printError('❌ --apply cannot be used with check');
        print('   Use: smartpub clean --apply');
        exit(ExitCodes.invalidArguments);
      }
      if (interactive) {
        _output.printError('❌ --interactive cannot be used with check');
        print('   Use: smartpub clean --interactive');
        exit(ExitCodes.invalidArguments);
      }
    }

    // Validate command exists
    if (!['check', 'clean', 'group', 'restore', 'update'].contains(command)) {
      _output.printError('❌ Unknown command: $command');
      print('   Valid commands: check, clean, group, restore, update');
      exit(ExitCodes.invalidArguments);
    }
  }

  /// Handle the command
  Future<void> _handleCommand(
    String command,
    bool apply,
    bool interactive, {
    bool failOnViolations = true,
  }) async {
    print(Strings.appTitle);
    print('');

    // Check for updates (silently, non-blocking)
    await _checkForUpdatesQuietly();

    // Print intent message
    _printIntent(command, apply, interactive);

    // Run analysis
    _output.printInfo(Strings.scanningDependencies);
    final DependencyAnalyzer analyzer = DependencyAnalyzer();
    final AnalysisResult result = await analyzer.analyze();

    // Route to command handler
    switch (command) {
      case 'check':
        await _handleCheck(result, failOnViolations: failOnViolations);
        break;
      case 'clean':
        await _handleClean(result, interactive);
        break;
      case 'group':
        await _handleGroup(result, apply, interactive);
        break;
    }
  }

  /// Check for updates quietly and notify user if available
  Future<void> _checkForUpdatesQuietly() async {
    try {
      // Only check if globally installed
      final bool isGlobal = await UpdateChecker.isGloballyInstalled();
      if (!isGlobal) return;

      // Check for updates with timeout (use cache for speed)
      final UpdateInfo updateInfo = await UpdateChecker.checkForUpdates()
          .timeout(const Duration(seconds: 2));

      // Show update notification in a green box
      if (updateInfo.hasUpdate) {
        _printUpdateNotification(updateInfo.latestVersion);
      }
    } catch (e) {
      // Silently fail - don't interrupt user's workflow
      // This includes timeout, network errors, or no update available
    }
  }

  /// Print update notification in a green box
  void _printUpdateNotification(String version) {
    final String message = '🆕 Update available: $version';
    final String instruction = 'Run: smartpub update';
    final int maxLength = message.length > instruction.length
        ? message.length
        : instruction.length;
    final String border = '═' * (maxLength + 2);

    if (!_output.noColor) {
      final AnsiPen green = AnsiPen()..green(bold: true);
      print(green('╔$border╗'));
      print(green('║ ${message.padRight(maxLength)} ║'));
      print(green('║ ${instruction.padRight(maxLength)} ║'));
      print(green('╚$border╝'));
    } else {
      print('┌${'─' * (maxLength + 2)}┐');
      print('│ ${message.padRight(maxLength)} │');
      print('│ ${instruction.padRight(maxLength)} │');
      print('└${'─' * (maxLength + 2)}┘');
    }
    print('');
  }

  /// Print what the command will do
  void _printIntent(String command, bool apply, bool interactive) {
    if (command == 'check') {
      _output.printInfo(
          '🔍 Previewing unused dependencies (no changes will be made)');
    } else if (command == 'clean') {
      if (interactive) {
        _output.printInfo('🤝 Interactive cleanup mode');
      } else {
        _output.printInfo('🧹 Removing unused dependencies');
      }
    } else if (command == 'group') {
      if (apply) {
        _output.printInfo('🗂️  Applying dependency categorization');
      } else if (interactive) {
        _output.printInfo('🤝 Interactive categorization mode');
      } else {
        _output.printInfo('🗂️  Previewing dependency categorization');
      }
    }
    print('');
  }

  /// Handle 'check' command - preview only.
  ///
  /// Exits [ExitCodes.success] (0) when no violations are found.
  /// Exits [ExitCodes.violationsFound] (1) when violations exist, UNLESS
  /// [failOnViolations] is false (--no-fail-on-violations flag), in which
  /// case it exits 0 so CI pipelines can run in warn-only mode.
  Future<void> _handleCheck(
    AnalysisResult result, {
    bool failOnViolations = true,
  }) async {
    _output.printDryRunResults(result);

    if (!result.hasIssues) {
      _output.printInfo(Strings.noIssuesFound);
      exit(ExitCodes.success); // ✅ clean
    }

    // Violations found
    print('');
    _output.printInfo('💡 To remove unused dependencies: smartpub clean');
    _output
        .printInfo('💡 To review changes first: smartpub clean --interactive');

    if (failOnViolations) {
      exit(ExitCodes.violationsFound); // ❌ CI fails the build
    } else {
      // --no-fail-on-violations: violations shown as warnings, build passes
      _output.printInfo(
          '⚠️  Violations found but --no-fail-on-violations is set. Exiting 0.');
      exit(ExitCodes.success);
    }
  }

  /// Handle 'clean' command - remove unused dependencies.
  ///
  /// Exits [ExitCodes.success] (0) when no violations exist OR after
  /// successfully removing them. Exits [ExitCodes.violationsFound] (1) if the
  /// apply step itself fails (violations remain).
  Future<void> _handleClean(AnalysisResult result, bool interactive) async {
    _output.printDryRunResults(result);

    if (!result.hasIssues) {
      _output.printInfo(Strings.noIssuesFound);
      exit(ExitCodes.success); // ✅ already clean
    }

    print('');

    if (interactive) {
      // Interactive mode
      final ApplyResult applyResult = await ApplyService.applyInteractive(
        result,
        InteractiveService.promptYesNo,
      );
      _handleApplyResult(applyResult);
    } else {
      // Auto mode
      _output.printInfo(Strings.autoApplyingFixes);
      final ApplyResult applyResult = await ApplyService.applyFixes(result);
      _handleApplyResult(applyResult);
    }
  }

  /// Handle 'group' command - categorize dependencies
  Future<void> _handleGroup(
    AnalysisResult result,
    bool apply,
    bool interactive,
  ) async {
    // Initialize categorization
    _output.printInfo(Strings.initializingCategorization);
    final GemsIntegration gemsIntegration = GemsIntegration();
    await gemsIntegration.initialize();

    // Load overrides
    final Map<String, String>? overrides = await loadGroupOverrides();
    final GroupingService groupingService = GroupingService(
      gemsIntegration: gemsIntegration,
      groupOverrides: overrides,
    );

    // Separate dependencies by section
    final List<DependencyInfo> deps = result.dependencies
        .where(
            (DependencyInfo d) => d.section == DependencySection.dependencies)
        .toList();
    final List<DependencyInfo> devDeps = result.dependencies
        .where((DependencyInfo d) =>
            d.section == DependencySection.devDependencies)
        .toList();

    // Group dependencies
    _output.printInfo(Strings.groupingByCategories);
    final GroupedDependencies groupedDeps =
        await groupingService.groupDependencies(deps);
    final GroupedDependencies groupedDevDeps =
        await groupingService.groupDependencies(devDeps);

    // Show preview
    final String preview =
        groupingService.generatePreview(groupedDeps, groupedDevDeps);
    _output.printInfo(Strings.preview);
    print('');
    print(preview);

    final int totalPkgs =
        groupedDeps.totalPackages + groupedDevDeps.totalPackages;
    final int totalCats =
        groupedDeps.categoryCount + groupedDevDeps.categoryCount;
    _output.printInfo(Strings.packagesInCategories(totalPkgs, totalCats));
    print('');

    // Handle mode
    if (apply) {
      // Auto apply
      await _applyGrouping(groupingService, groupedDeps, groupedDevDeps);
    } else if (interactive) {
      // Interactive override
      await _interactiveGrouping(groupingService, result.dependencies);
    } else {
      // Preview only
      _output.printInfo('💡 To apply: smartpub group --apply');
      _output.printInfo(
          '💡 To customize categories: smartpub group --interactive');
      print('');
      _output.printInfo(Strings.flutterGemsCredit);
    }
  }

  /// Apply grouping to pubspec.yaml.
  ///
  /// Exits [ExitCodes.success] (0) on success.
  /// Exits [ExitCodes.toolError] (2) if the backup or write fails (tool error,
  /// not a violation — the user didn't cause this).
  Future<void> _applyGrouping(
    GroupingService service,
    GroupedDependencies deps,
    GroupedDependencies devDeps,
  ) async {
    _output.printInfo(Strings.applyingGrouping);

    // Create backup before modifying pubspec.yaml
    final bool backupOk = await BackupService.createBackup();
    if (!backupOk) {
      _output.printError(Strings.backupFailed);
      exit(ExitCodes.toolError);
    }

    try {
      final String content =
          await service.generateGroupedPubspec(deps, devDeps);
      await File(FileConfig.pubspecFile).writeAsString(content);

      _output
        ..printBackupCreated()
        ..printSuccess(Strings.groupingSuccess);

      // Beta disclaimer and credits
      print('');
      _output.printInfo(Strings.betaWarning);
      _output.printInfo(Strings.flutterGemsCredit);
      exit(ExitCodes.success); // ✅ grouping applied
    } on Exception catch (e) {
      _output.printError('${Strings.failedToApplyGrouping}: $e');
      exit(ExitCodes.toolError);
    }
  }

  /// Interactive grouping with category overrides
  Future<void> _interactiveGrouping(
    GroupingService service,
    List<DependencyInfo> dependencies,
  ) async {
    final bool shouldOverride = InteractiveGroupingService.promptYesNo(
      Strings.overrideQuestion,
    );

    if (shouldOverride) {
      final InteractiveGroupingService interactive = InteractiveGroupingService(
        gemsIntegration: service.gemsIntegration,
      );

      interactive.showAvailableCategories();
      await interactive.promptForOverrides(dependencies);

      _output.printInfo(Strings.overridesSaved);
      _output.printInfo(Strings.runWithGroupClean);
      print('');
      _output.printInfo(Strings.flutterGemsCredit);
    } else {
      _output.printInfo('💡 To apply: smartpub group --apply');
      print('');
      _output.printInfo(Strings.flutterGemsCredit);
    }
  }

  /// Handle apply result and exit with the appropriate code.
  ///
  /// Exits [ExitCodes.success] (0):  apply succeeded (violations were fixed).
  /// Exits [ExitCodes.violationsFound] (1): apply itself failed internally.
  void _handleApplyResult(ApplyResult result) {
    if (result.success) {
      _output
        ..printBackupCreated()
        ..printSuccess('✅ pubspec.yaml updated successfully');
      exit(ExitCodes.success); // violations fixed → clean
    } else {
      _output.printError(result.error ?? 'Failed to apply changes');
      exit(ExitCodes.violationsFound); // couldn't fix them
    }
  }

  /// Restore from backup.
  ///
  /// Exits [ExitCodes.success] (0) on successful restore.
  /// Exits [ExitCodes.toolError] (2) when no backup exists or an IO error
  /// prevented restoring — both are tool-level errors, not violations.
  Future<void> _restoreBackup() async {
    print(Strings.appTitle);
    print('');
    _output.printInfo(Strings.restoringBackup);

    final BackupRestoreResult result = await BackupService.restoreFromBackup();

    switch (result.status) {
      case RestoreStatus.success:
        _output.printSuccess(Strings.restoreSuccess);
        exit(ExitCodes.success); // ✅ restored
      case RestoreStatus.noBackup:
        _output.printError(
          result.message ?? 'No backup file found. Run smartpub clean first.',
        );
        exit(ExitCodes.toolError); // 🔧 nothing to restore
      case RestoreStatus.ioError:
        _output.printError(result.message ?? Strings.restoreFailed);
        exit(ExitCodes.toolError); // 🔧 IO failure
    }
  }

  /// Update SmartPub.
  ///
  /// Exits [ExitCodes.success] (0) on successful update or when already
  /// up-to-date. Exits [ExitCodes.toolError] (2) on tool-level failures
  /// (not globally installed, network error, etc.).
  Future<void> _updateSmartPub() async {
    print(Strings.appTitle);
    print('');
    _output.printInfo(Strings.checkingForUpdates);

    // Check if globally installed
    final bool isGlobal = await UpdateChecker.isGloballyInstalled();
    if (!isGlobal) {
      _output.printError(
        'SmartPub is not globally installed. Install with: dart pub global activate smartpub',
      );
      exit(ExitCodes.toolError);
    }

    // Check for updates
    final UpdateInfo? updateInfo =
        await UpdateChecker.checkForUpdates(useCache: false);

    if (!(updateInfo?.hasUpdate ?? true)) {
      _output.printInfo(Strings.upToDate);
      return;
    }

    // Update
    _output.printInfo('🔄 Updating to ${updateInfo?.latestVersion}...');
    final bool success = await UpdateChecker.runUpdate();

    if (success) {
      _output.printSuccess('✅ Updated to ${updateInfo?.latestVersion}');
    } else {
      _output.printError('Failed to update');
      exit(ExitCodes.toolError);
    }
  }

  /// Print help
  void _printHelp() {
    print('''
📦 SmartPub – Flutter Dependency Analyzer

USAGE:
  smartpub [command] [options]

COMMANDS:
  check        Preview violations — unused deps, misplaced deps (default)
  clean        Remove unused / misplaced dependencies
  group        Preview dependency categorization
  restore      Restore pubspec.yaml from backup
  update       Update SmartPub to latest version

OPTIONS:
  --apply                  Apply changes automatically
  --interactive            Review and confirm changes interactively
  --no-fail-on-violations  Exit 0 even when violations are found (warn-only)
  --no-color               Disable colored output
  -h, --help               Show help information
  -v, --version            Show version information

EXIT CODES:
  0  Clean — no violations found, or violations were fixed successfully
  1  Violations found (use --no-fail-on-violations to suppress)
  2  Tool error — missing pubspec.yaml, no backup, parse failure
  3  Invalid arguments

EXAMPLES:
  smartpub
  smartpub check
  smartpub check --no-fail-on-violations   # warn-only, always exits 0

  smartpub clean
  smartpub clean --interactive

  smartpub group
  smartpub group --apply
  smartpub group --interactive

  smartpub restore
  smartpub update
''');
  }

  /// Print version
  void _printVersion() {
    print(Strings.appVersion);
  }
}
