# Package Categorization Example

This example demonstrates how to use SmartPub's package categorization feature to organize your dependencies.

## Sample pubspec.yaml (Before)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_bloc: ^8.1.0
  cached_network_image: ^3.2.0
  sqflite: ^2.3.0
  shared_preferences: ^2.2.0
  provider: ^6.0.0
  dio: ^5.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  flutter_lints: ^3.0.0
```

## Commands

### Preview Grouping
```bash
smartpub --group
```

### Apply Grouping
```bash
smartpub --group --apply
```

### Interactive Mode
```bash
smartpub --group --interactive
```

## Result (After Grouping)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.0
  provider: ^6.0.0

  # Networking
  dio: ^5.3.0
  http: ^1.1.0

  # Database
  shared_preferences: ^2.2.0
  sqflite: ^2.3.0

  # UI Components
  cached_network_image: ^3.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Testing
  mockito: ^5.4.0

  # Development Tools
  build_runner: ^2.4.0
  flutter_lints: ^3.0.0
  json_serializable: ^6.7.0
```

## Category Overrides

Create `group-overrides.yaml` to customize categories:

```yaml
# Package category overrides
# Format: package_name: Category Name

dio: Custom HTTP Client
shared_preferences: Local Storage
```

## Benefits

- **Better Organization**: Dependencies are logically grouped
- **Easier Navigation**: Find packages by category
- **Team Consistency**: Standardized organization across projects
- **Documentation**: Category headers serve as inline documentation