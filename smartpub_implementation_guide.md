# smartpub roadmap to #1

A checklist implementation guide for smartpub.

---

## Phase 1 — critical parity
*Must ship before you can compete with dependency_validator*

### [x] Non-zero exit codes on violations
* **Effort:** XS | **Impact:** critical
* *The single highest-impact change · ~30 minutes to ship*

#### What it is
When smartpub detects violations (unused deps, missing deps, promotion issues), it must exit with a non-zero code — conventionally **exit(1)**. Right now it exits 0 regardless. CI systems like GitHub Actions, GitLab CI, and Bitrise interpret any non-zero exit as a build failure. Without this, smartpub cannot be used as a blocking gate in any pipeline.

#### Implementation
Find your main analysis runner — wherever you collect the final list of violations. Add a single check at the end:

```dart
// In your check/clean command runner
final violations = analyzer.findUnused();

if (violations.isNotEmpty) {
  reporter.printViolations(violations);
  exit(1);  // non-zero = CI fails the build
}

exit(0);  // clean = CI passes
```

> [!TIP]
> Import `dart:io` for `exit()`. Add a `--no-fail-on-violations` flag so teams can run it in warning-only mode during migration. Default must be fail.

#### Exit code conventions
Use **exit(1)** for violations found. Use **exit(2)** for tool errors (bad config, missing pubspec.yaml, parse failure). Use **exit(0)** for clean. This matches the convention used by `dart analyze`, `dependency_validator`, and most Unix CLI tools.

#### Edge cases
* The `check` command should `exit(1)` when violations exist, even if no changes are made
* The `clean` command should `exit(0)` after successfully removing violations (they were fixed)
* The `group` command with `--apply` should `exit(0)` on success, `exit(1)` if it couldn't apply
* The `restore` command should `exit(0)` on success, `exit(2)` if no backup exists

---

### [x] smartpub.yaml config file
* **Effort:** S | **Impact:** critical
* *Persistent exclusions and team-shareable settings*

#### What it is
A YAML file at the project root that lets teams persist their configuration. Without this, every developer and every CI job must re-pass the same flags on every run. Teams need to be able to commit this file to git and have it work consistently everywhere.

#### Schema design
```yaml
# smartpub.yaml — place in project root

# Packages to never flag as unused
ignore:
  - build_runner     # code generator, no direct imports
  - flutter_native_splash

# Directories to skip when scanning imports
exclude:
  - "lib/generated/**"
  - "lib/l10n/**"

# Allow ==1.2.3 pinned versions without warning
allow_pins: false

# Exit non-zero on violations (default: true)
fail_on_violations: true

# Which checks to run
checks:
  unused: true
  missing: true
  promotions: true
```

#### Implementation
Use the **checked_yaml** + **json_annotation** packages (already used by `dependency_validator`) to parse and validate the config with typed models and helpful error messages on bad values.

```dart
import 'package:checked_yaml/checked_yaml.dart';

@JsonSerializable()
class SmartpubConfig {
  final List<String> ignore;
  final List<String> exclude;
  final bool allowPins;
  final bool failOnViolations;

  const SmartpubConfig({
    this.ignore = const [],
    this.exclude = const [],
    this.allowPins = false,
    this.failOnViolations = true,
  });
}

// Load from file, fall back to defaults
SmartpubConfig loadConfig(String projectPath) {
  final file = File('$projectPath/smartpub.yaml');
  if (!file.existsSync()) return const SmartpubConfig();
  return checkedYamlDecode(file.readAsStringSync(),
    (m) => SmartpubConfig.fromJson(m!));
}
```

#### Edge cases
* Config not found → silently use defaults, do not error
* Bad YAML syntax → print a clear error with line number, `exit(2)`
* Unknown keys → warn but do not error (forward compatibility)
* CLI flags always override config file values
* Support `--config path/to/other.yaml` to specify non-default config location

---

