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

**GooseTabs: The Tab Writer** - A Flutter mobile app for creating guitar/bass tablature. Uses Material 3 with customizable color schemes (8 options: Orange, Blue, Green, Purple, Red, Teal, Pink, Amber) and supports light/dark/system themes.

### Data Models

#### GuitarTab (`lib/models/tab_model.dart`)

Column-based architecture for proper alignment of multi-character notes (e.g., "5b", "12", "6/7"):

```
GuitarTab
  ├── folderId (optional)           # For folder organization
  ├── songStructure (optional)      # Custom section ordering for export
  └── sections: List<TabSection>
        ├── label (Intro, Verse, Chorus, etc.)
        ├── repeatCount
        ├── stringNames [e, B, G, D, A, E]
        └── bars: List<TabMeasure>
              └── columns: List<TabColumn>
                    └── notes: List<String>  // One per string, '-' for empty
```

Each `TabColumn` represents a vertical slice across all strings at one position. This ensures alignment when notes have different widths.

#### TabFolder (`lib/models/folder_model.dart`)

Simple folder model for organizing tabs:
```
TabFolder
  ├── id
  ├── name
  └── createdAt
```

### Export Format

Exports pad each column to match the widest note, with a separator dash after each column:
```
e|--5b-7--3-|
B|---------|
G|---------|
```

Supports custom song structure ordering via `toTabFormatWithStructure()`.

### Key Editor Features (`lib/screens/tab_editor/`)

- **Chord Mode**: Toggle on -> select notes on different strings -> toggle off to commit all as one column
- **Techniques that append** (h, p, b, t, ~, /, \): Append to previous note (e.g., `2h`, `4~`, `5/7`)
- **Harmonic** (diamond): Goes in own column, ONE digit appends (e.g., `<>9`)
- **Digits after b/\//\\**: Target frets append to these techniques (e.g., `5b7`, `4/7`)

Example line: `|-1--2h2b-4-4/3--4~-<>9`

### Services

#### StorageService (`lib/services/storage_service.dart`)

Static methods for persistence via `SharedPreferences`:

**Tab CRUD:**
- `saveTab()`, `loadAllTabs()`, `deleteTab()`, `getTab()`

**Folder CRUD:**
- `saveFolder()`, `loadAllFolders()`, `deleteFolder()`, `moveTabToFolder()`

**Import/Export:**
- `importTabFromFile()`, `importTabFromText()` - parses `.txt`/`.tab` files
- `exportTabToFile()`, `exportTabToFileWithStructure()` - uses system share sheet
- `downloadTabToDownloads()`, `downloadTabToDownloadsWithStructure()` - saves to Downloads

#### SettingsService (`lib/services/settings_service.dart`)

`ChangeNotifier` for app-wide settings:
- Color scheme selection (8 themes)
- Theme mode (Light/Dark/System)
- Default instrument (Guitar/Bass)
- Default string count
- Haptic feedback toggle
- Auto-save toggle

### Theme System (`lib/theme/app_theme.dart`)

- `buildDarkTheme()` and `buildLightTheme()` methods
- `ColorSchemeType` enum with 8 customizable color schemes
- Dynamic accent color generation using HSLColor
- Full Material 3 support

### Screen Flow

```
MainMenuScreen -> TabEditorScreen (new/edit)
              -> TabsListScreen (with folder management)
                   -> TabEditorScreen (edit existing)
                   -> TabViewerScreen (view/export/manage structure)
              -> SettingsScreen (app preferences)
              -> BlackjackScreen (secret - 5 taps on logo)
              -> Import -> TabEditorScreen
```

### Directory Structure

```
lib/
├── main.dart
├── models/
│   ├── tab_model.dart
│   └── folder_model.dart
├── screens/
│   ├── main_menu/
│   │   ├── main_menu_screen.dart
│   │   └── widgets/
│   │       ├── menu_card.dart
│   │       ├── new_tab_sheet.dart
│   │       ├── instrument_option.dart
│   │       └── string_count_option.dart
│   ├── tabs_list/
│   │   ├── tabs_list_screen.dart
│   │   ├── dialogs/
│   │   │   ├── folder_name_dialog.dart
│   │   │   ├── folder_options_dialog.dart
│   │   │   └── move_to_folder_dialog.dart
│   │   └── widgets/
│   │       ├── tab_card.dart
│   │       ├── folder_card.dart
│   │       └── info_chip.dart
│   ├── tab_editor/
│   │   ├── tab_editor_screen.dart
│   │   ├── dialogs/
│   │   │   ├── tuning_dialog.dart
│   │   │   ├── section_label_dialog.dart
│   │   │   ├── repeat_count_dialog.dart
│   │   │   ├── section_menu_dialog.dart
│   │   │   ├── tab_name_dialog.dart
│   │   │   └── slide_dialog.dart
│   │   └── widgets/
│   │       ├── editor_app_bar.dart
│   │       ├── fretboard.dart
│   │       ├── technique_toolbar.dart
│   │       ├── technique_button.dart
│   │       ├── section_selector.dart
│   │       ├── section_options.dart
│   │       ├── tab_display.dart
│   │       └── nav_button.dart
│   ├── tab_viewer/
│   │   ├── tab_viewer_screen.dart
│   │   └── widgets/
│   │       ├── action_button.dart
│   │       ├── info_tag.dart
│   │       └── date_info.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   └── widgets/
│   │       ├── color_scheme_picker.dart
│   │       └── settings_section.dart
│   └── secret/
│       ├── blackjack_screen.dart
│       ├── card_models.dart
│       └── widgets/
│           ├── playing_card_widget.dart
│           ├── chip_widget.dart
│           ├── dealer_widget.dart
│           └── confetti_widget.dart
├── services/
│   ├── storage_service.dart
│   └── settings_service.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    └── common/
        └── app_bar_action.dart
```

## Code Style Guidelines

### OOC (Object-Oriented Code) Pattern

**Keep files small and focused.** This codebase follows OOC principles - avoid gigantic files.

- **Maximum ~300-400 lines per file** - if a file exceeds this, split it into smaller components
- **Extract reusable widgets** into separate files under `widgets/` subdirectory
- **Extract dialogs** into separate files under `dialogs/` subdirectory
- **One widget per file** - each StatefulWidget/StatelessWidget should be in its own file
- **Group related files** in subdirectories (e.g., `lib/screens/tab_editor/widgets/`)
