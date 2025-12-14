import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../services/storage_service.dart';
import '../tab_viewer/tab_viewer_screen.dart';
import 'widgets/editor_app_bar.dart';
import 'widgets/section_selector.dart';
import 'widgets/fretboard.dart';
import 'widgets/technique_toolbar.dart';
import 'widgets/section_options.dart';
import 'widgets/tab_display.dart';
import 'dialogs/tuning_dialog.dart';
import 'dialogs/section_label_dialog.dart';
import 'dialogs/repeat_count_dialog.dart';
import 'dialogs/section_menu_dialog.dart';
import 'dialogs/tab_name_dialog.dart';

class TabEditorScreen extends StatefulWidget {
  final GuitarTab tab;

  const TabEditorScreen({super.key, required this.tab});

  @override
  State<TabEditorScreen> createState() => _TabEditorScreenState();
}

class _TabEditorScreenState extends State<TabEditorScreen> {
  late GuitarTab _tab;
  bool _hasChanges = false;
  int _selectedSectionIndex = 0;
  int _selectedStringIndex = 0;
  int _cursorPosition = 0;
  bool _chordMode = false;
  Map<int, String> _chordNotes = {};
  final ScrollController _tabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tab = widget.tab;
    if (_tab.sections.isEmpty) {
      _tab.sections.add(_tab.createEmptySection());
    }
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    super.dispose();
  }

  TabSection get _currentSection => _tab.sections[_selectedSectionIndex];

  int _getTotalColumns() {
    return _currentSection.bars.fold(0, (sum, bar) => sum + bar.columns.length);
  }

  // ============================================================
  // Scroll Management
  // ============================================================

  void _scrollToCursor() {
    if (!_tabScrollController.hasClients) return;

    final section = _currentSection;
    double cursorX = 24 + 8;
    int globalPos = 0;

    for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
      final bar = section.bars[barIdx];
      for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
        int maxLen = 1;
        for (int s = 0; s < section.stringCount; s++) {
          final n = bar.getNote(colIdx, s);
          if (n.length > maxLen) maxLen = n.length;
        }
        final colWidth = maxLen * 10.0 + 6;

        if (globalPos == _cursorPosition) {
          final viewportWidth = _tabScrollController.position.viewportDimension;
          final currentScroll = _tabScrollController.offset;

          if (cursorX < currentScroll + 50) {
            _tabScrollController.animateTo(
              (cursorX - 50).clamp(0, _tabScrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          } else if (cursorX > currentScroll + viewportWidth - 100) {
            _tabScrollController.animateTo(
              (cursorX - viewportWidth + 100).clamp(0, _tabScrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
          return;
        }
        cursorX += colWidth;
        globalPos++;
      }
      cursorX += 8;
    }
  }

  void _scheduleScrollToCursor() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCursor());
  }

  // ============================================================
  // Tab Operations
  // ============================================================

  Future<void> _saveTab() async {
    _tab.modifiedAt = DateTime.now();
    await StorageService.saveTab(_tab);
    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 12),
              const Text('Tab saved successfully!'),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _exportTab() async {
    await _saveTab();
    await StorageService.exportTabToFile(_tab);
  }

  Future<void> _downloadTab() async {
    await _saveTab();
    final path = await StorageService.downloadTabToDownloads(_tab);
    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Saved to Downloads')),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _editTabName() async {
    final result = await TabNameDialog.show(
      context: context,
      currentName: _tab.songName,
    );

    if (result != null && result.isNotEmpty && result != _tab.songName && mounted) {
      setState(() {
        _tab.songName = result;
        _hasChanges = true;
      });
    }
  }

  // ============================================================
  // Note Operations
  // ============================================================

  void _addNote(String note) {
    if (_chordMode) {
      setState(() {
        _chordNotes[_selectedStringIndex] = note;
      });
      return;
    }

    setState(() {
      // Check if we should append digit to previous incomplete note
      // Techniques that take target frets: h, p, b, t, /, \, +
      if (_cursorPosition > 0 && RegExp(r'^\d+$').hasMatch(note)) {
        int prevPos = _cursorPosition - 1;
        for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
          final bar = _currentSection.bars[barIdx];
          if (prevPos < bar.columns.length) {
            final prevNote = bar.getNote(prevPos, _selectedStringIndex);
            // h, p, b, t, /, \, + can have target frets appended (e.g., 5h6, 3p2, 5b7, 6/7, +12, h3)
            if (RegExp(r'[hpbt/\\+]$').hasMatch(prevNote)) {
              bar.setNote(prevPos, _selectedStringIndex, prevNote + note);
              _hasChanges = true;
              return;
            }
            break;
          }
          prevPos -= bar.columns.length;
        }
      }

      // INSERT a new column at current position and set the note
      int pos = _cursorPosition;
      for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
        final bar = _currentSection.bars[barIdx];
        final isLastBar = barIdx == _currentSection.bars.length - 1;
        // Only allow adding at end of bar if it's the last bar
        // Otherwise, pos == bar.columns.length means start of next bar
        if (pos < bar.columns.length || (isLastBar && pos == bar.columns.length)) {
          // Insert new column at this position
          final newCol = TabColumn(bar.stringCount);
          newCol.notes[_selectedStringIndex] = note;
          if (pos < bar.columns.length) {
            bar.columns.insert(pos, newCol);
          } else {
            bar.columns.add(newCol);
          }
          _cursorPosition++;
          _hasChanges = true;
          return;
        }
        pos -= bar.columns.length;
      }
      // At the end - add to last bar
      final lastBar = _currentSection.bars.last;
      final newCol = TabColumn(lastBar.stringCount);
      newCol.notes[_selectedStringIndex] = note;
      lastBar.columns.add(newCol);
      _cursorPosition = _getTotalColumns();
      _hasChanges = true;
    });
    _scheduleScrollToCursor();
  }

  // Append technique symbol to the previous note, or add as standalone column
  void _appendTechnique(String technique) {
    setState(() {
      // Try to append to previous note if it has a fret number
      if (_cursorPosition > 0) {
        int prevPos = _cursorPosition - 1;
        for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
          final bar = _currentSection.bars[barIdx];
          if (prevPos < bar.columns.length) {
            final prevNote = bar.getNote(prevPos, _selectedStringIndex);
            // Append if previous note has a fret number
            if (prevNote != '-' && RegExp(r'\d').hasMatch(prevNote)) {
              bar.setNote(prevPos, _selectedStringIndex, prevNote + technique);
              _hasChanges = true;
              return;
            }
            break;
          }
          prevPos -= bar.columns.length;
        }
      }

      // No previous note to append to - add technique as new column
      // This allows standalone techniques like h3, /6, +12
      _addNote(technique);
    });
  }

  void _commitChord() {
    if (_chordNotes.isEmpty) return;

    setState(() {
      // Add chord at current position (no automatic dash before)
      int pos = _cursorPosition;
      for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
        final bar = _currentSection.bars[barIdx];
        if (pos < bar.columns.length) {
          for (final entry in _chordNotes.entries) {
            bar.setNote(pos, entry.key, entry.value);
          }
          _cursorPosition++;
          if (_cursorPosition >= _getTotalColumns()) {
            _currentSection.bars.last.addColumn();
          }
          _chordNotes.clear();
          _hasChanges = true;
          return;
        }
        pos -= bar.columns.length;
      }
      final lastBar = _currentSection.bars.last;
      lastBar.addColumn();
      for (final entry in _chordNotes.entries) {
        lastBar.setNote(lastBar.columns.length - 1, entry.key, entry.value);
      }
      _cursorPosition = _getTotalColumns();
      _chordNotes.clear();
      _hasChanges = true;
    });
  }

  void _addBarLine() {
    setState(() {
      int pos = _cursorPosition;
      int columnsBeforeCursor = 0;

      for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
        final bar = _currentSection.bars[barIdx];
        if (pos < bar.columns.length) {
          // Cursor is within this bar - split it
          final newBar = TabMeasure(stringCount: _currentSection.stringCount);
          while (pos < bar.columns.length) {
            newBar.columns.add(bar.columns.removeAt(pos));
          }
          if (bar.columns.isEmpty) bar.addColumn();
          if (newBar.columns.isEmpty) newBar.addColumn();
          _currentSection.bars.insert(barIdx + 1, newBar);
          // Move cursor to start of new bar
          _cursorPosition = columnsBeforeCursor + bar.columns.length;
          _hasChanges = true;
          return;
        } else if (pos == bar.columns.length) {
          // Cursor is at the end of this bar - insert new bar after it
          final newBar = TabMeasure(stringCount: _currentSection.stringCount);
          newBar.addColumn();
          _currentSection.bars.insert(barIdx + 1, newBar);
          // Move cursor to start of new bar
          _cursorPosition = columnsBeforeCursor + bar.columns.length;
          _hasChanges = true;
          return;
        }
        columnsBeforeCursor += bar.columns.length;
        pos -= bar.columns.length;
      }
      // Fallback: add new bar at the end
      final newBar = TabMeasure(stringCount: _currentSection.stringCount);
      newBar.addColumn();
      _currentSection.bars.add(newBar);
      // Move cursor to new bar
      _cursorPosition = _getTotalColumns() - 1;
      _hasChanges = true;
    });
    _scheduleScrollToCursor();
  }

  void _backspace() {
    if (_cursorPosition > 0) {
      setState(() {
        _cursorPosition--;
        int pos = _cursorPosition;
        int columnsBeforeBar = 0;
        for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
          final bar = _currentSection.bars[barIdx];
          if (pos < bar.columns.length) {
            bar.removeColumn(pos);
            if (bar.columns.isEmpty) {
              if (_currentSection.bars.length > 1) {
                _currentSection.bars.removeAt(barIdx);
                if (_cursorPosition > columnsBeforeBar && barIdx > 0) {
                  _cursorPosition = columnsBeforeBar;
                }
              } else {
                bar.addColumn();
              }
            }
            _hasChanges = true;
            return;
          }
          columnsBeforeBar += bar.columns.length;
          pos -= bar.columns.length;
        }
      });
    } else if (_cursorPosition == 0 && _currentSection.bars.length > 1) {
      setState(() {
        if (_currentSection.bars[0].columns.length == 1 &&
            _currentSection.bars[0].columns[0].isEmpty) {
          _currentSection.bars.removeAt(0);
          _hasChanges = true;
        }
      });
    }
    _scheduleScrollToCursor();
  }

  void _moveCursor(int delta) {
    setState(() {
      _cursorPosition = (_cursorPosition + delta).clamp(0, _getTotalColumns());
    });
    _scheduleScrollToCursor();
  }

  // ============================================================
  // Section Operations
  // ============================================================

  void _addSection() {
    setState(() {
      final currentStringNames = List<String>.from(_currentSection.stringNames);
      final newSection = TabSection(stringNames: currentStringNames);
      newSection.bars[0].addColumn();
      _tab.sections.add(newSection);
      _selectedSectionIndex = _tab.sections.length - 1;
      _cursorPosition = 0;
      _hasChanges = true;
    });
  }

  void _deleteSection(int index) {
    if (_tab.sections.length <= 1) return;
    setState(() {
      _tab.sections.removeAt(index);
      if (_selectedSectionIndex >= _tab.sections.length) {
        _selectedSectionIndex = _tab.sections.length - 1;
      }
      _cursorPosition = 0;
      _hasChanges = true;
    });
  }

  Future<void> _editSectionLabel() async {
    final newLabel = await SectionLabelDialog.show(
      context: context,
      currentLabel: _currentSection.label,
    );

    if (newLabel != _currentSection.label) {
      setState(() {
        _currentSection.label = newLabel;
        _hasChanges = true;
      });
    }
  }

  Future<void> _setRepeatCount() async {
    final newCount = await RepeatCountDialog.show(
      context: context,
      currentCount: _currentSection.repeatCount,
    );

    if (newCount != null && newCount != _currentSection.repeatCount) {
      setState(() {
        _currentSection.repeatCount = newCount;
        _hasChanges = true;
      });
    }
  }

  Future<void> _editStringTuning(int stringIndex) async {
    final currentTuning = _currentSection.stringNames[stringIndex];
    final stringCount = _currentSection.stringCount;

    final newTuning = await TuningDialog.show(
      context: context,
      stringIndex: stringIndex,
      currentTuning: currentTuning,
      stringCount: stringCount,
    );

    if (newTuning != null && newTuning.isNotEmpty && mounted) {
      setState(() {
        _currentSection.stringNames[stringIndex] = newTuning;
        _hasChanges = true;
      });
    }
  }

  Future<void> _showSectionMenu(int index) async {
    final action = await SectionMenuDialog.show(
      context: context,
      canDelete: _tab.sections.length > 1,
    );

    if (action == null) return;

    _selectedSectionIndex = index;

    switch (action) {
      case SectionMenuAction.editLabel:
        await _editSectionLabel();
        break;
      case SectionMenuAction.setRepeats:
        await _setRepeatCount();
        break;
      case SectionMenuAction.delete:
        _deleteSection(index);
        break;
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: EditorAppBar(
        songName: _tab.songName,
        tuning: _tab.tuning,
        hasChanges: _hasChanges,
        onBack: () => Navigator.pop(context),
        onNameTap: _editTabName,
        onPreview: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TabViewerScreen(tab: _tab)),
        ),
        onDownload: _downloadTab,
        onShare: _exportTab,
        onSave: _saveTab,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SectionSelector(
              sections: _tab.sections,
              selectedIndex: _selectedSectionIndex,
              onSectionSelected: (index) => setState(() {
                _selectedSectionIndex = index;
                _cursorPosition = 0;
              }),
              onAddSection: _addSection,
              onSectionLongPress: _showSectionMenu,
            ),
            Fretboard(
              stringNames: _currentSection.stringNames,
              selectedStringIndex: _selectedStringIndex,
              chordNotes: _chordNotes,
              onStringSelected: (index) => setState(() => _selectedStringIndex = index),
              onTuningTap: _editStringTuning,
              onFretTap: (stringIndex, fret) {
                setState(() => _selectedStringIndex = stringIndex);
                _addNote(fret.toString());
              },
            ),
            TechniqueToolbar(
              chordMode: _chordMode,
              chordNotesCount: _chordNotes.length,
              onChordModeToggle: () {
                if (_chordMode && _chordNotes.isNotEmpty) {
                  _commitChord();
                }
                setState(() {
                  _chordMode = !_chordMode;
                  if (!_chordMode) _chordNotes.clear();
                });
              },
              onTechniqueTap: _appendTechnique,  // h, p, b, t, ~ append to previous note or standalone
              onSlideTap: _appendTechnique,      // /, \ append to previous note or standalone
              onHarmonicTap: () => _appendTechnique('+'), // + appends to previous note or standalone
              onBarLineTap: _addBarLine,
              onDashTap: () => _addNote('-'),
            ),
            SectionOptions(
              sectionLabel: _currentSection.label,
              repeatCount: _currentSection.repeatCount,
              onLabelTap: _editSectionLabel,
              onRepeatTap: _setRepeatCount,
            ),
            Expanded(
              child: TabDisplay(
                section: _currentSection,
                cursorPosition: _cursorPosition,
                selectedStringIndex: _selectedStringIndex,
                totalColumns: _getTotalColumns(),
                scrollController: _tabScrollController,
                onMoveLeft: () => _moveCursor(-1),
                onMoveRight: () => _moveCursor(1),
                onBackspace: _backspace,
                onCellTap: (position, stringIndex) => setState(() {
                  _cursorPosition = position;
                  _selectedStringIndex = stringIndex;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
