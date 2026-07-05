# 📦 SmartPub - Flutter Dependency Analyzer

> **The smart way to manage Flutter dependencies.**


[![pub package](https://img.shields.io/pub/v/smartpub.svg)](https://pub.dev/packages/smartpub)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)



SmartPub is a CLI tool for Flutter & Dart projects that helps you **identify unused dependencies** and **organize your `pubspec.yaml`** in a clean, predictable way.

Over time, Flutter projects often accumulate unused or poorly organized packages. SmartPub makes it easy to **preview**, **clean**, and **categorize** dependencies without risking accidental changes.

---

## 🤔 Why SmartPub?

In real Flutter projects:

* Unused packages increase build time and maintenance cost
* `pubspec.yaml` becomes hard to read as dependencies grow
* Developers hesitate to clean dependencies due to fear of breaking the app

SmartPub solves this by:

* Detecting unused dependencies safely
* Providing **preview-first** workflows
* Offering **interactive modes** before making changes
* Keeping actions explicit and predictable

No magic. No hidden behavior.

---

## ✨ What SmartPub Does

SmartPub focuses on **three core features**:

### 1️⃣ Unused, Misplaced & Missing Dependency Detection

* Scans your project source code (`lib/`, `test/`, `bin/`, `tool/`)
* Detects **unused dependencies** declared in `pubspec.yaml`
* Identifies **misplaced dependencies**:
  * **Over-promoted**: Packages only used in tests/tools but declared under `dependencies`.
  * **Under-promoted**: Packages used in core library files but declared under `dev_dependencies` (which can break downstream consumers).
* Identifies **missing dependencies**: Packages used in code but not declared in `pubspec.yaml`.
* Allows preview before removal or relocation (missing dependency reporting is read-only)
* Supports interactive confirmation for cleanups

### 2️⃣ Dependency Categorization ``` (beta) ```
#### [```Powered by FlutterGems```](https://fluttergems.dev/)

* Groups dependencies into logical categories
* Uses known ecosystem data
* Supports preview, auto-apply, and interactive overrides

### 3️⃣ Persistent Configuration (`smartpub.yaml`)

* Exclude specific directories/files from scanning (using globs like `lib/generated/**`)
* Ignore specific packages from analysis (e.g. code generators like `build_runner`)
* Fine-tune active checking parameters (toggling unused or promotions checks)

---

## 🚀 Installation & Setup

### 1. Install Globally

Activate SmartPub globally using Dart's pub tool:

```bash
dart pub global activate smartpub
```

Make sure Dart’s global bin is added to your system's PATH.

### 2. Initialize Configuration

Initialize the configuration file `smartpub.yaml` in your project root directory:

```bash
smartpub init
```

This generates a starter configuration template with detailed comments to customize rules for your project (ignored packages, path exclusions, etc.).

### 3. Run Analysis

Run SmartPub to preview dependency violations:

```bash
smartpub check
```
*(Or simply run `smartpub` as a shortcut).*

---

## 🧭 Usage Overview

```bash
smartpub [command] [options]
```

If no command is provided, SmartPub runs in **preview mode** (equivalent to `smartpub check`).

---

## 🔍 Commands

### `check` (default)

Preview unused dependencies (read-only).

```bash
smartpub
smartpub check
```

✔ No files are modified.

---

### `clean`

Remove unused dependencies.

```bash
smartpub clean
```

#### Interactive cleanup

Review each removal before applying changes.

```bash
smartpub clean --interactive
```

A backup of `pubspec.yaml` is created automatically.

---

### `group`

Preview dependency categorization.

```bash
smartpub group
```

#### Apply categorization automatically

```bash
smartpub group --apply
```

#### Interactive categorization

Override suggested categories interactively.

```bash
smartpub group --interactive
```

This is useful when you want full control over how packages are grouped.

---

### `init`

Initialize a default, fully documented `smartpub.yaml` configuration file.

```bash
smartpub init
```

* Prevents overwriting if `smartpub.yaml` already exists.

---

### `restore`

Restore `pubspec.yaml` from the last backup.

```bash
smartpub restore
```

---

### `update`

Update SmartPub to the latest version.

```bash
smartpub update
```

---

## ⚙️ Options

```text
--apply                  Apply changes automatically
--interactive            Review and confirm changes interactively
--no-fail-on-violations  Exit 0 even when violations are found (warn-only mode)
--no-color               Disable colored output (CI-friendly)
--config <path>          Path to custom config file (default: smartpub.yaml)
-h, --help               Show help information
-v, --version            Show version information
```

---

## 🏗️ CI Integration & Exit Codes

SmartPub returns standard exit codes so you can use it as a blocking gate in your pipelines (GitHub Actions, GitLab CI, Bitrise).

| Exit Code | Meaning |
|-----------|---------|
| `0` | **Success:** No violations found (or they were successfully cleaned). |
| `1` | **Violations Detected:** Unused or misplaced dependencies found. |
| `2` | **Tool Error:** Missing `pubspec.yaml`, no backup exists, or parse error. |
| `3` | **Invalid Arguments:** Unknown flags or incompatible options passed. |

### Example GitHub Action (Fail on violations)

```yaml
- name: Check for unused dependencies
  run: dart run smartpub check
```

### Example CI Migration (Warn-only mode)
If you want to integrate SmartPub into CI but aren't ready to fail the build yet, use:
```bash
smartpub check --no-fail-on-violations
```
This will print all violations but safely exit `0`.

---

## 🧪 Typical Workflow

A safe and recommended workflow:

```bash
smartpub            # preview unused dependencies
smartpub clean      # remove unused dependencies
smartpub group      # preview categorization
smartpub group --interactive
```

This keeps changes intentional and reviewable.

---

## 🛡️ Safety Guarantees

* SmartPub **never modifies files without intent**
* Preview is the default behavior
* Backups are created before changes
* Interactive mode is available for sensitive operations

---

## 📦 Project Scope (Important)

SmartPub intentionally does **not**:

* Modify versions automatically
* Upgrade or downgrade dependencies
* Guess architectural intent

Its goal is **clarity and cleanliness**, not automation overload.

---

## 📞 Support

- 🐛 [GitHub](https://github.com/VatsalJaganwala/smartpub)
- 🐛 [Report Issues](https://github.com/VatsalJaganwala/smartpub/issues)
- 💡 [Feature Requests](https://github.com/VatsalJaganwala/smartpub/issues)

---

**Made with ❤️ by [Vatsal Jaganwala](https://github.com/VatsalJaganwala)**
