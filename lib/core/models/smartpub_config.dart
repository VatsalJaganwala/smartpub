import 'dart:io';
import 'package:checked_yaml/checked_yaml.dart';
import '../config.dart';

/// Configuration for SmartPub checks selection
class SmartpubChecksConfig {
  const SmartpubChecksConfig({
    this.unused = true,
    this.missing = true,
    this.promotions = true,
  });

  /// Check for unused dependencies
  final bool unused;

  /// Check for missing dependencies
  final bool missing;

  /// Check for misplaced dependencies
  final bool promotions;

  /// Parse from json Map
  factory SmartpubChecksConfig.fromJson(Map json) {
    return SmartpubChecksConfig(
      unused: json['unused'] as bool? ?? true,
      missing: json['missing'] as bool? ?? true,
      promotions: json['promotions'] as bool? ?? true,
    );
  }
}

/// Main configuration model for smartpub.yaml
class SmartpubConfig {
  const SmartpubConfig({
    this.ignore = const <String>[],
    this.exclude = const <String>[],
    this.allowPins = false,
    this.failOnViolations = true,
    this.checks = const SmartpubChecksConfig(),
  });

  /// Dependencies to never flag as unused or misplaced
  final List<String> ignore;

  /// Directories/files to exclude from import scanning
  final List<String> exclude;

  /// Whether to allow version pins without warnings
  final bool allowPins;

  /// Whether to exit non-zero when violations exist
  final bool failOnViolations;

  /// Selection of checks to run
  final SmartpubChecksConfig checks;

  /// Parse from json Map
  factory SmartpubConfig.fromJson(Map json) {
    return SmartpubConfig(
      ignore: (json['ignore'] as List?)?.cast<String>() ?? const <String>[],
      exclude: (json['exclude'] as List?)?.cast<String>() ?? const <String>[],
      allowPins: json['allow_pins'] as bool? ?? false,
      failOnViolations: json['fail_on_violations'] as bool? ?? true,
      checks: json['checks'] is Map
          ? SmartpubChecksConfig.fromJson(json['checks'] as Map)
          : const SmartpubChecksConfig(),
    );
  }

  /// Load config from file, fall back to defaults
  static SmartpubConfig load(String projectPath, {String? configPath}) {
    final File file = configPath != null
        ? File(configPath)
        : File('$projectPath/smartpub.yaml');

    if (!file.existsSync()) {
      if (configPath != null) {
        throw Exception('Config file not found at $configPath');
      }
      return const SmartpubConfig();
    }

    try {
      return checkedYamlDecode(
        file.readAsStringSync(),
        (m) => SmartpubConfig.fromJson(m!),
        sourceUrl: Uri.file(file.path),
      );
    } on ParsedYamlException catch (e) {
      stderr.writeln('❌ Config YAML parse error:\n${e.formattedMessage}');
      exit(ExitCodes.toolError); // Exit code 2 on bad config YAML format
    } catch (e) {
      stderr.writeln('❌ Failed to load config: $e');
      exit(ExitCodes.toolError);
    }
  }
}
