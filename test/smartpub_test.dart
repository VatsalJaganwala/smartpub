import 'package:test/test.dart';
import 'package:smartpub/analyzer.dart';
import 'package:smartpub/config.dart';
import 'package:smartpub/models/dependency_info.dart';

void main() {
  group('SmartPub Tests', () {
    test('AppConfig contains correct values', () {
      expect(AppConfig.appName, equals('SmartPub'));
      expect(AppConfig.version, equals('1.0.0+1'));
      expect(AppConfig.description, equals('Flutter Dependency Analyzer'));
    });

    test('FileConfig contains correct file names', () {
      expect(FileConfig.pubspecFile, equals('pubspec.yaml'));
      expect(FileConfig.backupFile, equals('pubspec.yaml.bak'));
      expect(FileConfig.dartExtension, equals('.dart'));
    });

    test('AnalysisConfig contains correct patterns', () {
      expect(AnalysisConfig.dependenciesSection, equals('dependencies'));
      expect(AnalysisConfig.devDependenciesSection, equals('dev_dependencies'));
      expect(AnalysisConfig.flutterSdk, equals('flutter'));
    });

    test('DependencyInfo model works correctly', () {
      final dep = DependencyInfo(
        name: 'test_package',
        version: '^1.0.0',
        section: DependencySection.dependencies,
        status: DependencyStatus.used,
        usedInLib: true,
        usedInTest: false,
        usedInBin: false,
        usedInTool: false,
      );

      expect(dep.name, equals('test_package'));
      expect(dep.version, equals('^1.0.0'));
      expect(dep.section, equals(DependencySection.dependencies));
      expect(dep.status, equals(DependencyStatus.used));
      expect(dep.usedInLib, isTrue);
      expect(dep.usageDescription, equals('used in lib'));
      expect(dep.recommendation, equals('Keep in dependencies'));
      expect(dep.needsAction, isFalse);
    });

    test('DependencyStatus enum extensions work', () {
      expect(DependencyStatus.used.displayName, equals('Used'));
      expect(DependencyStatus.testOnly.displayName, equals('Test Only'));
      expect(DependencyStatus.unused.displayName, equals('Unused'));
    });

    test('DependencySection enum extensions work', () {
      expect(DependencySection.dependencies.displayName, equals('dependencies'));
      expect(DependencySection.devDependencies.displayName, equals('dev_dependencies'));
    });

    test('PackageUsage tracks usage correctly', () {
      final usage = PackageUsage(packageName: 'test_package');
      expect(usage.isUsed, isFalse);

      usage.usedInLib = true;
      expect(usage.isUsed, isTrue);

      usage.usedInTest = true;
      expect(usage.isUsed, isTrue);
    });

    test('OutputConfig contains correct emojis', () {
      expect(OutputConfig.packageEmoji, equals('📦'));
      expect(OutputConfig.successEmoji, equals('✅'));
      expect(OutputConfig.errorEmoji, equals('❌'));
      expect(OutputConfig.warningEmoji, equals('⚠️'));
    });

    test('CommandConfig contains correct flags', () {
      expect(CommandConfig.analyseFlag, equals('analyse'));
      expect(CommandConfig.applyFlag, equals('apply'));
      expect(CommandConfig.interactiveFlag, equals('interactive'));
      expect(CommandConfig.restoreFlag, equals('restore'));
      expect(CommandConfig.helpFlag, equals('help'));
      expect(CommandConfig.versionFlag, equals('version'));
    });

    test('ExitCodes are defined correctly', () {
      expect(ExitCodes.success, equals(0));
      expect(ExitCodes.error, equals(1));
      expect(ExitCodes.issuesFound, equals(1));
      expect(ExitCodes.fileNotFound, equals(2));
      expect(ExitCodes.invalidArguments, equals(3));
    });
  });
}