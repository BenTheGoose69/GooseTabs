import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_bar_action.dart';
import '../tab_viewer/tab_viewer_screen.dart';
import 'widgets/technique_button.dart';
import 'widgets/nav_button.dart';
import 'dialogs/slide_dialog.dart';
import 'dialogs/tuning_dialog.dart';
import 'dialogs/section_label_dialog.dart';
import 'dialogs/repeat_count_dialog.dart';
import 'dialogs/section_menu_dialog.dart';

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

  final List<String> _techniques = ['h', 'p', 'b', 'r', '~', 'x', 't', '(', ')'];
  final List<String> _slideTechniques = ['/', '\\'];

  @override
  void initState() {
    super.initState();
    _tab = widget.tab;
    if (_tab.sections.isEmpty) {
      _tab.sections.add(_tab.createEmptySection());
    }
  }

  TabSection get _currentSection => _tab.sections[_selectedSectionIndex];

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
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
      int pos = _cursorPosition;
      for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
        final bar = _currentSection.bars[barIdx];
        if (pos < bar.columns.length) {
          bar.setNote(pos, _selectedStringIndex, note);
          _cursorPosition++;
          if (_cursorPosition >= _getTotalColumns()) {
            _currentSection.bars.last.addColumn();
          }
          _hasChanges = true;
          return;
        }
        pos -= bar.columns.length;
      }
      final lastBar = _currentSection.bars.last;
      lastBar.addColumn();
      lastBar.setNote(lastBar.columns.length - 1, _selectedStringIndex, note);
      _cursorPosition = _getTotalColumns();
      _hasChanges = true;
    });
  }

  void _commitChord() {
    if (_chordNotes.isEmpty) return;

    setState(() {
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

  void _addTechnique(String technique) {
    setState(() {
      int pos = _cursorPosition > 0 ? _cursorPosition - 1 : 0;
      for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
        final bar = _currentSection.bars[barIdx];
        if (pos < bar.columns.length) {
          final currentNote = bar.getNote(pos, _selectedStringIndex);
          if (currentNote != '-') {
            bar.setNote(pos, _selectedStringIndex, currentNote + technique);
          } else {
            bar.setNote(pos, _selectedStringIndex, technique);
          }
          _hasChanges = true;
          return;
        }
        pos -= bar.columns.length;
      }
    });
  }

  Future<void> _addSlide(String slideType) async {
    int pos = _cursorPosition > 0 ? _cursorPosition - 1 : 0;
    String previousNote = '-';

    for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
      final bar = _currentSection.bars[barIdx];
      if (pos < bar.columns.length) {
        previousNote = bar.getNote(pos, _selectedStringIndex);
        break;
      }
      pos -= bar.columns.length;
    }

    final targetFret = await SlideDialog.show(
      context: context,
      slideType: slideType,
      previousNote: previousNote,
    );

    if (targetFret == null || targetFret.isEmpty) return;

    if (previousNote != '-') {
      setState(() {
        int pos = _cursorPosition > 0 ? _cursorPosition - 1 : 0;
        for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
          final bar = _currentSection.bars[barIdx];
          if (pos < bar.columns.length) {
            bar.setNote(pos, _selectedStringIndex, '$previousNote$slideType$targetFret');
            _hasChanges = true;
            return;
          }
          pos -= bar.columns.length;
        }
      });
    } else {
      _addNote('$slideType$targetFret');
    }
  }

  void _addBarLine() {
    setState(() {
      final newBar = TabMeasure(stringCount: _currentSection.stringCount);
      newBar.addColumn();
      _currentSection.bars.add(newBar);
      _cursorPosition = _getTotalColumns() - 1;
      _hasChanges = true;
    });
  }

  void _backspace() {
    if (_cursorPosition > 0) {
      setState(() {
        _cursorPosition--;
        int pos = _cursorPosition;
        for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
          final bar = _currentSection.bars[barIdx];
          if (pos < bar.columns.length) {
            for (int s = 0; s < _currentSection.stringCount; s++) {
              bar.setNote(pos, s, '-');
            }
            _hasChanges = true;
            return;
          }
          pos -= bar.columns.length;
        }
      });
    }
  }

  void _moveCursor(int delta) {
    setState(() {
      _cursorPosition = (_cursorPosition + delta).clamp(0, _getTotalColumns());
    });
  }

  int _getTotalColumns() {
    return _currentSection.bars.fold(0, (sum, bar) => sum + bar.columns.length);
  }

  // ============================================================
  // Section Operations
  // ============================================================

  void _addSection() {
    setState(() {
      // Copy string names from current section to preserve custom tunings
      final currentStringNames = List<String>.from(_currentSection.stringNames);
      final newSection = TabSection(stringNames: currentStringNames);
      // Start with 16 columns
      for (int i = 0; i < 16; i++) {
        newSection.bars[0].addColumn();
      }
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
    // Store current values before showing dialog
    final currentTuning = _currentSection.stringNames[stringIndex];
    final stringCount = _currentSection.stringCount;

    final newTuning = await TuningDialog.show(
      context: context,
      stringIndex: stringIndex,
      currentTuning: currentTuning,
      stringCount: stringCount,
    );

    // Only update if we got a valid new tuning and widget is still mounted
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
  // Build Methods
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSectionSelector(),
          _buildFretboard(),
          _buildTechniqueButtons(),
          _buildSectionOptions(),
          Expanded(child: _buildTabDisplay()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tab.songName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            _tab.tuning,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      actions: [
        AppBarAction(
          icon: Icons.visibility_outlined,
          tooltip: 'Preview',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TabViewerScreen(tab: _tab)),
          ),
        ),
        AppBarAction(
          icon: Icons.download_outlined,
          tooltip: 'Download',
          onPressed: _downloadTab,
        ),
        AppBarAction(
          icon: Icons.share_outlined,
          tooltip: 'Share',
          onPressed: _exportTab,
        ),
        AppBarAction(
          icon: _hasChanges ? Icons.save : Icons.save_outlined,
          tooltip: 'Save',
          highlighted: _hasChanges,
          onPressed: _saveTab,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _tab.sections.length + 1,
              itemBuilder: (context, index) {
                if (index == _tab.sections.length) {
                  return _buildAddSectionButton();
                }
                return _buildSectionChip(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSectionButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addSection,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionChip(int index) {
    final section = _tab.sections[index];
    final isSelected = index == _selectedSectionIndex;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _selectedSectionIndex = index;
            _cursorPosition = 0;
          }),
          onLongPress: () => _showSectionMenu(index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
            ),
            alignment: Alignment.center,
            child: Text(
              section.label ?? 'Section ${index + 1}',
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFretboard() {
    final stringNames = _currentSection.stringNames;
    const int maxFret = 24;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _buildTuningSettingsButton(stringNames),
            _buildStringLabels(stringNames),
            Expanded(child: _buildFretGrid(stringNames, maxFret)),
          ],
        ),
      ),
    );
  }

  Widget _buildTuningSettingsButton(List<String> stringNames) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(stringNames.length, (stringIndex) {
          return GestureDetector(
            onTap: () => _editStringTuning(stringIndex),
            child: Container(
              width: 28,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.settings,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStringLabels(List<String> stringNames) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(stringNames.length, (stringIndex) {
          final isSelected = stringIndex == _selectedStringIndex;
          final hasChordNote = _chordNotes.containsKey(stringIndex);
          final chordNote = _chordNotes[stringIndex];

          return GestureDetector(
            onTap: () => setState(() => _selectedStringIndex = stringIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: hasChordNote ? 44 : 32,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected || hasChordNote
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: hasChordNote
                    ? Border.all(color: Theme.of(context).colorScheme.secondary, width: 2)
                    : null,
              ),
              child: Text(
                hasChordNote ? '${stringNames[stringIndex]}:$chordNote' : stringNames[stringIndex],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: hasChordNote ? 11 : 14,
                  color: isSelected || hasChordNote
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFretGrid(List<String> stringNames, int maxFret) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(maxFret + 1, (fret) {
          final isMarkerFret = [3, 5, 7, 9, 12, 15, 17, 19, 21, 24].contains(fret);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(stringNames.length, (stringIndex) {
              return _buildFretCell(stringIndex, fret, isMarkerFret);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildFretCell(int stringIndex, int fret, bool isMarkerFret) {
    final isSelectedRow = stringIndex == _selectedStringIndex;
    final hasChordNote = _chordNotes.containsKey(stringIndex);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedStringIndex = stringIndex);
        _addNote(fret.toString());
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: hasChordNote
              ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
              : isSelectedRow
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : isMarkerFret
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.08)
                      : Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasChordNote
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: hasChordNote ? 1.5 : 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          fret.toString(),
          style: TextStyle(
            fontSize: fret >= 10 ? 11 : 12,
            fontWeight: isMarkerFret ? FontWeight.w600 : FontWeight.normal,
            color: hasChordNote
                ? Theme.of(context).colorScheme.secondary
                : isSelectedRow
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTechniqueButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChordModeButton(),
            _buildDivider(),
            ..._techniques.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TechniqueButton(label: t, onTap: () => _addTechnique(t)),
                )),
            ..._slideTechniques.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TechniqueButton(
                    label: t,
                    tooltip: t == '/' ? 'Slide up' : 'Slide down',
                    onTap: () => _addSlide(t),
                  ),
                )),
            _buildDivider(),
            TechniqueButton(label: '|', tooltip: 'Add bar', isWide: true, onTap: _addBarLine),
            const SizedBox(width: 6),
            TechniqueButton(label: '-', tooltip: 'Empty', onTap: () => _addNote('-')),
          ],
        ),
      ),
    );
  }

  Widget _buildChordModeButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_chordMode && _chordNotes.isNotEmpty) {
              _commitChord();
            }
            setState(() {
              _chordMode = !_chordMode;
              if (!_chordMode) {
                _chordNotes.clear();
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _chordMode
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _chordMode
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.layers,
                  size: 16,
                  color: _chordMode
                      ? Colors.black
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  _chordMode && _chordNotes.isNotEmpty
                      ? 'Add (${_chordNotes.length})'
                      : 'Chord',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _chordMode
                        ? Colors.black
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
    );
  }

  Widget _buildSectionOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _editSectionLabel,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.label_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentSection.label ?? 'Add section label...',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _currentSection.label == null
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _setRepeatCount,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _currentSection.repeatCount > 1
                    ? Theme.of(context).colorScheme.secondary.withOpacity(0.15)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _currentSection.repeatCount > 1
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.5)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.repeat,
                    size: 18,
                    color: _currentSection.repeatCount > 1
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'x${_currentSection.repeatCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _currentSection.repeatCount > 1
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabDisplay() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          _buildNavigationControls(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildTabLines(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          NavButton(icon: Icons.keyboard_arrow_left, onTap: () => _moveCursor(-1)),
          const SizedBox(width: 8),
          NavButton(icon: Icons.keyboard_arrow_right, onTap: () => _moveCursor(1)),
          const SizedBox(width: 8),
          NavButton(icon: Icons.backspace_outlined, onTap: _backspace, isDestructive: true),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Col ${_cursorPosition + 1} / ${_getTotalColumns()}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabLines() {
    final section = _currentSection;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(section.stringCount, (stringIndex) {
            return _buildStringLine(section, stringIndex);
          }),
        ),
      ),
    );
  }

  Widget _buildStringLine(TabSection section, int stringIndex) {
    final stringName = section.stringNames[stringIndex];
    final isSelectedString = stringIndex == _selectedStringIndex;

    return Container(
      decoration: BoxDecoration(
        color: isSelectedString ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedStringIndex = stringIndex),
            child: Container(
              width: 24,
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                stringName,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelectedString
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
          Text(
            '|',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          ..._buildNoteWidgets(section, stringIndex),
          Text(
            '|',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          if (stringIndex == section.stringCount - 1 && section.repeatCount > 1)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'x${section.repeatCount}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildNoteWidgets(TabSection section, int stringIndex) {
    List<Widget> widgets = [];
    int globalPos = 0;

    for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
      final bar = section.bars[barIdx];

      for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
        final note = bar.getNote(colIdx, stringIndex);
        final isCursor = globalPos == _cursorPosition && stringIndex == _selectedStringIndex;
        final currentPos = globalPos;

        int maxLen = 1;
        for (int s = 0; s < section.stringCount; s++) {
          final n = bar.getNote(colIdx, s);
          if (n.length > maxLen) maxLen = n.length;
        }

        widgets.add(
          GestureDetector(
            onTap: () => setState(() {
              _cursorPosition = currentPos;
              _selectedStringIndex = stringIndex;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: maxLen * 10.0 + 6,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCursor ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
                border: isCursor
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                note == '-' ? '-' : note,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: note != '-' ? FontWeight.bold : FontWeight.normal,
                  color: note != '-'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
        );
        globalPos++;
      }

      if (barIdx < section.bars.length - 1) {
        widgets.add(Container(
          width: 16,
          height: 24,
          alignment: Alignment.center,
          child: Text(
            '|',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ));
      }
    }

    return widgets;
  }
}
