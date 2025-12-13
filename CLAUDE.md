# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

Flutter is located at `C:\Users\Bendi\flutter\bin\flutter` (not in PATH).

```bash
C:\Users\Bendi\flutter\bin\flutter pub get          # Install dependencies
C:\Users\Bendi\flutter\bin\flutter run              # Run the app (debug mode)
C:\Users\Bendi\flutter\bin\flutter build apk        # Build Android APK
C:\Users\Bendi\flutter\bin\flutter analyze          # Run static analysis
C:\Users\Bendi\flutter\bin\flutter pub run flutter_launcher_icons  # Regenerate app icons
```

## Architecture

**GooseTabs: The Tab Writer** - A Flutter mobile app for creating guitar/bass tablature. Uses Material 3 with dark theme (pastel orange #FFAB91 accent on gray/black base).

### Data Model (`lib/models/tab_model.dart`)

Column-based architecture for proper alignment of multi-character notes (e.g., "5b", "12", "6/7"):

```
GuitarTab
  └── sections: List<TabSection>
        ├── label (Intro, Verse, Chorus, etc.)
        ├── repeatCount
        ├── stringNames [e, B, G, D, A, E]
        └── bars: List<TabMeasure>
              └── columns: List<TabColumn>
                    └── notes: List<String>  // One per string, '-' for empty
```

Each `TabColumn` represents a vertical slice across all strings at one position. This ensures alignment when notes have different widths.

### Export Format

Exports pad each column to match the widest note, with a separator dash after each column:
```
e|--5b-7--3-|
B|---------|
G|---------|
```

### Key Editor Features (`lib/screens/tab_editor/`)

- **Chord Mode**: Toggle on → select notes on different strings → toggle off to commit all as one column
- **Techniques that append** (h, p, b, t, ~, /, \): Append to previous note (e.g., `2h`, `4~`, `5/7`)
- **Harmonic** (◆): Goes in own column, ONE digit appends (e.g., `◆9`)
- **Digits after b/\//\\**: Target frets append to these techniques (e.g., `5b7`, `4/7`)

Example line: `|-1--2h2b-4-4/3--4~-◆9`

### Storage (`lib/services/storage_service.dart`)

- Persists to `SharedPreferences` as JSON
- `downloadTabToDownloads()` saves to system Downloads folder
- `exportTabToFile()` uses system share sheet
- `importTabFromFile()` parses `.txt`/`.tab` files

### Screen Flow

```
MainMenuScreen → TabEditorScreen (new/edit)
              → TabsListScreen → TabEditorScreen
                              → TabViewerScreen
              → Import → TabEditorScreen
```

## Code Style Guidelines

### OOC (Object-Oriented Code) Pattern

**Keep files small and focused.** This codebase follows OOC principles - avoid gigantic files.

- **Maximum ~300-400 lines per file** - if a file exceeds this, split it into smaller components
- **Extract reusable widgets** into separate files under `widgets/` subdirectory
- **Extract dialogs** into separate files under `dialogs/` subdirectory
- **One widget per file** - each StatefulWidget/StatelessWidget should be in its own file
- **Group related files** in subdirectories (e.g., `lib/screens/tab_editor/widgets/`)

Example structure:
```
lib/screens/tab_editor/
├── tab_editor_screen.dart      # Main screen (orchestrates components)
├── widgets/
│   ├── fretboard.dart
│   ├── technique_toolbar.dart
│   └── section_selector.dart
└── dialogs/
    ├── tuning_dialog.dart
    └── section_label_dialog.dart
```
