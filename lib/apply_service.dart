/// Apply Service
///
/// Handles automatic application of dependency fixes including removing unused
/// dependencies and moving misplaced ones while creating safety backups.

import 'analyzer.dart';
import 'backup_service.dart';
import 'pubspec_manager.dart';
import 'models/dependency_info.dart';
import 'config.dart';

/// Service for applying dependency fixes
class ApplyService {
  /// Apply all recommended fixes automatically
  static Future<ApplyResult> applyFixes(AnalysisResult analysisResult) async {
    final changes = <DependencyChange>[];
    final appliedChanges = <String>[];

    try {
      // Create backup before making changes
      final backupCreated = await BackupService.createBackup();
      if (!backupCreated) {
        return ApplyResult(
          success: false,
          error: 'Failed to create backup',
          changes: [],
        );
      }

      // Generate changes for unused dependencies
      for (final dep in analysisResult.unusedDependencies) {
        changes.add(DependencyChange(
          packageName: dep.name,
          action: ChangeAction.remove,
        ));
        appliedChanges.add('Removed unused dependency: ${dep.name}');
      }

      // Generate changes for misplaced dependencies
      final misplacedDeps = analysisResult.testOnlyDependencies
          .where((dep) => dep.section == DependencySection.dependencies)
          .toList();

      for (final dep in misplacedDeps) {
        changes.add(DependencyChange(
          packageName: dep.name,
          action: ChangeAction.moveToDevDependencies,
        ));
        appliedChanges.add('Moved to dev_dependencies: ${dep.name}');
      }

      // Generate changes for duplicate dependencies
      for (final duplicate in analysisResult.duplicates) {
        if (duplicate.recommendedSection == DependencySection.dependencies) {
          // Remove from dev_dependencies, keep in dependencies
          changes.add(DependencyChange(
            packageName: duplicate.name,
            action: ChangeAction.removeFromDevDependencies,
          ));
          appliedChanges.add(
              'Removed duplicate from dev_dependencies: ${duplicate.name}');
        } else {
          // Remove from dependencies, keep in dev_dependencies
          changes.add(DependencyChange(
            packageName: duplicate.name,
            action: ChangeAction.removeFromDependencies,
          ));
          appliedChanges
              .add('Removed duplicate from dependencies: ${duplicate.name}');
        }
      }

      // Apply changes if any
      if (changes.isNotEmpty) {
        final success = await PubspecManager.applyChanges(changes);
        if (!success) {
          // Restore backup if apply failed
          await BackupService.restoreFromBackup();
          return ApplyResult(
            success: false,
            error: 'Failed to apply changes - backup restored',
            changes: [],
          );
        }
      }

      return ApplyResult(
        success: true,
        changes: appliedChanges,
        backupCreated: backupCreated,
      );
    } catch (e) {
      // Restore backup on error
      await BackupService.restoreFromBackup();
      return ApplyResult(
        success: false,
        error: 'Error applying changes: $e',
        changes: [],
      );
    }
  }

