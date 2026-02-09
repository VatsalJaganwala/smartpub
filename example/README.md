# SmartPub Examples

> **The smart way to manage Flutter dependencies.**

This directory contains examples of how to use SmartPub in different scenarios.

---

## 🚀 Quick Start

### 1. Check for Unused Dependencies (Preview)

```bash
# Preview unused dependencies (default command)
smartpub
smartpub check
```

✔ No files are modified.

### 2. Clean Up Unused Dependencies

```bash
# Remove unused dependencies
smartpub clean

# Interactive cleanup (review each change)
smartpub clean --interactive
```

### 3. Organize Dependencies by Category

```bash
# Preview categorization
smartpub group

# Apply categorization automatically
smartpub group --apply

# Interactive categorization (override suggestions)
smartpub group --interactive
```

### 4. Restore from Backup

```bash
# Restore previous version
smartpub restore
```

### 5. Update SmartPub

```bash
# Update to latest version
smartpub update
```

---

## 📋 Example Scenarios

### Scenario 1: Clean Up Unused Dependencies

**Before:**
```yaml
dependencies:
  http: ^1.1.0      # Used in lib/
  dio: ^5.0.0       # Not used anywhere
  flutter_bloc: ^8.0.0  # Used in lib/
  lottie: ^2.0.0    # Not used anywhere

dev_dependencies:
  test: ^1.24.9
  mockito: ^5.4.4   # Not used anywhere
```

**Command:**
```bash
smartpub clean
```

**After:**
```yaml
dependencies:
  http: ^1.1.0
  flutter_bloc: ^8.0.0

dev_dependencies:
  test: ^1.24.9
```

---

### Scenario 2: Fix Misplaced Dependencies

**Before:**
```yaml
dependencies:
  http: ^1.1.0      # Used in lib/
  mockito: ^5.4.4   # Only used in test/
  build_runner: ^2.4.7  # Only used for code generation

dev_dependencies:
  test: ^1.24.9
```

**Command:**
```bash
smartpub clean
```

**After:**
```yaml
dependencies:
  http: ^1.1.0

dev_dependencies:
  test: ^1.24.9
  mockito: ^5.4.4
  build_runner: ^2.4.7
```

---

### Scenario 3: Resolve Duplicate Dependencies

**Before:**
```yaml
dependencies:
  yaml: ^3.1.2      # Used in lib/
  http: ^1.1.0

dev_dependencies:
  test: ^1.24.9
  yaml: ^3.1.0      # Duplicate with different version
```

**Command:**
```bash
smartpub clean
```

**After:**
```yaml
dependencies:
  yaml: ^3.1.2      # Kept the version from dependencies
  http: ^1.1.0

dev_dependencies:
  test: ^1.24.9
```

---

### Scenario 4: Organize Dependencies by Category

**Before:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.0.0
  shared_preferences: ^2.2.0
  flutter_svg: ^2.0.0
  intl: ^0.18.0
  dio: ^5.0.0
```

**Command:**
```bash
smartpub group --apply
```

**After:**
```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.0.0

  # Networking
  http: ^1.1.0
  dio: ^5.0.0

  # Storage
  shared_preferences: ^2.2.0

  # UI Components
  flutter_svg: ^2.0.0

  # Localization
  intl: ^0.18.0
```

---

## 🔄 Typical Workflow

A safe and recommended workflow:

```bash
# Step 1: Preview unused dependencies
smartpub

# Step 2: Remove unused dependencies
smartpub clean

# Step 3: Preview categorization
smartpub group

# Step 4: Apply categorization with interactive mode
smartpub group --interactive
```

This keeps changes intentional and reviewable.

---

## 🤖 CI/CD Integration

### GitHub Actions

```yaml
name: Dependency Check
on: [push, pull_request]

jobs:
  check-dependencies:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      
      - name: Install SmartPub
        run: dart pub global activate smartpub
        
      - name: Check dependencies
        run: smartpub check --no-color
```

### GitLab CI

```yaml
check_dependencies:
  stage: test
  image: dart:stable
  script:
    - dart pub global activate smartpub
    - smartpub check --no-color
  only:
    - merge_requests
    - main
```

---

## 🎯 Interactive Mode Examples

### Interactive Cleanup

```bash
smartpub clean --interactive
```

**Output:**
```
📦 SmartPub - Dependency Analyzer

✓ Analysis complete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Summary:
  • Total dependencies: 8
  • Unused: 2
  • Misplaced: 1
  • Duplicates: 0

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remove 'dio' (unused)? (y/n): y
Remove 'lottie' (unused)? (y/n): y
Move 'mockito' to dev_dependencies? (y/n): y

✓ Changes applied successfully
```

### Interactive Categorization

```bash
smartpub group --interactive
```

**Output:**
```
📦 Package: http
Suggested category: Networking
Keep this category? (y/n): y

📦 Package: provider
Suggested category: State Management
Keep this category? (y/n): y

📦 Package: custom_package
Suggested category: Utilities
Keep this category? (y/n): n
Enter custom category: Custom Logic

✓ Categorization complete
```

---

## 🛠️ Complex Dependencies

SmartPub handles all types of dependencies:

```yaml
dependencies:
  # Simple version constraint
  http: ^1.1.0
  
  # Git dependency
  my_package:
    git:
      url: https://github.com/user/repo.git
      ref: main
  
  # Path dependency
  local_package:
    path: ../local_package
    
  # Git with path
  sub_package:
    git:
      url: https://github.com/user/mono_repo.git
      path: packages/sub_package
      ref: v1.0.0

dev_dependencies:
  # Development tools
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

All of these will be properly analyzed and maintained by SmartPub while preserving their exact structure and formatting.

---

## 🎨 Category Override Example

Create a `group-overrides.yaml` file in your project root:

```yaml
# Custom category overrides
my_custom_package: Custom Logic
internal_utils: Internal Tools
company_sdk: Company SDKs
```

Then run:

```bash
smartpub group --apply
```

Your custom categories will be used instead of the suggested ones.

---

## 📞 Need Help?

- 🐛 [Report Issues](https://github.com/VatsalJaganwala/smartpub/issues)
- 💡 [Feature Requests](https://github.com/VatsalJaganwala/smartpub/issues)
- 📖 [Full Documentation](https://github.com/VatsalJaganwala/smartpub)

---

**Made with ❤️ by [Vatsal Jaganwala](https://github.com/VatsalJaganwala)**