### [x] Missing dependency detection
* **Effort:** M | **Impact:** critical
* *Find packages used in code but not declared in pubspec.yaml*

#### What it is
Scan every **.dart** file for `import 'package:X/...'` and `export 'package:X/...'` statements. Collect the set of unique package names **X**. Then cross-reference against `pubspec.yaml`'s declared dependencies. Any package imported in code but not declared in pubspec is a missing dependency — it works today only because it's a transitive dep of something else, and will silently break if that intermediate package changes.

#### Implementation algorithm
```dart
// Step 1: collect declared packages from pubspec.yaml
final declared = {
  ...pubspec.dependencies.keys,
  ...pubspec.devDependencies.keys,
};

// Step 2: scan all .dart files for package: imports
final imported = <String>{};
final importRe = RegExp(r"import\s+['\"]package:([^/]+)/");
final exportRe = RegExp(r"export\s+['\"]package:([^/]+)/");

for (final file in dartFiles) {
  final content = file.readAsStringSync();
  importRe.allMatches(content)
    .forEach((m) => imported.add(m.group(1)!));
  exportRe.allMatches(content)
    .forEach((m) => imported.add(m.group(1)!));
}

// Step 3: find missing = imported but not declared
final packageName = pubspec.name; // exclude self-imports
final sdkPackages = {'dart', 'flutter'}; // not in pubspec

final missing = imported
  .where((p) => !declared.contains(p))
  .where((p) => p != packageName)
  .where((p) => !sdkPackages.contains(p))
  .toList();
```

#### False positive cases to handle
* `flutter` and `dart` are SDK packages — never flag them as missing
* The project's own package name (self-imports) — exclude it
* Packages that declare executables or builders don't need to be imported — don't require them to appear in code
* Conditional imports (`// ignore: depend_on_referenced_packages`) — respect ignore comments
* Generated files (`*.g.dart`, `*.freezed.dart`) — configure exclusion in `smartpub.yaml`

> [!WARNING]
> Missing dep detection is read-only — it should never auto-fix. The user must manually add the dep to `pubspec.yaml`. Auto-adding would choose the wrong version range.

---

### [x] Over- and under-promoted detection
* **Effort:** M | **Impact:** critical
* *Flag deps in the wrong section of pubspec.yaml*

#### What it is
* **Under-promoted:** Package used inside `lib/` but declared only as `dev_dependency`. This is a bug — when other packages depend on yours, they won't get this transitive dep and the code will fail to compile.
* **Over-promoted:** Package only used outside `lib/` (in `test/`, `tool/`, `bin/`) but declared as a regular `dependency`. This inflates app bundle size for consumers.

#### Implementation
```dart
// Categorise each dart file by location
enum FileScope { lib, nonLib }

FileScope scopeOf(String filePath) =>
  filePath.contains('/lib/') ? FileScope.lib : FileScope.nonLib;

// Build: package → set of scopes that import it
final usedInLib = <String>{};
final usedOutsideLib = <String>{};

for (final file in dartFiles) {
  final scope = scopeOf(file.path);
  final pkgs = extractImportedPackages(file);
  if (scope == FileScope.lib) {
    usedInLib.addAll(pkgs);
  } else {
    usedOutsideLib.addAll(pkgs);
  }
}

// Under-promoted: in lib, but only a dev_dep
final underPromoted = pubspec.devDependencies.keys
  .where((p) => usedInLib.contains(p))
  .toList();

// Over-promoted: not in lib, but a regular dep
final overPromoted = pubspec.dependencies.keys
  .where((p) => !usedInLib.contains(p))
  .where((p) => usedOutsideLib.contains(p))
  .toList();
```

#### Reporting
Show clear, actionable output for each violation:
```
Under-promoted — move to dependencies:
  mocktail   used in lib/services/auth_service.dart
             but declared as dev_dependency

Over-promoted — move to dev_dependencies:
  build_runner  only used in test/ and tool/
               declared as dependency (inflates bundle)
```

