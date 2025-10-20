/// Interactive Service
///
/// Handles user interaction for the interactive mode, including prompts
/// and user input validation.
library;

import 'dart:io';

/// Service for handling interactive user prompts
class InteractiveService {
  /// Prompt user with a yes/no question
  /// Returns true for yes, false for no
  static Future<bool> promptYesNo(String message) async {
    while (true) {
      stdout.write('$message ');
      final input = stdin.readLineSync()?.toLowerCase().trim() ?? '';

      // Default to yes if empty input
      if (input.isEmpty || input == 'y' || input == 'yes') {
        return true;
      }

      if (input == 'n' || input == 'no') {
        return false;
      }

      // Invalid input, ask again
      print('Please enter Y (yes) or N (no)');
    }
  }

  /// Prompt user to continue with the operation
  static Future<bool> promptContinue(String message) async =>
      promptYesNo('$message Continue? [Y/n]');

  /// Show a summary and ask for confirmation
  static Future<bool> confirmChanges(List<String> changes) async {
    if (changes.isEmpty) {
      print('No changes to apply.');
      return false;
    }

    print('\nThe following changes will be made:');
    for (int i = 0; i < changes.length; i++) {
      print('  ${i + 1}. ${changes[i]}');
    }
    print('');

    return promptYesNo('Apply these ${changes.length} change(s)? [Y/n]');
  }

  /// Show progress indicator
  static void showProgress(String message) {
    stdout.write('$message... ');
  }

  /// Show completion message
  static void showComplete(String message) {
    print(message);
  }

  /// Show error message
  static void showError(String message) {
    stderr.writeln('Error: $message');
  }

  /// Show warning message
  static void showWarning(String message) {
    print('Warning: $message');
  }

  /// Show info message
  static void showInfo(String message) {
    print('Info: $message');
  }

  /// Prompt user to select from multiple options
  static Future<int?> promptSelect(String message, List<String> options) async {
    print(message);
    for (int i = 0; i < options.length; i++) {
      print('  ${i + 1}. ${options[i]}');
    }

    while (true) {
      stdout.write('Select option (1-${options.length}) or 0 to cancel: ');
      final input = stdin.readLineSync()?.trim() ?? '';

      if (input == '0') {
        return null; // Cancel
      }

      final selection = int.tryParse(input);
      if (selection != null && selection >= 1 && selection <= options.length) {
        return selection - 1; // Convert to 0-based index
      }

      print(
          'Invalid selection. Please enter a number between 0 and ${options.length}');
    }
  }

  /// Show a list with numbered items
  static void showList(String title, List<String> items) {
    if (items.isEmpty) {
      print('$title: None');
      return;
    }

    print('$title:');
    for (int i = 0; i < items.length; i++) {
      print('  ${i + 1}. ${items[i]}');
    }
  }

  /// Wait for user to press Enter
  static Future<void> waitForEnter([String? message]) async {
    stdout.write(message ?? 'Press Enter to continue...');
    stdin.readLineSync();
  }

  /// Clear the console (cross-platform)
  static void clearConsole() {
    if (Platform.isWindows) {
      Process.runSync('cls', <String>[], runInShell: true);
    } else {
      Process.runSync('clear', <String>[], runInShell: true);
    }
  }
}
