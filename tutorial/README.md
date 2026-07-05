# SmartPub Tutorial & Guide

SmartPub is a smart dependency analyzer and organizer for Flutter and Dart projects. It helps teams clean up unused packages, fix misplaced or duplicate dependencies, and organize `pubspec.yaml` into commented, neat categories.

This comprehensive guide compiles all instructions and tutorials to help you master using SmartPub.

---

## Table of Contents

1. [Installation & Basic Usage](#installation--basic-usage)
2. [Analyzing Dependencies (`check`)](#analyzing-dependencies-check)
3. [Cleaning and Fixing (`clean`)](#cleaning-and-fixing-clean)
4. [Categorizing and Organizing (`group`)](#categorizing-and-organizing-group)
5. [Persistent Configuration (`smartpub.yaml`)](#persistent-configuration-smartpubyaml)

---

## Installation & Setup

### Step 1: Install Globally

Activate SmartPub globally using Dart's pub tool:

```bash
dart pub global activate smartpub
```

Make sure Dart’s global bin directory is in your system's PATH.

### Step 2: Initialize Configuration

Run the init command inside your project root directory to create the default config:

```bash
smartpub init
```

This creates a pre-configured `smartpub.yaml` containing explanations of all customizable options (ignores, exclusions, checks).

### Step 3: Run Dependency Analysis

To check for dependency violations without modifying any files:

```bash
smartpub
# or explicitly:
smartpub check
```

For help and a list of all available CLI options:
```bash
smartpub --help
```

---

## Analyzing Dependencies (`check`)

The `check` command is the default action of SmartPub. It performs a read-only analysis of your project's `pubspec.yaml` and source directories to detect dependency violations.

### What SmartPub Scans
SmartPub recursively scans the following directories for package imports:
* `lib/` (Core source code)
* `test/` (Test suites)
* `bin/` (CLI Executables)
* `tool/` (Local development/automation scripts)

### Understanding Violations

The CLI categorizes dependencies into four categories:

1. **✅ Used Dependencies**: Dependencies that are correctly declared and imported in their appropriate folders (e.g. `http` in `dependencies` and imported in `lib/`).
2. **⚠️ Unused Dependencies**: Dependencies declared under `dependencies` but never imported in any source file. Removing these keeps build configurations clean and prevents bloat.
3. **🧩 Misplaced Dependencies**:
   * **Over-promoted (Move to dev_dependencies)**: Packages used only in `test/` or `tool/` but declared in regular `dependencies` (inflates app bundle size).
   * **Under-promoted (Move to dependencies)**: Packages used in `lib/` or `bin/` but declared under `dev_dependencies` (causes downstream compilation errors).
4. **🔁 Duplicate Dependencies**: Packages declared in both sections at the same time.
5. **❌ Missing Dependencies**: Packages imported or exported in the source code but not declared in `pubspec.yaml` (these work only because they are transitive dependencies of other packages and can break anytime).

### CI/CD Pipeline Integration & Exit Codes

SmartPub conforms to standard Unix exit codes, making it perfect for blocking PR merges on lint failures:
* **`0` (Success/Clean)**: No violations found.
* **`1` (Violations Found)**: Unused, misplaced, or duplicate dependencies detected.
* **`2` (Tool Error)**: Bad syntax in `smartpub.yaml`, missing `pubspec.yaml`, or internal file errors.
* **`3` (Invalid Arguments)**: Unknown CLI flags/arguments.

#### GitHub Actions Workflow Example
```yaml
name: Dependency Lint
on: [pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      
      - name: Install dependencies
        run: dart pub get
        
      - name: Activate SmartPub
        run: dart pub global activate smartpub
        
      - name: Verify dependencies are organized
        run: smartpub check
```

#### Warn-Only Mode
For large legacy projects, you can output warning logs in CI without failing the build by using:
```bash
smartpub check --no-fail-on-violations
```
This forces SmartPub to exit with `0` even if violations exist.

---

## Cleaning and Fixing (`clean`)

The `clean` command fixes the issues identified during check analysis. It automatically modifies your `pubspec.yaml` to remove unused packages and relocate misplaced dependencies.

### Safety Backups & Restoring
Before writing any changes, SmartPub creates a safety backup of your `pubspec.yaml` named **`pubspec.yaml.bak`**.

If anything goes wrong, restore the backup instantly using:
```bash
smartpub restore
```
This restores the original `pubspec.yaml` and cleans up the backup file.

### Automatic Fixes
To apply all recommended fixes automatically:
```bash
smartpub clean
```
This automatically removes unused dependencies and rearranges misplaced or duplicate dependencies into their correct sections.

### Interactive Fixes
If you prefer to review and approve each modification individually:
```bash
smartpub clean --interactive
```
SmartPub will prompt you for confirmation on each violation, allowing you to selectively apply fixes:
```
🧩 yaml — used in lib. Move to dependencies? [Y/n]
```
Press **`Y`** (or Enter) to accept and apply the recommendation, or **`N`** (or `n`) to skip.

---

## Categorizing and Organizing (`group`)

The `group` command organizes your dependencies in `pubspec.yaml` into commented categories (e.g. state management, API/networking, widgets) powered by FlutterGems.

### Previewing Grouping
To preview how your dependencies will be categorized without modifying the file:
```bash
smartpub group
```

### Applying Grouping
To apply the categories and write them directly into `pubspec.yaml`:
```bash
smartpub group --apply
```

### Interactive Overrides
If you want to customize your categories or assign custom groupings:
```bash
smartpub group --interactive
```
Type `Y` when prompted to start, then hit **Enter** to keep a suggested category or type a new custom category name. Your preferences will be saved to a local **`group-overrides.yaml`** file and will be respected in all future categorization runs.

---

## Persistent Configuration (`smartpub.yaml`)

To ensure that analysis runs consistently for all team members and CI pipelines, you can add a `smartpub.yaml` configuration file to the root of your project.

### Initializing Configuration

To quickly generate a default, fully annotated configuration file, run:

```bash
smartpub init
```

This creates a starter `smartpub.yaml` file in the current directory. If a `smartpub.yaml` already exists, SmartPub will safely warn you and prevent overwriting your existing settings.

### Configuration Schema
```yaml
# smartpub.yaml — place in project root

# 1. Packages to never flag as unused or misplaced
ignore:
  - build_runner
  - flutter_native_splash
  - json_serializable

# 2. Path patterns/directories to exclude from file scanning (using globs)
exclude:
  - "lib/generated/**"
  - "lib/l10n/**"
  - "test/fixtures/**"

# 3. Version constraint quality
allow_pins: false

# 4. Exit non-zero on violations in CI (defaults to true)
fail_on_violations: true

# 5. Fine-tune which checks to run
checks:
  unused: true
  missing: true
  promotions: true
```

### Loading Configuration
By default, running SmartPub will automatically look for `smartpub.yaml` in the root of the project. If you have a custom configuration path, specify it with:
```bash
smartpub check --config configs/smartpub-dev.yaml
```

### CLI Overrides
Any CLI flags passed directly (e.g., `--no-fail-on-violations` or `--apply`) will always override the values declared in your `smartpub.yaml` configuration file.
