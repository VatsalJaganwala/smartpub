/// CLI Output Formatter
///
/// Handles colored and structured output for the SmartPub CLI tool.
/// Provides consistent formatting for analysis results and user feedback.
library;

import 'package:ansicolor/ansicolor.dart';
import '../core/config.dart';
import '../core/models/dependency_info.dart';
import '../core/analyzer.dart';

/// CLI output formatter class
class CLIOutput {
  CLIOutput({this.noColor = false}) {
    if (noColor) {
      ansiColorDisabled = true;
    }
  }

  /// Whether colors are disabled
  final bool noColor;

  /// Print analysis results in dry-run format
  void printDryRunResults(AnalysisResult result) {
    _printSectionHeader('Analysis Results (Dry Run)');

    if (!result.hasIssues) {
      _printSuccess(
          'No issues found! All dependencies are properly organized.');
      return;
    }

    // Print used dependencies
    if (result.usedDependencies.isNotEmpty) {
      _printSubHeader('${OutputConfig.usedIndicator} Used Dependencies');
      for (final dep in result.usedDependencies) {
        _printDependency(dep, OutputConfig.usedIndicator);
      }
      print('');
    }

    // Print test-only dependencies that need moving
    final testOnlyInWrongSection = result.testOnlyDependencies
        .where((DependencyInfo dep) =>
            dep.section == DependencySection.dependencies)
        .toList();

    if (testOnlyInWrongSection.isNotEmpty) {
      _printSubHeader(
          '${OutputConfig.testOnlyIndicator} Move to dev_dependencies');
      for (final dep in testOnlyInWrongSection) {
        _printDependency(dep, OutputConfig.testOnlyIndicator);
      }
      print('');
    }

    // Print unused dependencies
    if (result.unusedDependencies.isNotEmpty) {
      _printSubHeader('${OutputConfig.unusedIndicator} Unused Dependencies');
      for (final dep in result.unusedDependencies) {
        _printDependency(dep, OutputConfig.unusedIndicator);
      }
      print('');
    }

    // Print duplicates
    if (result.duplicates.isNotEmpty) {
      _printSubHeader('${OutputConfig.warningEmoji} Duplicate Dependencies');
      for (final duplicate in result.duplicates) {
        final versionInfo = duplicate.hasVersionConflict
            ? ' (${duplicate.dependenciesVersion} vs ${duplicate.devDependenciesVersion})'
            : '';
        _printWarning(
            '${duplicate.name}$versionInfo - ${duplicate.recommendationMessage}');
      }
      print('');
    }

    // Print summary
    _printSummary(result);
  }

  /// Print a dependency with status indicator
  void _printDependency(DependencyInfo dep, String indicator) {
    final message = '$indicator ${dep.name} - ${dep.usageDescription}';

    if (!ansiColorDisabled) {
      AnsiPen pen;
      switch (dep.status) {
        case DependencyStatus.used:
          pen = AnsiPen()..green();
          break;
        case DependencyStatus.testOnly:
          pen = AnsiPen()..yellow();
          break;
        case DependencyStatus.unused:
          pen = AnsiPen()..red();
          break;
      }
      print(pen(message));
    } else {
      print(message);
    }
  }

  /// Print section header
  void _printSectionHeader(String title) {
    if (!ansiColorDisabled) {
      final pen = AnsiPen()..blue(bold: true);
      print(pen('\n┌${'─' * (title.length + 2)}┐'));
      print(pen('│ $title │'));
      print(pen('└${'─' * (title.length + 2)}┘\n'));
    } else {
      print('\n=== $title ===\n');
    }
  }

  /// Print sub-header
  void _printSubHeader(String title) {
    if (!ansiColorDisabled) {
      final pen = AnsiPen()..cyan(bold: true);
      print(pen(title));
    } else {
      print(title);
    }
  }

  /// Print success message
  void _printSuccess(String message) {
    if (!ansiColorDisabled) {
      final pen = AnsiPen()..green();
      print(pen('${OutputConfig.successEmoji} $message'));
    } else {
      print('SUCCESS: $message');
    }
  }

  /// Print warning message
  void _printWarning(String message) {
    if (!ansiColorDisabled) {
      final pen = AnsiPen()..yellow();
      print(pen('${OutputConfig.warningEmoji} $message'));
    } else {
      print('${OutputConfig.warningPrefix} $message');
    }
  }

  /// Print error message
  void printError(String message) {
    if (!ansiColorDisabled) {
      final pen = AnsiPen()..red();
      print(pen('${OutputConfig.errorEmoji} $message'));
    } else {
      print('${OutputConfig.errorPrefix} $message');
    }
  }

  /// Print info message
  void printInfo(String message) {
    if (!ansiColorDisabled) {
      final pen = AnsiPen()..blue();
      print(pen('${OutputConfig.infoEmoji} $message'));
    } else {
      print('${OutputConfig.infoPrefix} $message');
    }
  }

  /// Print analysis summary
  void _printSummary(AnalysisResult result) {
    _printSubHeader('Summary');

    print('Total dependencies scanned: ${result.totalScanned}');
    print('Used dependencies: ${result.usedDependencies.length}');
    print('Test-only dependencies: ${result.testOnlyDependencies.length}');
    print('Unused dependencies: ${result.unusedDependencies.length}');

    if (result.duplicates.isNotEmpty) {
      print('Duplicate dependencies: ${result.duplicates.length}');
    }

    if (result.hasIssues) {
      final issueCount = result.testOnlyDependencies
              .where((DependencyInfo dep) =>
                  dep.section == DependencySection.dependencies)
              .length +
          result.unusedDependencies.length +
          result.duplicates.length;

      _printWarning('$issueCount issue(s) found that can be fixed');
    } else {
      _printSuccess('No issues found!');
    }
  }

  /// Print backup creation success message
  void printBackupCreated() {
    if (!ansiColorDisabled) {
      final green = AnsiPen()..green();
      print(green('💾 Backup created: ${FileConfig.backupFile}'));
    } else {
      print('Backup created: ${FileConfig.backupFile}');
    }
  }

  /// Print backup restoration success message
  void printBackupRestored() {
    if (!ansiColorDisabled) {
      final green = AnsiPen()..green();
      print(green(
          '${OutputConfig.successEmoji} Restored ${FileConfig.pubspecFile} from backup'));
    } else {
      print('SUCCESS: Restored ${FileConfig.pubspecFile} from backup');
    }
  }

  /// Print success message
  void printSuccess(String message) {
    if (!ansiColorDisabled) {
      final green = AnsiPen()..green();
      print(green('${OutputConfig.successEmoji} $message'));
    } else {
      print('SUCCESS: $message');
    }
  }
}