#### Edge cases
* `flutter_test`, `build`, `build_runner` are expected as `dev_dependencies` — pre-whitelist them
* Packages with builders (auto-applied) count as used even without imports
* A package used in BOTH `lib/` and `test/` is correctly promoted as a regular dependency
* `flutter_lints`, `analysis_options.yaml` references — not detectable by import scanning, ignore them

---

## Phase 2 — moat features
*No competitor offers these — this is how you win*

### [ ] Monorepo / Pub Workspace support
* **Effort:** M | **Impact:** high
* *-C flag + workspace traversal*

#### What it is
Dart's official workspace feature allows multiple packages in one repo to share a resolved dependency tree. smartpub needs a **-C <path>** flag (run on a sub-package) and automatic workspace detection (run on root = analyse all packages). Without this, any project using Flutter monorepo patterns cannot use smartpub at all.

#### Implementation
```dart
// 1. Add -C / --directory flag to all commands
final parser = ArgParser()
  ..addOption('directory', abbr: 'C',
     help: 'Run in this subdirectory');

// 2. Detect workspace at root pubspec.yaml
bool isWorkspaceRoot(String path) {
  final pubspec = loadPubspec(path);
  return pubspec.containsKey('workspace');
}

// 3. Traverse all workspace members
List<String> getWorkspacePackages(String rootPath) {
  final pubspec = loadPubspec(rootPath);
  final members = pubspec['workspace'] as List;
  return members
    .map((m) => '$rootPath/$m')
    .toList();
}

// 4. Run analysis on each, aggregate results
for (final pkg in getWorkspacePackages(root)) {
  final results = analyzePackage(pkg);
  printPackageHeader(pkg);
  printResults(results);
  if (results.hasViolations) overallExitCode = 1;
}
```

> [!TIP]
> Match `dependency_validator`'s exact `-C` behaviour: running on the workspace root analyses root + all members. Running with `-C` on a sub-package analyses only that package.

---

### [ ] Dependency health scoring
* **Effort:** L | **Impact:** high
* *Live pub.dev API checks — discontinued, deprecated, abandoned*

#### What it is
Query `pub.dev`'s public REST API for each dependency at runtime. Check: is the package discontinued? deprecated? Was its last publish more than 18 months ago? Is its pub points score below 60? This turns smartpub into a continuous health monitor — no competitor does this today.

#### pub.dev API endpoints
```http
// Package metadata
GET https://pub.dev/api/packages/{package}

// Response contains:
{
  "latest": {
    "pubspec": { "version": "2.1.0" }
  },
  "isDiscontinued": false,
  "replacedBy": null   // if discontinued, points here
}

// Package score (pub points, likes, popularity)
GET https://pub.dev/api/packages/{package}/score

// Response contains:
{
  "grantedPoints": 110,
  "maxPoints": 160,
  "popularityScore": 0.94,
  "likeCount": 283
}
```

#### Implementation
```dart
Future<PackageHealth> checkHealth(String package) async {
  final meta = await http.get(
    Uri.parse('https://pub.dev/api/packages/$package'));
  final score = await http.get(
    Uri.parse('https://pub.dev/api/packages/$package/score'));

  final metaJson = jsonDecode(meta.body);
  final scoreJson = jsonDecode(score.body);

  final lastPublish = DateTime.parse(
    metaJson['latest']['published']);
  final monthsSince =
    DateTime.now().difference(lastPublish).inDays ~/ 30;

  return PackageHealth(
    isDiscontinued: metaJson['isDiscontinued'] ?? false,
    replacedBy: metaJson['replacedBy'],
    monthsSinceUpdate: monthsSince,
    pubPoints: scoreJson['grantedPoints'],
    isAbandoned: monthsSince > 18,
  );
}

// Batch requests with Future.wait for speed
final healths = await Future.wait(
  packages.map((p) => checkHealth(p)));
```

