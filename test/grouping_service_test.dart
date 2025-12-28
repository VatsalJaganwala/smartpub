/// Tests for Grouping Service
library;

import 'dart:io';
import 'package:test/test.dart';
import 'package:smartpub/categorization/gems_integration.dart';
import 'package:smartpub/categorization/grouping_service.dart';
import 'package:smartpub/core/models/dependency_info.dart';

void main() {
  group('GroupingService', () {
    late GemsIntegration gemsIntegration;
    late GroupingService groupingService;

    setUp(() {
      gemsIntegration = GemsIntegration(
        useGems: true,
        updateCache: false,
        fetchGemsFallback: false,
      );
      groupingService = GroupingService(
        gemsIntegration: gemsIntegration,
      );
    });

    tearDown(() async {
      // Clean up test files
      final cacheDir = Directory('.smartpub/cache');
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }

      final overridesFile = File('group-overrides.yaml');
      if (overridesFile.existsSync()) {
        await overridesFile.delete();
      }
    });

    test('should group dependencies by categories', () async {
      await gemsIntegration.initialize();

      final dependencies = [
        DependencyInfo(
          name: 'http',
          version: '^1.1.0',
          section: DependencySection.dependencies,
          status: DependencyStatus.used,
          usedInLib: true,
          usedInTest: false,
          usedInBin: false,
          usedInTool: false,
        ),
        DependencyInfo(
          name: 'flutter_bloc',
          version: '^8.0.0',
          section: DependencySection.dependencies,
          status: DependencyStatus.used,
          usedInLib: true,
          usedInTest: false,
          usedInBin: false,
          usedInTool: false,
        ),
        DependencyInfo(
          name: 'sqflite',
          version: '^2.0.0',
          section: DependencySection.dependencies,
          status: DependencyStatus.used,
          usedInLib: true,
          usedInTest: false,
          usedInBin: false,
          usedInTool: false,
        ),
      ];

      final grouped = await groupingService.groupDependencies(dependencies);

      expect(grouped.grouped.containsKey('Networking'), isTrue);
      expect(grouped.grouped.containsKey('State Management'), isTrue);
      expect(grouped.grouped.containsKey('Database'), isTrue);

      expect(grouped.grouped['Networking']!.length, equals(1));
      expect(grouped.grouped['Networking']!.first.name, equals('http'));

      expect(grouped.grouped['State Management']!.length, equals(1));
      expect(grouped.grouped['State Management']!.first.name,
          equals('flutter_bloc'));

      expect(grouped.grouped['Database']!.length, equals(1));
      expect(grouped.grouped['Database']!.first.name, equals('sqflite'));
    });

    test('should respect group overrides', () async {
      await gemsIntegration.initialize();

      final overrides = {'http': 'Custom Category'};
      final groupingServiceWithOverrides = GroupingService(
        gemsIntegration: gemsIntegration,
        groupOverrides: overrides,
      );

      final dependencies = [
        DependencyInfo(
          name: 'http',
          version: '^1.1.0',
          section: DependencySection.dependencies,
          status: DependencyStatus.used,
          usedInLib: true,
          usedInTest: false,
          usedInBin: false,
          usedInTool: false,
        ),
      ];

      final grouped =
          await groupingServiceWithOverrides.groupDependencies(dependencies);

      expect(grouped.grouped.containsKey('Custom Category'), isTrue);
      expect(grouped.grouped['Custom Category']!.length, equals(1));
      expect(grouped.grouped['Custom Category']!.first.name, equals('http'));
    });

    test('should generate preview correctly', () async {
      await gemsIntegration.initialize();

      final dependencies = [
        DependencyInfo(
          name: 'http',
          version: '^1.1.0',
          section: DependencySection.dependencies,
          status: DependencyStatus.used,
          usedInLib: true,
          usedInTest: false,
          usedInBin: false,
          usedInTool: false,
        ),
      ];

      final grouped = await groupingService.groupDependencies(dependencies);
      final preview = groupingService.generatePreview(
          grouped, GroupedDependencies(grouped: {}, categoryOrder: []));

      expect(preview, contains('dependencies:'));
      expect(preview, contains('# Networking'));
      expect(preview, contains('http: ^1.1.0'));
    });

    test('should save and load group overrides', () async {
      final overrides = {
        'http': 'Custom Networking',
        'flutter_bloc': 'Custom State Management',
      };

      await saveGroupOverrides(overrides);

      final loaded = await loadGroupOverrides();
      expect(loaded, isNotNull);
      expect(loaded!['http'], equals('Custom Networking'));
      expect(loaded['flutter_bloc'], equals('Custom State Management'));
    });

    test('should handle empty dependencies gracefully', () async {
      await gemsIntegration.initialize();

      final grouped = await groupingService.groupDependencies([]);
      expect(grouped.grouped, isEmpty);
      expect(grouped.categoryOrder, isEmpty);
      expect(grouped.totalPackages, equals(0));
      expect(grouped.categoryCount, equals(0));
    });
  });
}
