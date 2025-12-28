# 📦 SmartPub - Flutter Dependency Analyzer

> **The smart way to manage Flutter dependencies.**

[![pub package](https://img.shields.io/pub/v/smartpub.svg)](https://pub.dev/packages/smartpub)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A cross-platform Dart/Flutter developer tool that analyzes and cleans dependencies in your `pubspec.yaml` file. SmartPub runs on Windows, macOS, and Linux, identifying unused, misplaced, and duplicate dependencies to keep your Flutter projects clean and efficient.

## ✨ Features

- 🔍 **Smart Analysis** - Scans your entire project to detect dependency usage patterns
- 🧹 **Auto-Fix** - Automatically removes unused dependencies and fixes misplaced ones
- 📊 **Package Categorization** - Groups dependencies by categories using FlutterGems data
- 🤝 **Interactive Mode** - Prompts for confirmation before making changes
- 🛡️ **Safety First** - Creates backups before modifications with easy restore
- 📈 **Duplicate Detection** - Finds and resolves duplicate dependencies with version conflicts
- 🎯 **Category Overrides** - Customize package categories with local overrides

## 🌐 Platform Support

SmartPub works with Flutter projects targeting any platform:

- ✅ **Android**
- ✅ **iOS**
- ✅ **Web**
- ✅ **macOS**
- ✅ **Windows**
- ✅ **Linux**

## 🚀 Installation

### Global Installation (Recommended)

```bash
dart pub global activate smartpub
```

### Local Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  smartpub: ^1.0.0
```

Then run:

```bash
dart pub get
```

## 📖 Usage

### Basic Analysis

```bash
# Analyze dependencies without making changes
smartpub --analyse

# Or simply
smartpub
```

### Auto-Fix Mode

```bash
# Automatically fix all issues
smartpub --apply
```

### Interactive Mode

```bash
# Review and apply changes interactively
smartpub --interactive
```

### Restore from Backup

```bash
# Restore previous version
smartpub --restore
```

### Update SmartPub

```bash
# Update to the latest version
smartpub --update
```

### CI-Friendly Mode

```bash
# Disable colors for CI pipelines
smartpub --analyse --no-color
```

## 📋 Command Reference


| Command                   | Description                                 |
| --------------------------- | --------------------------------------------- |
| `smartpub` or `--analyse` | Analyze dependencies without making changes |
| `--interactive`           | Review and apply changes interactively      |
| `--apply`                 | Automatically apply fixes                   |
| `--restore`               | Restore pubspec.yaml from backup            |
| `--update`                | Update SmartPub to the latest version       |
| `--no-color`              | Disable colored output                      |
| `--help`                  | Show help information                       |
| `--version`               | Show version information                    |

### 📊 Package Categorization Commands

| Command                        | Description                                    |
| -------------------------------- | ------------------------------------------------ |
| `--group`                      | Preview dependency grouping by categories      |
| `--group --apply`              | Apply dependency grouping to pubspec.yaml     |
| `--group --interactive`        | Interactive grouping with category overrides  |
| `--update-cache`               | Force update user-level category cache        |
| `--fetch-gems-fallback`        | Enable FlutterGems fallback for missing data  |
| `--use-gems` / `--no-use-gems` | Enable/disable FlutterGems categorization     |

## 📊 Package Categorization

SmartPub can automatically group your dependencies by categories using data from FlutterGems, making your `pubspec.yaml` more organized and easier to navigate.

### 🚀 Quick Start

```bash
# Preview dependency grouping
smartpub --group

# Apply grouping to pubspec.yaml
smartpub --group --apply

# Interactive mode with category overrides
smartpub --group --interactive
```

### 📋 Available Categories

- **State Management** - BLoC, Provider, Riverpod, Redux, MobX
- **Networking** - HTTP clients, API libraries, GraphQL
- **Database** - SQLite, Hive, SharedPreferences, storage solutions
- **UI Components** - Widgets, animations, image handling, charts
- **Navigation** - Routing and navigation libraries
- **Authentication** - Auth providers and security libraries
- **Testing** - Test frameworks, mocking, and testing utilities
- **Development Tools** - Code generation, linting, build tools
- **Utilities** - Helper libraries and common utilities

### 🎯 Category Overrides

Create a `group-overrides.yaml` file to customize package categories:

```yaml
# Package category overrides
# Format: package_name: Category Name

http: Custom Networking
my_package: Custom Category
```

### 📈 Example Output

```yaml
dependencies:
  # State Management
  flutter_bloc: ^8.1.0
  provider: ^6.0.0

  # Networking
  dio: ^5.0.0
  http: ^1.1.0

  # UI Components
  cached_network_image: ^3.2.0
  flutter_svg: ^2.0.0

dev_dependencies:
  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0

  # Development Tools
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

*Package categories courtesy of FlutterGems (used with permission).*

## 🎯 What SmartPub Detects

### ✅ Used Dependencies

Dependencies that are properly used in your `lib/` directory.

### 🧩 Misplaced Dependencies

Dependencies used only in `test/`, `bin/`, or `tool/` that should be in `dev_dependencies`.

### ⚠️ Unused Dependencies

Dependencies declared but never imported in your code.

### 🔄 Duplicate Dependencies

Packages declared in both `dependencies` and `dev_dependencies` with intelligent recommendations.

## 📊 Example Output

```
📦 SmartPub - Flutter Dependency Analyzer

✅ Used Dependencies
✅ http - used in lib
✅ flutter_bloc - used in lib

🧩 Move to dev_dependencies
🧩 mockito - used in test

⚠️ Unused Dependencies
⚠️ lottie - unused

Summary
Total dependencies scanned: 12
⚠️ 2 issue(s) found that can be fixed
```

## 🛡️ Safety Features

- **Automatic Backups** - Creates `pubspec.yaml.bak` before any modifications
- **Easy Restore** - Restore previous version with `--restore` command
- **Error Recovery** - Automatically restores backup if operations fail

## 🔧 CI/CD Integration

Use SmartPub in your CI pipeline across different platforms:

```yaml
# GitHub Actions example (works on ubuntu, windows, macos)
- name: Check dependencies
  run: |
    dart pub global activate smartpub
    smartpub --analyse --no-color
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- 🐛 [Report Issues](https://github.com/VatsalJaganwala/smartpub/issues)
- 💡 [Feature Requests](https://github.com/VatsalJaganwala/smartpub/issues)

---

**Made with ❤️ by [Vatsal Jaganwala](https://github.com/VatsalJaganwala)**
