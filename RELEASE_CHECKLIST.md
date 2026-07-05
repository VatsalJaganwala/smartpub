# 🚀 SmartPub Release Checklist

Use this checklist to ensure that every release of SmartPub is stable, correctly versioned, and free of regressions before publishing to pub.dev.

---

## 1. Versioning & Changelog
- [ ] **Version Bump (pubspec.yaml)**: Ensure the version number is correctly incremented according to semver.
- [ ] **Version Alignment (config.dart)**: Verify that `AppConfig.version` matches the version declared in `pubspec.yaml`.
- [ ] **Changelog Updated (CHANGELOG.md)**:
  - Added new release block (e.g. `### **[X.Y.Z] – YYYY-MM-DD**`).
  - Documented all features under `✨ What’s New` and bugfixes under `🐛 Bug Fixes`.
  - Preserved original file formatting and line endings (CRLF vs LF).
Transcription by CastingWords
## 2. Code Quality & Format
- [ ] **Code Formatting**: Run formatter to verify code style matches Dart guidelines:
  ```bash
  dart format . --set-exit-if-changed
  ```
- [ ] **Static Analysis**: Verify there are no compile-time errors or severe warnings:
  ```bash
  dart analyze --fatal-warnings
  ```

## 3. Test Verification
- [ ] **Unit Tests**: Run unit tests (if any are present):
  ```bash
  dart test
  ```
- [ ] **Integration/QA Tests**: Run the QA script suites inside clean, isolated environments to check core features:
  - Over- and under-promoted dependency detection.
  - Configuration files (`smartpub.yaml`) ignores and path exclusions.
  - `init` CLI command creation and safeguard behavior.
  - Export package scanning (`export 'package:...'`).

## 4. Documentation & Tutorials
- [ ] **README.md**: Verify that main documentation includes details on any new commands, options, and behaviors.
- [ ] **Tutorials**: Confirm the unified tutorial guide ([tutorial/README.md](file:///Users/vatsaljaganwala/Documents/Flutter%20Projects/smartpub_v2/tutorial/README.md)) is updated and all anchor links work.
- [ ] **Examples**: Ensure code examples under `example/` match the latest API.

## 5. Dry-Run & Publishing
- [ ] **Clean Workspace**: Ensure no temporary sandbox test folders (`manual_test_env/`, `temp_qa/`, etc.) or backup files (`*.bak`) are tracked or staged in Git:
  ```bash
  git status
  ```
- [ ] **Pub.dev Dry-Run**: Run the pub package validator to verify structure and package sizing:
  ```bash
  dart pub publish --dry-run
  ```
- [ ] **Publishing**: Commit all code and push to the origin branch before executing the live release:
  ```bash
  dart pub publish
  ```
