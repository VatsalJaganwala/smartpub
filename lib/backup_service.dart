/// Safety Backup Service
///
/// Handles creating and restoring backups of pubspec.yaml files to ensure
/// safe dependency modifications with the ability to revert changes.
library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'config.dart';

/// Service for managing pubspec.yaml backups
class BackupService {
  /// Create a backup of the current pubspec.yaml file
  /// Returns true if backup was created successfully
  static Future<bool> createBackup() async {
    try {
      final pubspecFile = File(FileConfig.pubspecFile);

      // Check if pubspec.yaml exists
      if (!pubspecFile.existsSync()) {
        throw Exception('${FileConfig.pubspecFile} not found');
      }

      // Create backup by copying the file
      await pubspecFile.copy(FileConfig.backupFile);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore pubspec.yaml from backup
  /// Returns true if restore was successful
  static Future<bool> restoreFromBackup() async {
    try {
      final backupFile = File(FileConfig.backupFile);

      // Check if backup exists
      if (!backupFile.existsSync()) {
        throw Exception('No backup file found (${FileConfig.backupFile})');
      }

      // Restore by copying backup to pubspec.yaml
      await backupFile.copy(FileConfig.pubspecFile);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a backup file exists
  static bool backupExists() => File(FileConfig.backupFile).existsSync();

  /// Delete the backup file
  /// Returns true if deletion was successful
  static Future<bool> deleteBackup() async {
    try {
      final backupFile = File(FileConfig.backupFile);

      if (backupFile.existsSync()) {
        await backupFile.delete();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get backup file information
  static Future<BackupInfo?> getBackupInfo() async {
    try {
      final backupFile = File(FileConfig.backupFile);

      if (!backupFile.existsSync()) {
        return null;
      }

      final stat = await backupFile.stat();
      final size = stat.size;
      final modified = stat.modified;

      return BackupInfo(
        path: FileConfig.backupFile,
        size: size,
        lastModified: modified,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a timestamped backup (for multiple backups)
  static Future<String?> createTimestampedBackup() async {
    try {
      final pubspecFile = File(FileConfig.pubspecFile);

      if (!pubspecFile.existsSync()) {
        throw Exception('${FileConfig.pubspecFile} not found');
      }

      // Create timestamped backup filename
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final timestampedBackupPath =
          '${FileConfig.pubspecFile}.backup.$timestamp';

      // Create backup
      await pubspecFile.copy(timestampedBackupPath);

      return timestampedBackupPath;
    } catch (e) {
      return null;
    }
  }

  /// List all backup files in the current directory
  static List<String> listBackups() {
    final directory = Directory.current;
    final backups = <String>[];

    try {
      final files = directory.listSync();

      for (final file in files) {
        if (file is File) {
          final filename = path.basename(file.path);
          if (filename.startsWith('${FileConfig.pubspecFile}.backup') ||
              filename == FileConfig.backupFile) {
            backups.add(filename);
          }
        }
      }

      // Sort by modification time (newest first)
      backups.sort((String a, String b) {
        final fileA = File(a);
        final fileB = File(b);
        return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
      });
    } catch (e) {
      // Return empty list if error occurs
    }

    return backups;
  }
}

/// Information about a backup file
class BackupInfo {
  BackupInfo({
    required this.path,
    required this.size,
    required this.lastModified,
  });

  /// Path to the backup file
  final String path;

  /// Size of the backup file in bytes
  final int size;

  /// Last modified timestamp
  final DateTime lastModified;

  /// Get human-readable file size
  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Get formatted last modified time
  String get formattedLastModified {
    final now = DateTime.now();
    final difference = now.difference(lastModified);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${lastModified.day}/${lastModified.month}/${lastModified.year}';
  }
}
