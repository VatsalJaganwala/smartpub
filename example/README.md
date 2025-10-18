# SmartPub Examples

> **The smart way to manage Flutter dependencies.**

This directory contains examples of how to use SmartPub in different scenarios.

## Basic Usage

### 1. Analyze Dependencies

```bash
# Basic analysis
smartpub --analyse

# Or simply
smartpub
```

### 2. Auto-Fix Issues

```bash
# Automatically fix all detected issues
smartpub --apply
```

### 3. Interactive Mode

```bash
# Review and apply changes interactively
smartpub --interactive
```

### 4. Restore from Backup

```bash
# Restore previous version
smartpub --restore
```

## Example Scenarios

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
smartpub --apply
```

**After:**
```yaml
dependencies:
  http: ^1.1.0
  flutter_bloc: ^8.0.0

dev_dependencies:
  test: ^1.24.9
```

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
smartpub --apply
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
smartpub --apply
```

**After:**
```yaml
dependencies:
  yaml: ^3.1.2      # Kept the version from dependencies
  http: ^1.1.0

dev_dependencies:
  test: ^1.24.9
```

## CI/CD Integration

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
        run: smartpub --analyse --no-color
```

### GitLab CI

```yaml
check_dependencies:
  stage: test
  image: dart:stable
  script:
    - dart pub global activate smartpub
    - smartpub --analyse --no-color
  only:
    - merge_requests
    - main
```

## Complex Dependencies

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