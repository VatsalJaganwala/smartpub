# Changelog

All notable changes to SmartPub will be documented in this file.

## [1.0.1] - 2025-10-20

### Changed

- 🔧 **Improved Dev Dependencies Handling** - Dev dependencies are no longer flagged as unused, allowing for more flexible development tooling
- 🎯 **Smarter Dependency Analysis** - Only suggests moving dev dependencies to main dependencies when they're used in `lib/` or `bin/` directories
- 📈 **Better User Experience** - Reduces noise by not flagging legitimate unused dev dependencies (build tools, linters, etc.)


## [1.0.0] - 2025-10-18

### Added

- 🔍 **Smart Dependency Analysis** - Comprehensive scanning of Dart files to detect dependency usage patterns
- 🧹 **Auto-Fix Mode** - Automatically removes unused dependencies and fixes misplaced ones
- 🤝 **Interactive Mode** - Prompts for user confirmation before making changes
- 🛡️ **Safety Backup System** - Creates automatic backups before modifications with easy restore
- 📊 **Duplicate Detection** - Identifies and resolves duplicate dependencies with version conflict detection
- 🌐 **Universal Platform Support** - Works with Flutter projects targeting Android, iOS, Web, macOS, Windows, and Linux

### Stable Release

This is the stable release of SmartPub, providing a complete solution for Flutter/Dart dependency management and cleanup. Works with Flutter projects targeting any platform.
