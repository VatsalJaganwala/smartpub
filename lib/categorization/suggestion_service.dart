/// Package Suggestion Service
///
/// Handles submitting package categorization suggestions to the maintainers
/// for packages not found in the FlutterGems database.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for submitting package categorization suggestions
class SuggestionService {
  SuggestionService({
    this.apiEndpoint = 'https://smartpub-api.example.com',
  });

  /// API endpoint for suggestions
  final String apiEndpoint;

  /// Submit a package categorization suggestion
  Future<bool> submitSuggestion({
    required String packageName,
    required List<String> categories,
    String? notes,
  }) async {
    try {
      final payload = {
        'name': packageName,
        'categories': categories,
        'source': 'cli-suggestion',
        'notes': notes ?? 'Suggested by SmartPub user',
        'submittedAt': DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('$apiEndpoint/suggest/package'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'SmartPub/1.0 (+https://github.com/VatsalJaganwala/smartpub)',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Silently fail for now - suggestions are optional
      return false;
    }
  }

  /// Submit multiple suggestions in batch
  Future<int> submitBatchSuggestions(
    List<PackageSuggestion> suggestions,
  ) async {
    int successCount = 0;

    for (final suggestion in suggestions) {
      final success = await submitSuggestion(
        packageName: suggestion.packageName,
        categories: suggestion.categories,
        notes: suggestion.notes,
      );

      if (success) {
        successCount++;
      }

      // Add small delay to be polite to the API
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return successCount;
  }
}

/// Package suggestion data structure
class PackageSuggestion {
  PackageSuggestion({
    required this.packageName,
    required this.categories,
    this.notes,
  });

  /// Package name
  final String packageName;

  /// Suggested categories
  final List<String> categories;

  /// Optional notes
  final String? notes;
}
