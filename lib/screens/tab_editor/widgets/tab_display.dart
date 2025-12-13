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
                  child: _TabLines(
                    section: section,
                    cursorPosition: cursorPosition,
                    selectedStringIndex: selectedStringIndex,
                    onCellTap: onCellTap,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabLines extends StatelessWidget {
  final TabSection section;
  final int cursorPosition;
  final int selectedStringIndex;
  final Function(int position, int stringIndex) onCellTap;

  const _TabLines({
    required this.section,
    required this.cursorPosition,
    required this.selectedStringIndex,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate cursor column position and width
    double cursorX = 24 + 8; // String name width (24) + bar line text (~8)
    double cursorWidth = 16;
    int globalPos = 0;

    for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
      final bar = section.bars[barIdx];
      for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
        // Calculate max width for this column
        int maxLen = 1;
        for (int s = 0; s < section.stringCount; s++) {
          final n = bar.getNote(colIdx, s);
          if (n.length > maxLen) maxLen = n.length;
        }
        final colWidth = maxLen * 10.0 + 6;

        if (globalPos == cursorPosition) {
          cursorWidth = colWidth;
          break;
        }
        cursorX += colWidth;
        globalPos++;
      }
      if (globalPos == cursorPosition) break;
      cursorX += 8; // Bar separator text width (~8)
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // The actual tab content (rendered first so stripe is on top)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(section.stringCount, (stringIndex) {
                return _StringLine(
                  section: section,
                  stringIndex: stringIndex,
                  selectedStringIndex: selectedStringIndex,
                  onCellTap: onCellTap,
                );
              }),
            ),
            // The stripe overlay on top
            Positioned(
              left: cursorX,
              top: 0,
              bottom: 0,
              width: cursorWidth,
              child: IgnorePointer(
                child: Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StringLine extends StatelessWidget {
  final TabSection section;
  final int stringIndex;
  final int selectedStringIndex;
  final Function(int position, int stringIndex) onCellTap;

  const _StringLine({
    required this.section,
    required this.stringIndex,
    required this.selectedStringIndex,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final stringName = section.stringNames[stringIndex];
    final isSelectedString = stringIndex == selectedStringIndex;

    return Container(
      decoration: BoxDecoration(
        color: isSelectedString ? Theme.of(context).colorScheme.primary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          Text(
            '|',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          ..._buildNoteWidgets(context),
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

  List<Widget> _buildNoteWidgets(BuildContext context) {
    List<Widget> widgets = [];
    int globalPos = 0;

    for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
      final bar = section.bars[barIdx];

      for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
        final note = bar.getNote(colIdx, stringIndex);
        final currentPos = globalPos;

        int maxLen = 1;
        for (int s = 0; s < section.stringCount; s++) {
          final n = bar.getNote(colIdx, s);
          if (n.length > maxLen) maxLen = n.length;
        }

        widgets.add(
          GestureDetector(
            onTap: () => onCellTap(currentPos, stringIndex),
            child: Container(
              width: maxLen * 10.0 + 6,
              height: 24,
              alignment: Alignment.center,
              child: Text(
                note,
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
