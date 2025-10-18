# 📦 SmartPub — Flutter Dependency Analyzer

### Project Requirements Document

---

## 📊 Project Status

**Current Phase:** Phase 2 - Intelligent Operations (Complete!)
**Overall Progress:** 85% Complete

### ✅ Completed Features

- ✅ Smart Context-Based Dependency Detection
- ✅ Colored & Structured CLI Output
- ✅ Analysis Mode (`--analyse`)
- ✅ Safety Backup System
- ✅ Restore Functionality (`--restore`)
- ✅ CLI Framework with proper argument parsing
- ✅ Configuration system
- ✅ Cross-platform path handling

### ✅ Recently Completed

- ✅ Auto-Apply Mode (`--apply`)
- ✅ Interactive Mode (`--interactive`)
- ✅ Multi-line dependency support (path, git dependencies)
- ✅ Duplicate dependency detection
- ✅ Safety backup system
- ✅ Restore functionality (`--restore`)

### 🚧 In Progress

- 🚧 Functional grouping (`--organize`)

### ⏳ Planned

- ⏳ Functional grouping (`--organize`)
- ⏳ CI/CD friendly mode

---

## 🧭 Overview

**SmartPub** is a Dart/Flutter developer tool designed to analyze, clean, and organize dependencies in a Flutter project’s `pubspec.yaml` file.

It identifies **unused**, **misplaced**, and **duplicate** dependencies, and allows developers to **fix** or **reorganize** them safely using powerful CLI commands.

This tool aims to simplify dependency maintenance and keep Flutter projects clean, efficient, and production-ready.

---

## 🧩 Core Objectives

- Detect unused or misplaced dependencies.
- Safely remove or move dependencies with user approval.
- Support auto-fix and dry-run modes for CI/CD automation.
- Organize dependencies into functional groups (widgets, API, etc.).
- Maintain developer-friendly, readable output.

---

## 🏗️ Project Phases

The project will be developed in **three main phases**, each containing multiple features and milestones.

---

## ⚙️ Phase 1 — Core Analysis Engine

### 🎯 Goal

Build the foundation: dependency detection, usage scanning, and CLI output.

### 🧠 Features

#### 1. ✅ Smart Context-Based Dependency Detection