  /// Apply specific changes interactively
  static Future<ApplyResult> applyInteractive(
    AnalysisResult analysisResult,
    Future<bool> Function(String message) promptUser,
  ) async {
    final changes = <DependencyChange>[];
    final appliedChanges = <String>[];

    try {
      // Create backup before making changes
      final backupCreated = await BackupService.createBackup();
      if (!backupCreated) {
        return ApplyResult(
          success: false,
          error: 'Failed to create backup',
          changes: [],
        );
      }

      // Prompt for unused dependencies
      for (final dep in analysisResult.unusedDependencies) {
        final shouldRemove = await promptUser(
            '${OutputConfig.unusedIndicator} ${dep.name} — unused dependency. Remove it? [Y/n]');

        if (shouldRemove) {
          changes.add(DependencyChange(
            packageName: dep.name,
            action: ChangeAction.remove,
          ));
          appliedChanges.add('Removed unused dependency: ${dep.name}');
        }
      }

      // Prompt for misplaced dependencies
      final misplacedDeps = analysisResult.testOnlyDependencies
          .where((dep) => dep.section == DependencySection.dependencies)
          .toList();

      for (final dep in misplacedDeps) {
        final shouldMove = await promptUser(
            '${OutputConfig.testOnlyIndicator} ${dep.name} — ${dep.usageDescription}. Move to dev_dependencies? [Y/n]');

        if (shouldMove) {
          changes.add(DependencyChange(
            packageName: dep.name,
            action: ChangeAction.moveToDevDependencies,
          ));
          appliedChanges.add('Moved to dev_dependencies: ${dep.name}');
        }
      }

      // Prompt for duplicate dependencies
      for (final duplicate in analysisResult.duplicates) {
        final versionInfo = duplicate.hasVersionConflict
            ? ' (versions: ${duplicate.dependenciesVersion} vs ${duplicate.devDependenciesVersion})'
            : '';

        final shouldFix = await promptUser(
            '${OutputConfig.warningEmoji} ${duplicate.name}$versionInfo — duplicate. ${duplicate.recommendationMessage}? [Y/n]');

        if (shouldFix) {
          if (duplicate.recommendedSection == DependencySection.dependencies) {
            changes.add(DependencyChange(
              packageName: duplicate.name,
              action: ChangeAction.removeFromDevDependencies,
            ));
            appliedChanges.add(
                'Removed duplicate from dev_dependencies: ${duplicate.name}');
          } else {
            changes.add(DependencyChange(
              packageName: duplicate.name,
              action: ChangeAction.removeFromDependencies,
            ));
            appliedChanges
                .add('Removed duplicate from dependencies: ${duplicate.name}');
          }
        }
      }

      // Apply changes if any
      if (changes.isNotEmpty) {
        final success = await PubspecManager.applyChanges(changes);
        if (!success) {
          // Restore backup if apply failed
          await BackupService.restoreFromBackup();
          return ApplyResult(
            success: false,
            error: 'Failed to apply changes - backup restored',
            changes: [],
          );
        }
      }

      return ApplyResult(
        success: true,
        changes: appliedChanges,
        backupCreated: backupCreated,
      );
    } catch (e) {
      // Restore backup on error
      await BackupService.restoreFromBackup();
      return ApplyResult(
        success: false,
        error: 'Error applying changes: $e',
        changes: [],
      );
    }
  }

  /// Preview changes without applying them
  static List<String> previewChanges(AnalysisResult analysisResult) {
    final changes = <String>[];

    // Preview unused dependency removals
    for (final dep in analysisResult.unusedDependencies) {
      changes.add('Would remove unused dependency: ${dep.name}');
    }

    // Preview misplaced dependency moves
    final misplacedDeps = analysisResult.testOnlyDependencies
        .where((dep) => dep.section == DependencySection.dependencies)
        .toList();

    for (final dep in misplacedDeps) {
      changes.add(
          'Would move to dev_dependencies: ${dep.name} (${dep.usageDescription})');
    }

    // Preview duplicate dependency fixes
    for (final duplicate in analysisResult.duplicates) {
      if (duplicate.recommendedSection == DependencySection.dependencies) {
        changes.add(
            'Would remove duplicate from dev_dependencies: ${duplicate.name} (${duplicate.recommendationMessage})');
      } else {
        changes.add(
            'Would remove duplicate from dependencies: ${duplicate.name} (${duplicate.recommendationMessage})');
      }
    }

    return changes;
  }
}

/// Result of applying dependency changes
class ApplyResult {
  final bool success;
  final String? error;
  final List<String> changes;
  final bool backupCreated;

  ApplyResult({
    required this.success,
    this.error,
    required this.changes,
    this.backupCreated = false,
  });

  /// Whether any changes were made
  bool get hasChanges => changes.isNotEmpty;

  /// Number of changes applied
  int get changeCount => changes.length;
}
