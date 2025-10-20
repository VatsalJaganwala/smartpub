/// Update Checker Service
///
/// Checks for newer versions of SmartPub from pub.dev and provides
/// update notifications and automatic update functionality.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'config.dart';

/// Service for checking and managing SmartPub updates
class UpdateChecker {
  /// Cache file name for storing last check information
  static const String _cacheFileName = '.smartpub_update_cache.json';

  /// Cache duration in hours (24 hours)
  static const int _cacheDurationHours = 24;

  /// pub.dev API endpoint for package information
  static const String _pubDevApiUrl = 'https://pub.dev/api/packages/smartpub';

  /// Check for updates and return update information
  /// [useCache] - if true, uses cached data when available (default: true)
  /// Set to false for explicit update commands to always check pub.dev
  static Future<UpdateInfo> checkForUpdates({bool useCache = true}) async {
    try {
      // Check cache first only if useCache is true
      if (useCache) {
        final cachedInfo = await _getCachedUpdateInfo();
        if (cachedInfo != null && !_isCacheExpired(cachedInfo.lastChecked)) {
          return cachedInfo;
        }
      }

      // Fetch latest version from pub.dev
      final latestVersion = await _fetchLatestVersion();
      if (latestVersion == null) {
        return UpdateInfo(
          currentVersion: AppConfig.version,
          latestVersion: AppConfig.version,
          hasUpdate: false,
          lastChecked: DateTime.now(),
        );
      }

      // Compare versions
      final hasUpdate = _isNewerVersion(latestVersion, AppConfig.version);

      final updateInfo = UpdateInfo(
        currentVersion: AppConfig.version,
        latestVersion: latestVersion,
        hasUpdate: hasUpdate,
        lastChecked: DateTime.now(),
      );

      // Cache the result
      await _cacheUpdateInfo(updateInfo);

      return updateInfo;
    } catch (e) {
      // Return no update info on error
      return UpdateInfo(
        currentVersion: AppConfig.version,
        latestVersion: AppConfig.version,
        hasUpdate: false,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Fetch the latest version from pub.dev API
  static Future<String?> _fetchLatestVersion() async {
    try {
      final response = await http
          .get(
            Uri.parse(_pubDevApiUrl),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final latest = jsonData['latest'] as Map<String, dynamic>?;
        return latest?['version'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Compare two version strings to determine if first is newer than second
  static bool _isNewerVersion(String version1, String version2) {
    final v1Parts = version1
        .split('.')
        .map(int.tryParse)
        .where((int? v) => v != null)
        .cast<int>()
        .toList();
    final v2Parts = version2
        .split('.')
        .map(int.tryParse)
        .where((int? v) => v != null)
        .cast<int>()
        .toList();

    // Pad shorter version with zeros
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return true;
      if (v1Parts[i] < v2Parts[i]) return false;
    }

    return false; // Versions are equal
  }

  /// Get cached update information
  static Future<UpdateInfo?> _getCachedUpdateInfo() async {
    try {
      final cacheFile = await _getCacheFile();
      if (!cacheFile.existsSync()) return null;

      final content = await cacheFile.readAsString();
      final jsonData = jsonDecode(content) as Map<String, dynamic>;

      return UpdateInfo.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Cache update information
  static Future<void> _cacheUpdateInfo(UpdateInfo info) async {
    try {
      final cacheFile = await _getCacheFile();
      await cacheFile.writeAsString(jsonEncode(info.toJson()));
    } catch (e) {
      // Ignore cache write errors
    }
  }

  /// Get the cache file
  static Future<File> _getCacheFile() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '.';
    final cacheDir = Directory(path.join(homeDir, '.smartpub'));

    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }

    return File(path.join(cacheDir.path, _cacheFileName));
  }

  /// Check if cache is expired
  static bool _isCacheExpired(DateTime lastChecked) {
    final now = DateTime.now();
    final difference = now.difference(lastChecked);
    return difference.inHours >= _cacheDurationHours;
  }

  /// Run the update command
  static Future<bool> runUpdate() async {
    try {
      final result = await Process.run(
        'dart',
        <String>['pub', 'global', 'activate', 'smartpub'],
        runInShell: true,
      );

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if SmartPub is globally installed
  static Future<bool> isGloballyInstalled() async {
    try {
      final result = await Process.run(
        'dart',
        <String>['pub', 'global', 'list'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        return output.contains('smartpub ');
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clear the update cache
  static Future<void> clearCache() async {
    try {
      final cacheFile = await _getCacheFile();
      if (cacheFile.existsSync()) {
        await cacheFile.delete();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Information about available updates
class UpdateInfo {
  UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.hasUpdate,
    required this.lastChecked,
    this.error,
  });

  /// Create UpdateInfo from JSON
  factory UpdateInfo.fromJson(Map<String, dynamic> json) => UpdateInfo(
        currentVersion: json['currentVersion'] as String,
        latestVersion: json['latestVersion'] as String,
        hasUpdate: json['hasUpdate'] as bool,
        lastChecked: DateTime.parse(json['lastChecked'] as String),
        error: json['error'] as String?,
      );
  final String currentVersion;
  final String latestVersion;
  final bool hasUpdate;
  final DateTime lastChecked;
  final String? error;

  /// Convert UpdateInfo to JSON
  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'hasUpdate': hasUpdate,
        'lastChecked': lastChecked.toIso8601String(),
        if (error != null) 'error': error,
      };

  /// Get formatted update message
  String get updateMessage {
    if (!hasUpdate) return '';

    return '${OutputConfig.warningEmoji} Update available: $latestVersion (current: $currentVersion)\n'
        'Run `smartpub --update` to update.';
  }

  /// Whether the check was successful
  bool get isSuccessful => error == null;
}
