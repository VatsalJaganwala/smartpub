/// Telemetry Service
///
/// Collects anonymous usage statistics to help improve SmartPub.
/// All telemetry is opt-in and contains no personally identifiable information.
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service for collecting anonymous usage telemetry
class TelemetryService {
  TelemetryService({
    this.enabled = true,
    this.apiEndpoint = 'https://smartpub-telemetry.example.com',
  });

  /// Whether telemetry is enabled
  final bool enabled;

  /// Telemetry API endpoint
  final String apiEndpoint;

  /// Record categorization usage
  Future<void> recordCategorizationUsage({
    required int totalPackages,
    required int categorizedPackages,
    required int cacheHits,
    required int firestoreHits,
    required int fallbackHits,
    required int heuristicHits,
    required int overrideCount,
  }) async {
    if (!enabled) return;

    try {
      final payload = {
        'event': 'categorization_usage',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'total_packages': totalPackages,
          'categorized_packages': categorizedPackages,
          'cache_hits': cacheHits,
          'firestore_hits': firestoreHits,
          'fallback_hits': fallbackHits,
          'heuristic_hits': heuristicHits,
          'override_count': overrideCount,
        },
        'version': '1.0.1',
      };

      await http
          .post(
            Uri.parse('$apiEndpoint/events'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent':
                  'SmartPub/1.0 (+https://github.com/VatsalJaganwala/smartpub)',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silently fail - telemetry should never interfere with functionality
    }
  }

  /// Record general usage statistics
  Future<void> recordUsage({
    required String command,
    required int dependencyCount,
    required int issuesFound,
    required bool applied,
  }) async {
    if (!enabled) return;

    try {
      final payload = {
        'event': 'general_usage',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'command': command,
          'dependency_count': dependencyCount,
          'issues_found': issuesFound,
          'applied': applied,
          'platform': Platform.operatingSystem,
        },
        'version': '1.0.1',
      };

      await http
          .post(
            Uri.parse('$apiEndpoint/events'),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent':
                  'SmartPub/1.0 (+https://github.com/VatsalJaganwala/smartpub)',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silently fail - telemetry should never interfere with functionality
    }
  }
}