#### Edge cases
* Rate limit `pub.dev` requests — batch with small delays, cache results locally in `~/.smartpub/cache/`
* Offline mode: if no internet, skip health checks silently with a notice
* Flutter SDK packages (`flutter`, `flutter_test`) never hit the API
* Private/path/git dependencies — skip API check, warn they can't be scored
* Add `--no-health` flag to skip this check entirely for fast offline runs

---

### [ ] Version constraint quality analysis
* **Effort:** M | **Impact:** medium
* *Flag pins, over-tight ranges, stale upper bounds*

#### What it is
Analyse each version constraint in `pubspec.yaml` for quality issues. A **pin** (`==1.2.3`) blocks all upgrades. A wildcard (`any`) is a security risk. A **stale upper bound** (`<2.0.0` when 3.0.0 is released) causes resolution failures. The `pub.dev` API can tell you the latest version so you can compare.

#### Constraint patterns to detect
```dart
// Use pub_semver package (already in your deps)
import 'package:pub_semver/pub_semver.dart';

enum ConstraintIssue { pinned, wildcard, staleUpperBound, tooTight }

ConstraintIssue? analyzeConstraint(
  String constraint, Version latestVersion) {

  if (constraint == 'any') return ConstraintIssue.wildcard;

  final vc = VersionConstraint.parse(constraint);

  // Pin: ==1.2.3 (VersionConstraint.any is range, Version is exact)
  if (vc is Version) return ConstraintIssue.pinned;

  if (vc is VersionRange) {
    // Stale upper: <2.0.0 but latest is 3.x
    if (vc.max != null && !vc.allows(latestVersion)) {
      return ConstraintIssue.staleUpperBound;
    }
  }
  return null; // constraint is healthy
}
```

> [!TIP]
> Suggest a `^`-style caret range when you find a pin or stale bound. E.g. "consider `^2.1.0` instead of `==2.1.0`" — actionable, not just a complaint.

---

### [ ] License compliance scanning
* **Effort:** M | **Impact:** high
* *Flag GPL/AGPL deps incompatible with app store distribution*

#### What it is
Fetch the SPDX license identifier for each dependency from `pub.dev` and classify it. GPL-2.0, GPL-3.0, and AGPL-3.0 are copyleft licenses that require distributing source code — incompatible with most commercial app distributions. No other Dart/Flutter tool scans for this. Hugely valuable for enterprise teams and agencies.

#### Implementation
```dart
// Fetch license from pub.dev API
// GET https://pub.dev/api/packages/{package}
// response['latest']['pubspec']['license'] = 'MIT'

const copyleftLicenses = {
  'GPL-2.0', 'GPL-2.0-only', 'GPL-2.0-or-later',
  'GPL-3.0', 'GPL-3.0-only', 'GPL-3.0-or-later',
  'AGPL-3.0', 'AGPL-3.0-only',
  'LGPL-2.1', 'LGPL-3.0',   // warn (not block)
};

const permissiveLicenses = {
  'MIT', 'BSD-2-Clause', 'BSD-3-Clause',
  'Apache-2.0', 'ISC', 'MPL-2.0',
};

// In smartpub.yaml: allow user to configure
// licenses:
//   deny: [GPL-3.0, AGPL-3.0]
//   warn: [LGPL-2.1]
```

#### Output format
```
License scan results:
  http          BSD-3-Clause  OK
  path          BSD-3-Clause  OK
  some_package  GPL-3.0       BLOCKED — copyleft, incompatible with
                              commercial app distribution
  other_pkg     unknown       WARN — no license declared on pub.dev
```

---

### [ ] Transitive dependency visibility
* **Effort:** M | **Impact:** medium
* *Show which declared deps are actually undeclared transitive imports*

#### What it is
Read **.dart_tool/package_config.json** (generated by `pub get`) to get the full resolved dependency graph including transitives. Cross-reference with what you actually import in code. If your code imports package `X` but `X` is only in the resolved graph as a transitive dep of `Y`, flag it — you're relying on an undeclared dep that could break silently.

