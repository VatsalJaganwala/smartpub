/// Interactive Grouping Service
///
/// Handles interactive category overrides and user input for package grouping.
library;

import 'dart:io';
import '../core/models/dependency_info.dart';
import '../categorization/gems_integration.dart';
import '../categorization/grouping_service.dart';

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
    final overrides = <String, String>{};

    print('\n🤝 Interactive Category Override Mode');
    print(
        'Press Enter to keep suggested category, or type a new category name.\n');

    for (final dep in dependencies) {
      // Get suggested categories
      final categories = await gemsIntegration.getPackageCategories(dep.name);
      final suggestedCategory =
          categories.isNotEmpty ? categories.first : 'Utilities';

      stdout.write('${dep.name} (suggested: $suggestedCategory): ');
      final input = stdin.readLineSync()?.trim();

      if (input != null && input.isNotEmpty && input != suggestedCategory) {
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
