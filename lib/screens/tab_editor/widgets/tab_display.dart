import 'package:flutter/material.dart';
import '../../../models/tab_model.dart';
import 'nav_button.dart';

class TabDisplay extends StatelessWidget {
  final TabSection section;
  final int cursorPosition;
  final int selectedStringIndex;
  final int totalColumns;
  final ScrollController scrollController;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onBackspace;
  final Function(int position, int stringIndex) onCellTap;

  const TabDisplay({
    super.key,
    required this.section,
    required this.cursorPosition,
    required this.selectedStringIndex,
    required this.totalColumns,
    required this.scrollController,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onBackspace,
    required this.onCellTap,
  });

  /// Build colored text spans for the section
  List<TextSpan> _buildColoredLine(BuildContext context, int stringIdx) {
    final spans = <TextSpan>[];
    final colors = _NoteColors.from(context);
    int globalCol = 0;

    // Find max string name length for alignment
    int maxNameLen = 1;
    for (final name in section.stringNames) {
      if (name.length > maxNameLen) maxNameLen = name.length;
    }

    // String name (padded for alignment)
    var stringName = section.stringNames[stringIdx];
    while (stringName.length < maxNameLen) {
      stringName = '$stringName ';
    }
    spans.add(TextSpan(
      text: stringName,
      style: TextStyle(color: colors.stringName, fontWeight: FontWeight.bold),
    ));

    spans.add(TextSpan(text: '|', style: TextStyle(color: colors.barLine)));

    for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
      final bar = section.bars[barIdx];

      for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
        final column = bar.columns[colIdx];
        final columnWidth = column.width;

        var note = column.notes[stringIdx];

        // Pad note with dashes to match column width
        while (note.length < columnWidth) {
          note += '-';
        }

        // Check if this is the cursor column
        final isCursorColumn = globalCol == cursorPosition;

        // Color the note based on content, with cursor highlight
        spans.add(_colorizeNote(note, colors, isCursorColumn));

        // Add separator dash after each column
        spans.add(TextSpan(
          text: '-',
          style: TextStyle(
            color: colors.dash,
            backgroundColor: isCursorColumn ? colors.cursorBg : null,
          ),
        ));

        globalCol++;
      }
      spans.add(TextSpan(text: '|', style: TextStyle(color: colors.barLine)));
    }

    // Repeat marker on last string
    if (stringIdx == section.stringCount - 1 && section.repeatCount > 1) {
      spans.add(TextSpan(
        text: ' x${section.repeatCount}',
        style: TextStyle(color: colors.repeat, fontWeight: FontWeight.bold),
      ));
    }

    return spans;
  }

  TextSpan _colorizeNote(String note, _NoteColors colors, bool isCursorColumn) {
    if (note.replaceAll('-', '').isEmpty) {
      // All dashes
      return TextSpan(
        text: note,
        style: TextStyle(
          color: colors.dash,
          backgroundColor: isCursorColumn ? colors.cursorBg : null,
        ),
      );
    }

    // Build spans for mixed content (e.g., "5h6", "12-", "h3", "/6")
    final spans = <TextSpan>[];
    for (int i = 0; i < note.length; i++) {
      final char = note[i];
      Color color;
      if (char == '-') {
        color = colors.dash;
      } else if (RegExp(r'\d').hasMatch(char)) {
        color = colors.fret;
      } else if ('hpbt'.contains(char)) {
        color = colors.technique;
      } else if (char == '/' || char == '\\') {
        color = colors.slide;
      } else if (char == '~') {
        color = colors.vibrato;
      } else if (char == '+') {
        color = colors.harmonic;
      } else {
        color = colors.fret;
      }
      spans.add(TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          backgroundColor: isCursorColumn ? colors.cursorBg : null,
        ),
      ));
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            _NavigationControls(
              cursorPosition: cursorPosition,
              totalColumns: totalColumns,
              onMoveLeft: onMoveLeft,
              onMoveRight: onMoveRight,
              onBackspace: onBackspace,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(section.stringCount, (stringIdx) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                                children: _buildColoredLine(context, stringIdx),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteColors {
  final Color stringName;
  final Color barLine;
  final Color dash;
  final Color fret;
  final Color technique;
  final Color slide;
  final Color vibrato;
  final Color harmonic;
  final Color repeat;
  final Color cursorBg;

  _NoteColors({
    required this.stringName,
    required this.barLine,
    required this.dash,
    required this.fret,
    required this.technique,
    required this.slide,
    required this.vibrato,
    required this.harmonic,
    required this.repeat,
    required this.cursorBg,
  });

  factory _NoteColors.from(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _NoteColors(
      stringName: scheme.primary,
      barLine: scheme.outline,
      dash: scheme.onSurface.withValues(alpha: 0.3),
      fret: scheme.primary,
      technique: Colors.cyan,
      slide: Colors.orange,
      vibrato: Colors.purple,
      harmonic: Colors.tealAccent,
      repeat: scheme.secondary,
      cursorBg: scheme.primary.withValues(alpha: 0.3),
    );
  }
}

class _NavigationControls extends StatelessWidget {
  final int cursorPosition;
  final int totalColumns;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onBackspace;

  const _NavigationControls({
    required this.cursorPosition,
    required this.totalColumns,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          NavButton(icon: Icons.keyboard_arrow_left, onTap: onMoveLeft),
          const SizedBox(width: 8),
          NavButton(icon: Icons.keyboard_arrow_right, onTap: onMoveRight),
          const SizedBox(width: 8),
          NavButton(icon: Icons.backspace_outlined, onTap: onBackspace, isDestructive: true),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Col ${cursorPosition + 1} / $totalColumns',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