#### Implementation
```dart
// Read resolved dep graph
final config = jsonDecode(
  File('.dart_tool/package_config.json').readAsStringSync());

final allResolved = (config['packages'] as List)
  .map((p) => p['name'] as String)
  .toSet();

// Packages you import but didn't explicitly declare
final undeclaredTransitives = importedPackages
  .where((p) => allResolved.contains(p))  // resolved (not missing)
  .where((p) => !declared.contains(p))    // but not declared
  .toList();
```

> [!WARNING]
> Require `.dart_tool/package_config.json` to exist (i.e. `pub get` has been run). Exit with a helpful message if it's missing — do not guess.

---

## Phase 3 — ecosystem integration
*Adoption multipliers — lower the activation energy for every developer*

### [ ] GitHub Actions marketplace action
* **Effort:** S | **Impact:** high
* *3-line CI integration — uncontested distribution channel*

#### What it is
A dedicated GitHub Actions action published to the Marketplace under `smartpub/smartpub-action`. Lets any Flutter team add smartpub CI checks with 3 lines of YAML. `dependency_validator` has no official action — this distribution channel is completely uncontested.

#### action.yml
```yaml
name: 'smartpub'
description: 'Analyse Flutter/Dart dependencies'
inputs:
  working-directory:
    description: 'Project directory'
    default: '.'
  fail-on-violations:
    description: 'Fail the build on violations'
    default: 'true'
runs:
  using: 'composite'
  steps:
    - run: dart pub global activate smartpub
      shell: bash
    - run: smartpub check --no-color
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

#### User-facing usage (what teams add to their workflow)
```yaml
- name: Check dependencies
  uses: smartpub/smartpub-action@v1
```

> [!TIP]
> Create a separate repository named `smartpub-action`. Tag `v1`, `v1.0`, `v1.0.0` — GitHub Actions users expect major-version tags that float. Publish to the GitHub Marketplace (free, takes ~5 minutes).

---

### [ ] SARIF output format
* **Effort:** M | **Impact:** medium
* *Violations appear as inline PR annotations in GitHub*

#### What it is
SARIF (Static Analysis Results Interchange Format) is the JSON standard used by GitHub Code Scanning, VS Code Problems panel, and Azure DevOps. When you emit SARIF and upload it in CI, GitHub shows violations as inline annotations directly on the changed files in a PR — no one has to read log output.

#### SARIF structure for smartpub violations
```json
{
  "version": "2.1.0",
  "runs": [{
    "tool": {
      "driver": {
        "name": "smartpub",
        "rules": [
          { "id": "SP001", "name": "UnusedDependency" },
          { "id": "SP002", "name": "MissingDependency" },
          { "id": "SP003", "name": "UnderPromoted" },
          { "id": "SP004", "name": "OverPromoted" }
        ]
      }
    },
    "results": [{
      "ruleId": "SP001",
      "message": { "text": "'dio' is declared but not imported" },
      "locations": [{
        "physicalLocation": {
          "artifactLocation": { "uri": "pubspec.yaml" }
        }
      }]
    }]
  }]
}
```

#### CI upload snippet (add to GitHub Action)
```yaml
- run: smartpub check --format=sarif --output=results.sarif
- uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: results.sarif
```

---

### [ ] Programmatic Dart API
* **Effort:** M | **Impact:** medium
* *Export analyser as a typed Dart library*

#### What it is
Export a clean public API so other tools, scripts, and IDEs can invoke smartpub's analysis without shelling out. Keeps your CLI as a thin wrapper over the library layer. Enables VS Code extensions, custom build scripts, and programmatic integration in larger toolchains.

#### Public API design
```dart
// lib/smartpub.dart — public exports only
export 'src/analyzer.dart';
export 'src/models.dart';
export 'src/config.dart';

// Usage from another package:
import 'package:smartpub/smartpub.dart';

