/// Interactive Grouping Service
///
/// Handles interactive category overrides and user input for package grouping.
library;

import 'dart:io';
import '../categorization/gems_integration.dart';
import '../categorization/grouping_service.dart';
import '../core/models/dependency_info.dart';
import '../core/strings.dart';

/// Service for interactive package categorization
class InteractiveGroupingService {
  InteractiveGroupingService({
    required this.gemsIntegration,
  });

  /// Gems integration service
  final GemsIntegration gemsIntegration;

  /// Prompt user for category overrides
  Future<Map<String, String>> promptForOverrides(
    List<DependencyInfo> dependencies,
  ) async {
    final Map<String, String> overrides = <String, String>{};

    print('\n${Strings.interactiveCategoryOverride}');
    print(Strings.overridePrompt);
    print('');

    int current = 0;
    for (final DependencyInfo dep in dependencies) {
      current++;

      final List<String> categories =
          await gemsIntegration.getPackageCategories(dep.name);

      final String suggestedCategory =
          categories.isNotEmpty ? categories.first : 'Utilities';

      print(
        '[$current/${dependencies.length}] ${dep.name} '
        '(suggested: $suggestedCategory)[Enter y to keep suggested]:',
      );
      final String input = stdin.readLineSync() ?? '';

      if (input.toLowerCase() == 'y') {
        // 'y' pressed → keep suggested category
        continue;
      } 
      if (input.isEmpty) {
        // Enter pressed → keep suggested category
        continue;
      }

      if (input != suggestedCategory) {
        overrides[dep.name] = input;
        print('  → Override: ${dep.name} → $input');
      }
    }
    if (overrides.isNotEmpty) {
      print('\n📝 Saving overrides to group-overrides.yaml...');
      await saveGroupOverrides(overrides);
    }

    return overrides;
  }

  /// Show available categories for reference
  void showAvailableCategories() {
    print('\n📋 Available Categories:');
    const categories = [
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

    for (final category in categories) {
      print('  • $category');
    }
    print('');
  }

  /// Prompt yes/no question
  static bool promptYesNo(String question, {bool defaultValue = false}) {
    final defaultText = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('$question [$defaultText]: ');

    final input = stdin.readLineSync()?.trim().toLowerCase();

    if (input == null || input.isEmpty) {
      return defaultValue;
    }

    return input == 'y' || input == 'yes';
  }
}
