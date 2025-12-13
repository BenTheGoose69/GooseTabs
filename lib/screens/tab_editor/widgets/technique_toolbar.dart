import 'package:flutter/material.dart';
import 'technique_button.dart';

class TechniqueToolbar extends StatelessWidget {
  final bool chordMode;
  final int chordNotesCount;
  final VoidCallback onChordModeToggle;
  final ValueChanged<String> onTechniqueTap;
  final ValueChanged<String> onSlideTap;
  final VoidCallback onHarmonicTap;
  final VoidCallback onBarLineTap;
  final VoidCallback onDashTap;

  const TechniqueToolbar({
    super.key,
    required this.chordMode,
    required this.chordNotesCount,
    required this.onChordModeToggle,
    required this.onTechniqueTap,
    required this.onSlideTap,
    required this.onHarmonicTap,
    required this.onBarLineTap,
    required this.onDashTap,
  });

  @override
  Widget build(BuildContext context) {
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
            _ChordModeButton(
              isActive: chordMode,
              notesCount: chordNotesCount,
              onTap: onChordModeToggle,
            ),
            _buildDivider(context),
            // Techniques in order: h, p, b, t, /, \, ◆, ~
            _buildTechniqueButton('h', 'Hammer on', () => onTechniqueTap('h')),
            _buildTechniqueButton('p', 'Pull off', () => onTechniqueTap('p')),
            _buildTechniqueButton('b', 'Bend', () => onTechniqueTap('b')),
            _buildTechniqueButton('t', 'Tap', () => onTechniqueTap('t')),
            _buildTechniqueButton('/', 'Slide up', () => onSlideTap('/')),
            _buildTechniqueButton('\\', 'Slide down', () => onSlideTap('\\')),
            _buildTechniqueButton('◆', 'Harmonic', onHarmonicTap),
            _buildTechniqueButton('~', 'Vibrato', () => onTechniqueTap('~')),
            _buildDivider(context),
            TechniqueButton(label: '|', tooltip: 'Add bar', isWide: true, onTap: onBarLineTap),
            const SizedBox(width: 6),
            TechniqueButton(label: '-', tooltip: 'Empty', onTap: onDashTap),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniqueButton(String label, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TechniqueButton(label: label, tooltip: tooltip, onTap: onTap),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
    );
  }
}

class _ChordModeButton extends StatelessWidget {
  final bool isActive;
  final int notesCount;
  final VoidCallback onTap;

  const _ChordModeButton({
    required this.isActive,
    required this.notesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.layers,
                  size: 16,
                  color: isActive
                      ? Colors.black
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive && notesCount > 0
                      ? 'Add ($notesCount)'
                      : 'Chord',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
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
}
