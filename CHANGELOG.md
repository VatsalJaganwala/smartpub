# 📄 Changelog
---

## [1.0.3] – 2026-02-09

### 🐛 Bug Fixes

* Fixed "Category not found" error causing app crashes when API returns error responses
* Improved null safety across all JSON parsing operations
* Enhanced error handling to gracefully handle malformed API responses and missing data fields

### 🔄 Improvements

* Better resilience when categorization API is unavailable or returns unexpected data
* Application continues execution with safe defaults instead of crashing on data errors

---

## [1.0.2] – 2026-02-08

### ✨ What’s New

* New **simplified CLI commands**: `check`, `clean`, `group`, `restore`, `update`
* **Preview-first workflows** for both unused dependency detection and categorization
* **Interactive categorization** with clearer prompts and progress indicators
* Visual confirmation when keeping suggested categories during interactive grouping

### 🔄 What Changed

* `check` is now the **default command** when no arguments are provided
* Categorization is faster and more reliable with automatic caching
* Help output is clearer and easier to understand for new users


### 🚀 Improvements

* Faster categorization performance
* Clearer error messages for invalid command usage
* Safer workflows with restore guidance after changes

---

## [1.0.1] – 2025-10-20

### 🔄 Improvements

* Dev dependencies are no longer incorrectly flagged as unused
* Smarter detection of when dependencies should move between sections
* Reduced false positives for build tools and linters

---

## [1.0.0] – 2025-10-18

### 🎉 Initial Release

* Detect unused dependencies in Flutter and Dart projects
* Automatically remove unused and misplaced dependencies
* Interactive cleanup mode with confirmations
* Automatic backup and restore support
* Works across all Flutter platforms

---
