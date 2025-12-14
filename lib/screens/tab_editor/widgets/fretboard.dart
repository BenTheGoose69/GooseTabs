import 'package:flutter/material.dart';

class Fretboard extends StatelessWidget {
  final List<String> stringNames;
  final int selectedStringIndex;
  final Map<int, String> chordNotes;
  final ValueChanged<int> onStringSelected;
  final ValueChanged<int> onTuningTap;
  final Function(int stringIndex, int fret) onFretTap;

  const Fretboard({
    super.key,
    required this.stringNames,
    required this.selectedStringIndex,
    required this.chordNotes,
    required this.onStringSelected,
    required this.onTuningTap,
    required this.onFretTap,
  });

  static const int maxFret = 24;
  static const int deadNote = -1; // "x" for muted/dead notes

  @override
  Widget build(BuildContext context) {
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
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _TuningSettingsColumn(
              stringNames: stringNames,
              onTuningTap: onTuningTap,
            ),
            _StringLabelsColumn(
              stringNames: stringNames,
              selectedStringIndex: selectedStringIndex,
              chordNotes: chordNotes,
              onStringSelected: onStringSelected,
            ),
            Expanded(
              child: _FretGrid(
                stringNames: stringNames,
                selectedStringIndex: selectedStringIndex,
                chordNotes: chordNotes,
                onFretTap: onFretTap,
                onStringSelected: onStringSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TuningSettingsColumn extends StatelessWidget {
  final List<String> stringNames;
  final ValueChanged<int> onTuningTap;

  const _TuningSettingsColumn({
    required this.stringNames,
    required this.onTuningTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(stringNames.length, (stringIndex) {
          return GestureDetector(
            onTap: () => onTuningTap(stringIndex),
            child: Container(
              width: 28,
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                Icons.settings,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StringLabelsColumn extends StatelessWidget {
  final List<String> stringNames;
  final int selectedStringIndex;
  final Map<int, String> chordNotes;
  final ValueChanged<int> onStringSelected;

  const _StringLabelsColumn({
    required this.stringNames,
    required this.selectedStringIndex,
    required this.chordNotes,
    required this.onStringSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(stringNames.length, (stringIndex) {
          final isSelected = stringIndex == selectedStringIndex;
          final hasChordNote = chordNotes.containsKey(stringIndex);
          final chordNote = chordNotes[stringIndex];

          return GestureDetector(
            onTap: () => onStringSelected(stringIndex),
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
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
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
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _FretGrid extends StatelessWidget {
  final List<String> stringNames;
  final int selectedStringIndex;
  final Map<int, String> chordNotes;
  final Function(int stringIndex, int fret) onFretTap;
  final ValueChanged<int> onStringSelected;

  const _FretGrid({
    required this.stringNames,
    required this.selectedStringIndex,
    required this.chordNotes,
    required this.onFretTap,
    required this.onStringSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Frets 0-24 plus dead note (x) at the end
    final fretValues = [
      ...List.generate(Fretboard.maxFret + 1, (i) => i),
      Fretboard.deadNote,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: fretValues.map((fret) {
          final isMarkerFret = [3, 5, 7, 9, 12, 15, 17, 19, 21, 24].contains(fret);
          final isDeadNote = fret == Fretboard.deadNote;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(stringNames.length, (stringIndex) {
              return _FretCell(
                stringIndex: stringIndex,
                fret: fret,
                isMarkerFret: isMarkerFret,
                isDeadNote: isDeadNote,
                isSelectedRow: stringIndex == selectedStringIndex,
                hasChordNote: chordNotes.containsKey(stringIndex),
                onTap: () {
                  onStringSelected(stringIndex);
                  onFretTap(stringIndex, fret);
                },
              );
            }),
          );
        }).toList(),
      ),
    );
  }
}

class _FretCell extends StatelessWidget {
  final int stringIndex;
  final int fret;
  final bool isMarkerFret;
  final bool isDeadNote;
  final bool isSelectedRow;
  final bool hasChordNote;
  final VoidCallback onTap;

  const _FretCell({
    required this.stringIndex,
    required this.fret,
    required this.isMarkerFret,
    required this.isDeadNote,
    required this.isSelectedRow,
    required this.hasChordNote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: hasChordNote
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2)
              : isSelectedRow
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                  : isDeadNote
                      ? Theme.of(context).colorScheme.error.withValues(alpha: 0.08)
                      : isMarkerFret
                          ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08)
                          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasChordNote
                ? Theme.of(context).colorScheme.secondary
                : isDeadNote
                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: hasChordNote ? 1.5 : 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          isDeadNote ? 'x' : fret.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isDeadNote || isMarkerFret ? FontWeight.w600 : FontWeight.normal,
            color: hasChordNote
                ? Theme.of(context).colorScheme.secondary
                : isDeadNote
                    ? Theme.of(context).colorScheme.error
                    : isSelectedRow
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
