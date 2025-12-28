/// Tests for FlutterGems Integration
library;

import 'dart:io';
import 'package:test/test.dart';
import 'package:smartpub/categorization/gems_integration.dart';

void main() {
  group('GemsIntegration', () {
    late GemsIntegration gemsIntegration;

    setUp(() {
      gemsIntegration = GemsIntegration(
        useGems: true,
        updateCache: false,
        fetchGemsFallback: false,
      );
    });

    tearDown(() async {
      // Clean up test cache
      final cacheDir = Directory('.smartpub/cache');
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
    });

    test('should initialize without errors', () async {
      await expectLater(
        gemsIntegration.initialize(),
        completes,
      );
    });

    test('should classify packages using heuristics when gems disabled',
        () async {
      final disabledIntegration = GemsIntegration(useGems: false);
      await disabledIntegration.initialize();

      final category = await disabledIntegration.classifyPackage('http');
      expect(category, equals('Networking'));
    });

    test('should infer categories by name correctly', () async {
      final testCases = {
        'http': 'Networking',
        'dio': 'Networking',
        'flutter_bloc': 'State Management',
        'provider': 'State Management',
        'sqflite': 'Database',
        'hive': 'Database',
        'cached_network_image': 'UI Components',
        'test': 'Testing',
        'mockito': 'Testing',
        'build_runner': 'Development Tools',
        'json_serializable': 'Development Tools',
        'unknown_package': 'Utilities',
      };

      for (final entry in testCases.entries) {
        final category = await gemsIntegration.classifyPackage(entry.key);
        expect(category, equals(entry.value), reason: 'Package: ${entry.key}');
      }
    });

    test('should handle cache operations', () async {
      await gemsIntegration.initialize();

      // Test package classification (should use heuristics since no cache/firestore)
      final category = await gemsIntegration.classifyPackage('http');
      expect(category, equals('Networking'));

      // Verify cache directory was created
      final cacheDir = Directory('.smartpub/cache');
      expect(cacheDir.existsSync(), isTrue);
    });

    test('PackageCategory should serialize/deserialize correctly', () {
      final original = PackageCategory(
        name: 'test_package',
        categories: ['Testing', 'Development Tools'],
        primaryCategory: 'Testing',
        source: 'firestore',
        confidence: 0.95,
        fetchedAt: DateTime.parse('2025-12-07T10:00:00Z'),
      );

      final json = original.toJson();
      final restored = PackageCategory.fromJson(json);

      expect(restored.name, equals(original.name));
      expect(restored.categories, equals(original.categories));
      expect(restored.primaryCategory, equals(original.primaryCategory));
      expect(restored.source, equals(original.source));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.fetchedAt, equals(original.fetchedAt));
    });
  });
}