final analyzer = DependencyAnalyzer(
  projectPath: '/path/to/project',
  config: SmartpubConfig(ignore: ['build_runner']),
);

final result = await analyzer.analyze();

result.unused         // List<String>
result.missing        // List<String>
result.underPromoted  // List<String>
result.overPromoted   // List<String>
result.hasViolations  // bool
```

> [!TIP]
> Keep your CLI in `bin/` as a thin `main()` that calls the library. All business logic lives in `lib/src/`. This separation costs nothing to implement now and enables everything in Phase 3 and 4.

---

## Phase 4 — trust infrastructure
*Cannot be shortcut — takes time, consistency, and visibility*

### [ ] Register a verified publisher domain
* **Effort:** XS | **Impact:** high
* *10 minutes — biggest non-code trust signal on pub.dev*

#### How to do it
Go to **pub.dev/publishers/create**. Enter a domain you control (even a personal one like `yourname.dev` — it does not need to be a company). Verify via a DNS TXT record. Once verified, transfer smartpub to that publisher. The verified badge appears immediately on the package page. This alone removes the single most visible trust barrier for enterprise developers evaluating the package.

> [!NOTE]
> You don't need a company domain. `yourname.dev`, `yourname.com`, or any domain you own works. The badge signals you're accountable — not that you work for a corporation.

---

### [ ] Test suite with coverage
* **Effort:** L | **Impact:** high
* *A dep analyser must prove its own analysis is correct*

#### Testing strategy
Create a `test/fixtures/` directory with small synthetic Flutter projects — each one designed to test a specific scenario. Write integration tests that run smartpub against each fixture and assert on the output.

#### Fixture structure
```
test/
  fixtures/
    unused_dep/        # has 'dio' in pubspec, never imported
      pubspec.yaml
      lib/main.dart
    missing_dep/       # imports 'http' but not in pubspec
      pubspec.yaml
      lib/main.dart
    under_promoted/    # uses 'mocktail' in lib/, declared as dev
      pubspec.yaml
      lib/service.dart
    clean_project/     # no violations — must exit 0
      pubspec.yaml
      lib/main.dart
  analyzer_test.dart
  config_test.dart
  exit_code_test.dart
```

#### CI coverage setup
```yaml
# .github/workflows/ci.yml
- name: Run tests with coverage
  run: |
    dart test --coverage=coverage
    dart pub global activate coverage
    dart pub global run coverage:format_coverage \
      --lcov --in=coverage --out=coverage/lcov.info \
      --report-on=lib
- uses: codecov/codecov-action@v4
  with:
    files: coverage/lcov.info
```

> [!TIP]
> Aim for 85%+ coverage on `lib/src/`. The fixture-based integration tests give you high confidence at low maintenance cost — one fixture per known false-positive edge case.

---

### [ ] Release cadence + CHANGELOG discipline
* **Effort:** ongoing | **Impact:** high
* *Monthly releases signal the project is alive*

#### What to do
Set a personal rule: at minimum one `pub.dev` release per month, even if it's only a patch. Add a GitHub Actions workflow that runs on every push to main and automatically checks that the CHANGELOG has been updated. Keep a **CHANGELOG.md** in the format below — it is read by developers evaluating whether the project is active, and by `pub.dev`'s scoring system.

#### CHANGELOG.md format
```markdown
## 1.1.0 - 2025-04-10
### Added
- Missing dependency detection (SP002)
- Non-zero exit codes on violations
- smartpub.yaml config file support

### Fixed
- False positive on flutter_test in lib/ (#12)

### Changed
- check command now exits 1 when violations found
```

#### Automated release workflow
```yaml
# .github/workflows/publish.yml
on:
  push:
    tags: ['v*']
jobs:
  publish:
    steps:
      - uses: dart-lang/setup-dart@v1
      - run: dart pub publish --force
```

> [!WARNING]
> `assets_cleaner` died because it went 13 months without a release. Consistency matters more than frequency — even a one-line bugfix released monthly is enough to show the project is alive.
