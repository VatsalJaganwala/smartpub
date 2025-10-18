# 📦 SmartPub - Flutter Dependency Analyzer

[![pub package](https://img.shields.io/pub/v/smartpub.svg)](https://pub.dev/packages/smartpub)
[![License: BSD-3-Clause](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

A Dart/Flutter developer tool that analyzes and cleans dependencies in your `pubspec.yaml` file. SmartPub identifies unused, misplaced, and duplicate dependencies to keep your Flutter projects clean and efficient.

## ✨ Features

- 🔍 **Smart Analysis** - Scans your entire project to detect dependency usage patterns
- 🧹 **Auto-Fix** - Automatically removes unused dependencies and fixes misplaced ones
- 🤝 **Interactive Mode** - Prompts for confirmation before making changes
- 🛡️ **Safety First** - Creates backups before modifications with easy restore
- 📊 **Duplicate Detection** - Finds and resolves duplicate dependencies with version conflicts

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

### CI-Friendly Mode

```bash
# Disable colors for CI pipelines
smartpub --analyse --no-color
```

## 📋 Command Reference

| Command | Description |
|---------|-------------|
| `smartpub` or `--analyse` | Analyze dependencies without making changes |
| `--interactive` | Review and apply changes interactively |
| `--apply` | Automatically apply fixes |
| `--restore` | Restore pubspec.yaml from backup |
| `--no-color` | Disable colored output |
| `--help` | Show help information |
| `--version` | Show version information |

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

Use SmartPub in your CI pipeline:

```yaml
# GitHub Actions example
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
