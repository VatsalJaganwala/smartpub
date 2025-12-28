# SmartPub Library Structure

This document describes the organized structure of the SmartPub library.

## Directory Organization

The `lib/` directory is organized by feature and functionality:

### 📁 `core/`
Contains the fundamental components of SmartPub:
- `analyzer.dart` - Main dependency analysis engine
- `config.dart` - Application configuration and constants
- `models/` - Core data models
  - `dependency_info.dart` - Dependency information model

### 📁 `services/`
Contains business logic services:
- `apply_service.dart` - Handles applying dependency fixes
- `backup_service.dart` - Manages backup and restore operations
- `pubspec_manager.dart` - Handles pubspec.yaml file operations
- `update_checker.dart` - Checks for SmartPub updates

### 📁 `categorization/`
Contains package categorization functionality:
- `gems_integration.dart` - FlutterGems API integration
- `grouping_service.dart` - Dependency grouping logic
- `suggestion_service.dart` - Package suggestion handling
- `models/` - Categorization-specific models (future)

### 📁 `ui/`
Contains user interface components:
- `cli_output.dart` - CLI output formatting and colors
- `interactive_service.dart` - Interactive prompts and user input
- `interactive_grouping_service.dart` - Interactive categorization

### 📁 `telemetry/`
Contains telemetry functionality:
- `telemetry_service.dart` - Anonymous usage statistics collection

## Barrel Files

Each directory includes a barrel file (e.g., `core.dart`, `services.dart`) that exports all public APIs from that module, making imports cleaner:

```dart
// Instead of multiple imports:
import 'package:smartpub/core/analyzer.dart';
import 'package:smartpub/core/config.dart';
import 'package:smartpub/core/models/dependency_info.dart';

// You can use:
import 'package:smartpub/core/core.dart';
```

## Main Library File

The `smartpub.dart` file at the root of `lib/` exports all public APIs, allowing users to import everything with:

```dart
import 'package:smartpub/smartpub.dart';
```

## Benefits of This Structure

1. **Feature-based organization** - Related functionality is grouped together
2. **Clear separation of concerns** - Each directory has a specific purpose
3. **Easier maintenance** - Changes to a feature are contained within its directory
4. **Better discoverability** - Developers can easily find related code
5. **Scalability** - New features can be added as new directories
6. **Clean imports** - Barrel files reduce import complexity

## Import Guidelines

- Use relative imports within the same feature directory
- Use package imports when importing from other feature directories
- Prefer barrel file imports when importing multiple items from a directory
- Keep imports organized and grouped by source (external packages, then internal modules)