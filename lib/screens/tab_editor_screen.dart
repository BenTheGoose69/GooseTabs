import 'package:flutter/material.dart';
import '../models/tab_model.dart';
import '../services/storage_service.dart';
import 'tab_viewer_screen.dart';

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
  Map<int, String> _chordNotes = {}; // For chord mode - staged notes (stringIndex -> note)

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

  void _addNote(String note) {
    if (_chordMode) {
      // In chord mode, stage the note for the selected string
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
          // Add all staged notes to this column
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
      // Past all columns, add to last bar
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

  void _addSlide(String slideType) {
    // Get the previous note to build slide notation like "6/7"
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

    // Show dialog to get target fret
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(slideType, style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )),
              ),
              const SizedBox(width: 12),
              Text(slideType == '/' ? 'Slide Up' : 'Slide Down'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Target fret (0-24)',
                prefixIcon: const Icon(Icons.music_note),
                prefixText: previousNote != '-' ? '$previousNote$slideType' : slideType,
              ),
              autofocus: true,
              onSubmitted: (_) => _submitSlide(ctx, controller, slideType, previousNote),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => _submitSlide(ctx, controller, slideType, previousNote),
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  void _submitSlide(BuildContext ctx, TextEditingController controller, String slideType, String previousNote) {
    final targetFret = controller.text.trim();
    if (targetFret.isEmpty) {
      Navigator.pop(ctx);
      return;
    }

    Navigator.pop(ctx);

    if (previousNote != '-') {
      // Update previous note to include slide notation
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
      // No previous note, just add the slide as new note
      _addNote('$slideType$targetFret');
    }
  }

  void _addTechnique(String technique) {
    setState(() {
      int pos = _cursorPosition > 0 ? _cursorPosition - 1 : 0;
      for (int barIdx = 0; barIdx < _currentSection.bars.length; barIdx++) {
        final bar = _currentSection.bars[barIdx];
        if (pos < bar.columns.length) {
          final currentNote = bar.getNote(pos, _selectedStringIndex);
          if (currentNote != '-') {
            // Append technique to existing note (e.g., "5" becomes "5b")
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

  void _addBarLine() {
    setState(() {
      final newBar = TabMeasure(stringCount: _currentSection.stringCount);
      newBar.addColumn(); // Start with just one column
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

  void _addSection() {
    setState(() {
      _tab.sections.add(_tab.createEmptySection());
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

  void _editSectionLabel() {
    final controller = TextEditingController(text: _currentSection.label ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.label_outline, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              const Text('Section Label'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Verse, Chorus, Intro...',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) {
                final newLabel = controller.text.trim().isEmpty ? null : controller.text.trim();
                Navigator.pop(ctx);
                setState(() {
                  _currentSection.label = newLabel;
                  _hasChanges = true;
                });
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final newLabel = controller.text.trim().isEmpty ? null : controller.text.trim();
                Navigator.pop(ctx);
                setState(() {
                  _currentSection.label = newLabel;
                  _hasChanges = true;
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  void _setRepeatCount() {
    final controller = TextEditingController(text: _currentSection.repeatCount.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.repeat, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 12),
              const Text('Repeat Count'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '1-99',
                prefixIcon: Icon(Icons.numbers),
              ),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final newCount = (int.tryParse(controller.text) ?? 1).clamp(1, 99);
                Navigator.pop(ctx);
                setState(() {
                  _currentSection.repeatCount = newCount;
                  _hasChanges = true;
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  void _editStringTuning(int stringIndex) {
    final currentTuning = _currentSection.stringNames[stringIndex];
    final controller = TextEditingController(text: currentTuning);

    // Common tunings based on string position
    final commonTunings = <String>[];
    final stringCount = _currentSection.stringCount;

    // For bass (4-6 strings) and guitar (6-8 strings)
    if (stringCount <= 6 && stringIndex == stringCount - 1) {
      // Lowest string - common drop tunings
      commonTunings.addAll(['E', 'D', 'C', 'B', 'A']);
    } else if (stringCount <= 6 && stringIndex == stringCount - 2) {
      // Second lowest
      commonTunings.addAll(['A', 'G', 'F#', 'F']);
    } else {
      // Standard note options
      commonTunings.addAll(['E', 'B', 'G', 'D', 'A', 'C', 'F', 'F#']);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.music_note, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text('Edit String ${stringIndex + 1} Tuning'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: $currentTuning',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonTunings.map((tuning) => FilledButton.tonal(
                    onPressed: () {
                      controller.text = tuning;
                      _submitTuningChange(ctx, controller, stringIndex);
                    },
                    child: Text(tuning),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Custom tuning (e.g., D, C#)',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                  onSubmitted: (_) => _submitTuningChange(ctx, controller, stringIndex),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => _submitTuningChange(ctx, controller, stringIndex),
              child: const Text('Save'),
            ),
          ],
        );
      },
    ).then((_) => controller.dispose());
  }

  void _submitTuningChange(BuildContext ctx, TextEditingController controller, int stringIndex) {
    final newTuning = controller.text.trim();
    if (newTuning.isEmpty) {
      Navigator.pop(ctx);
      return;
    }

    Navigator.pop(ctx);
    setState(() {
      _currentSection.stringNames[stringIndex] = newTuning;
      _hasChanges = true;
    });
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
              Expanded(child: Text('Saved to Downloads')),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          _AppBarAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TabViewerScreen(tab: _tab)),
            ),
          ),
          _AppBarAction(
            icon: Icons.download_outlined,
            tooltip: 'Download',
            onPressed: _downloadTab,
          ),
          _AppBarAction(
            icon: Icons.share_outlined,
            tooltip: 'Share',
            onPressed: _exportTab,
          ),
          _AppBarAction(
            icon: _hasChanges ? Icons.save : Icons.save_outlined,
            tooltip: 'Save',
            highlighted: _hasChanges,
            onPressed: _saveTab,
          ),
          const SizedBox(width: 8),
        ],
      ),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSectionMenu(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.label_outline, color: Theme.of(context).colorScheme.primary),
              ),
              title: const Text('Edit Label'),
              subtitle: const Text('Change section name'),
              onTap: () {
                Navigator.pop(context);
                _selectedSectionIndex = index;
                _editSectionLabel();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.repeat, color: Theme.of(context).colorScheme.secondary),
              ),
              title: const Text('Set Repeats'),
              subtitle: const Text('How many times to repeat'),
              onTap: () {
                Navigator.pop(context);
                _selectedSectionIndex = index;
                _setRepeatCount();
              },
            ),
            if (_tab.sections.length > 1)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                ),
                title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                subtitle: const Text('Remove this section'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteSection(index);
                },
              ),
            const SizedBox(height: 8),
          ],
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
            // String names (selectable) - shows staged chord notes
            // Long press to edit tuning
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(stringNames.length, (stringIndex) {
                  final isSelected = stringIndex == _selectedStringIndex;
                  final hasChordNote = _chordNotes.containsKey(stringIndex);
                  final chordNote = _chordNotes[stringIndex];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStringIndex = stringIndex;
                      });
                    },
                    onLongPress: () => _editStringTuning(stringIndex),
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
            ),
            // Fretboard
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(maxFret + 1, (fret) {
                    final isMarkerFret = [3, 5, 7, 9, 12, 15, 17, 19, 21, 24].contains(fret);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(stringNames.length, (stringIndex) {
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
                      }),
                    );
                  }),
                ),
              ),
            ),
          ],
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
            // Chord mode toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (_chordMode && _chordNotes.isNotEmpty) {
                      // Turning off chord mode - commit the staged notes
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
            ),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            // Regular techniques
            ..._techniques.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TechniqueButton(
                    label: t,
                    onTap: () => _addTechnique(t),
                  ),
                )),
            // Slide techniques (with dialog)
            ..._slideTechniques.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TechniqueButton(
                    label: t,
                    tooltip: t == '/' ? 'Slide up' : 'Slide down',
                    onTap: () => _addSlide(t),
                  ),
                )),
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            _TechniqueButton(
              label: '|',
              tooltip: 'Add bar',
              isWide: true,
              onTap: _addBarLine,
            ),
            const SizedBox(width: 6),
            _TechniqueButton(
              label: '-',
              tooltip: 'Empty',
              onTap: () => _addNote('-'),
            ),
          ],
        ),
      ),
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
          // Label editor
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
                    Icon(
                      Icons.label_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
          // Repeats
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
          // Navigation controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _NavButton(
                  icon: Icons.keyboard_arrow_left,
                  onTap: () => _moveCursor(-1),
                ),
                const SizedBox(width: 8),
                _NavButton(
                  icon: Icons.keyboard_arrow_right,
                  onTap: () => _moveCursor(1),
                ),
                const SizedBox(width: 8),
                _NavButton(
                  icon: Icons.backspace_outlined,
                  onTap: _backspace,
                  isDestructive: true,
                ),
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
          ),
          // Tab content
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

  Widget _buildTabLines() {
    final section = _currentSection;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(section.stringCount, (stringIndex) {
            final stringName = section.stringNames[stringIndex];
            final isSelectedString = stringIndex == _selectedStringIndex;

            return Container(
              decoration: BoxDecoration(
                color: isSelectedString
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : null,
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
          }),
        ),
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
                color: isCursor
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : null,
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

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: highlighted
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: highlighted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TechniqueButton extends StatelessWidget {
  final String label;
  final String? tooltip;
  final VoidCallback onTap;
  final bool isWide;

  const _TechniqueButton({
    required this.label,
    this.tooltip,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: isWide ? 48 : 40,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: isDestructive
                ? Theme.of(context).colorScheme.error.withOpacity(0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDestructive
                  ? Theme.of(context).colorScheme.error.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
