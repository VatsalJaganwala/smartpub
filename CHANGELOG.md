# 📄 Changelog
---

## [1.0.2] – 2025-02-08

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

## [1.1.0] – 2025-12-07

### ✨ What’s New

* **Dependency categorization** to organize `pubspec.yaml` by logical categories
* **Interactive grouping mode** to override suggested categories
* Support for **local category overrides** via `group-overrides.yaml`
* Automatic backup before applying grouping changes

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

### Notes

* SmartPub always defaults to **preview mode** before making changes
* Backups are created automatically for safe cleanup and grouping

---

## ✅ Why this version is better

* ❌ No internal filenames, APIs, or architecture details
* ❌ No implementation trivia
* ✅ Clear impact for users
* ✅ Easy to skim
* ✅ Matches your new **user-friendly CLI philosophy**

If you want, I can also:

* Split this into **Keep a Changelog–compliant** format
* Add **upgrade notes** between breaking versions
* Align this perfectly with **pub.dev best practices**

You’re making the right call here — clarity beats completeness every time 👌