- Scan all Dart files within the project (`lib/`, `test/`, `bin/`, `tool/`).
- Detect imports and map them to declared packages in `pubspec.yaml`.
- Classify dependencies into:
  - ✅ **Used in lib/**
  - 🧩 **Used only in test/bin/tool/**
  - ⚠️ **Unused**

**Implementation Notes:**

- Use a regex to detect imports like `import 'package:dio/dio.dart';`.
- Map to declared dependencies.
- Support multi-level analysis for nested folders.

**Output Example:**

```

✅ yaml — used in lib
🧩 args — used in bin (move to dev_dependencies)
⚠️ glob — unused (remove)

```

**Status: ✅ COMPLETED**

---

#### 2. ✅ Colored & Structured CLI Output

- Display results in a color-coded, easy-to-read format.
- Optional flag `--no-color` for CI pipelines.

**Color Codes:**

- ✅ Green → used
- 🧩 Yellow → move to `dev_dependencies`
- ⚠️ Red → unused

**Example Output:**

```

┌────────────────────────────┐
│ Analysis Results           │
└────────────────────────────┘

✅ Used Dependencies
✅ yaml - used in lib
✅ ansicolor - used in lib, bin

🧩 Move to dev_dependencies
🧩 args - used in bin

⚠️ Unused Dependencies
⚠️ glob - unused

```

**Status: ✅ COMPLETED**

---

#### 3. ✅ Analysis Mode (`--analyse`)

- Run a complete analysis **without modifying anything**.
- Outputs a categorized report.
- Serves as a safe preview before fixing.

**Example:**

```

smartpub --analyse

```

**Output:**

```

Analysis complete
✅ Used: yaml, ansicolor, path
🧩 Move to dev_dependencies: args
⚠️ Unused: glob, http, cupertino_icons

```

**Status: ✅ COMPLETED**

---

#### 4. ⏳ Safety Backup System

- Before any modification, create a backup of `pubspec.yaml` → `pubspec.yaml.bak`.
- Optional `--restore` command to revert.

**Example:**

```

💾 Backup created: pubspec.yaml.bak

```

**Status: ⏳ PLANNED**

---

## 🚀 Phase 2 — Intelligent Operations

### 🎯 Goal

Enable automatic and interactive dependency management with full control and safety.

### 🧠 Features

#### 1. 🚧 Auto-Apply Mode (`--apply`)

- Automatically modify `pubspec.yaml`:
  - Remove unused dependencies.
  - Move test-only dependencies to `dev_dependencies`.
- Create backup automatically before applying changes.
- Print summary of operations.

**Example:**

```

smartpub --apply

```

**Output:**

```

🧹 Removed: glob, http, cupertino_icons
🧩 Moved to dev_dependencies: args
✅ pubspec.yaml updated successfully

```

**Status: 🚧 IN PROGRESS**

---

#### 2. ✅ Interactive Mode (`--interactive`)

- Prompts the user for confirmation before making any change.
- Ideal for cautious cleanup.

**Example:**

```

smartpub --interactive

```

**Example Interaction:**

```

⚠️ glob — unused. Remove? [Y/n]
🧩 args — used only in bin/. Move to dev_dependencies? [Y/n]

```

**Status: 🚧 IN PROGRESS**

---

#### 3. ✅ Detect Duplicate Dependencies

- Identify packages declared in both `dependencies` and `dev_dependencies`.
- Suggest the correct location based on usage.
- Detect version conflicts between duplicate declarations.
- Automatically fix duplicates in apply mode.

**Output:**

```

⚠️ yaml (^3.1.2 vs ^3.1.0) - Keep in dependencies (used in lib)

```

**Status: ✅ COMPLETED**

---

#### 4. ✅ CI/CD Friendly Mode (`--no-color`)

- Minimal text output (no colors or emojis).
- Suitable for automation pipelines.
- Return codes:
  - `0` → Clean
  - `1` → Issues found

**Example:**

```

smartpub --analyse --no-color

```

**Example Output:**

```

=== Analysis Results ===
Used Dependencies: yaml, ansicolor, path
Move to dev_dependencies: args  
Unused Dependencies: glob, http, cupertino_icons

```

**Status: ✅ COMPLETED**

---

## 🧱 Phase 3 — Functional Organization & Automation

### 🎯 Goal

Make `pubspec.yaml` organized, readable, and semantically grouped.

### 🧠 Features

#### 1. Functional Grouping (`--organize`)

- Organize dependencies into logical categories:
  - `widgets`
  - `api`
  - `state management`
  - `database`
  - `testing`
  - `miscellaneous`

**Default Example Output:**

```yaml
dependencies:
  # widgets
  cached_network_image: ^3.2.0
  flutter_svg: ^2.0.0

  # api
  http: ^1.1.0
  dio: ^6.0.0

  # state management
  flutter_bloc: ^9.0.0

  # miscellaneous
  some_unknown_package: ^1.0.0
````

---

#### 2. Semi-Automatic Categorization

- Uses predefined mapping for popular packages.
- Unknown packages go under `# miscellaneous`.
- Optional CLI prompt:

  ```
  Unknown package: xyz
  Assign group? [widgets/api/state/testing/misc] (default: misc)
  ```

---

#### 3. Network-Based Auto Grouping _(Optional Future Feature)_

- Fetch tags from the **pub.dev API**:

  ```
  GET https://pub.dev/api/packages/<package>/score
  ```
- Use metadata (like “network”, “testing”, etc.) to auto-suggest group.

---

## 🧩 Optional Future Enhancements


| Feature                  | Description                                                   |
| -------------------------- | --------------------------------------------------------------- |
| **Export Reports**       | Generate JSON or Markdown summary of analysis.                |
| **IDE Integration**      | VS Code / IntelliJ plugin to show unused dependencies inline. |
| **Pub.dev API Learning** | Dynamically update internal package-group mappings.           |

---

## 🗂️ Project Structure

```
smartpub/
├── bin/
│   └── smartpub.dart          # Main CLI entry
├── lib/
│   ├── analyzer.dart          # Core dependency analyzer
│   ├── pubspec_manager.dart   # Read/write utilities for pubspec.yaml
│   ├── cli_output.dart        # Colored/structured CLI handling
│   ├── backup_service.dart    # Safety backup operations
│   ├── organizer.dart         # Grouping logic
│   └── models/
│       └── dependency_info.dart
└── test/
    └── analyzer_test.dart
```

---

## 🧰 Tech Stack

- **Language:** Dart
- **Dependencies:**

  - `yaml` → for parsing and writing YAML files
  - `ansicolor` → for CLI color output
  - `http` (optional) → for fetching package metadata
- **Testing:** `test` package

---

## ✅ Deliverables by Phase


| Phase       | Status | Deliverables                                   |
| ------------- | -------- | ------------------------------------------------ |
| **Phase 1** | ✅     | Core analyzer, analysis mode, CLI output       |
| **Phase 2** | 🚧     | Auto-apply, interactive mode, duplicates       |
| **Phase 3** | ⏳     | Functional grouping, optional network metadata |
| **Future**  | ⏳     | Reports, plugin integration                    |

**Legend:**

- ✅ Completed
- 🚧 In Progress
- ⏳ Planned

---

## ⚙️ Command Reference


| Command                   | Status | Description                             |
| --------------------------- | -------- | ----------------------------------------- |
| `smartpub` or `--analyse` | ✅     | Analyze without modifying files         |
| `--interactive` | ✅     | Review and apply changes interactively   |
| `--apply`                 | ✅     | Automatically apply fixes               |
| `--organize`              | ⏳     | Group dependencies by functionality     |
| `--no-color`              | ✅     | Disable colored output for CI pipelines |
| `--restore`               | ⏳     | Restore last backup of pubspec.yaml     |

**Legend:**

- ✅ Completed
- 🚧 In Progress
- ⏳ Planned

---

## 📄 License

MIT License (to allow open-source collaboration)

---

## 👥 Author / Maintainer

**Vatsal Jaganwala**
Flutter Developer & Open Source Contributor

---
