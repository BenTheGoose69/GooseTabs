import 'package:flutter/material.dart';

class TuningDialog {
  static Future<String?> show({
    required BuildContext context,
    required int stringIndex,
    required String currentTuning,
    required int stringCount,
  }) async {
    // Common tunings based on string position
    final commonTunings = <String>[];

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

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _TuningDialogContent(
          stringIndex: stringIndex,
          currentTuning: currentTuning,
          commonTunings: commonTunings,
        );
      },
    );
  }
}

class _TuningDialogContent extends StatefulWidget {
  final int stringIndex;
  final String currentTuning;
  final List<String> commonTunings;

  const _TuningDialogContent({
    required this.stringIndex,
    required this.currentTuning,
    required this.commonTunings,
  });

  @override
  State<_TuningDialogContent> createState() => _TuningDialogContentState();
}

class _TuningDialogContentState extends State<_TuningDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTuning);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? presetTuning]) {
    final result = presetTuning ?? _controller.text.trim();
    if (result.isNotEmpty) {
      Navigator.of(context).pop(result);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.music_note, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text('Edit String ${widget.stringIndex + 1} Tuning'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${widget.currentTuning}',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.commonTunings
                  .map((tuning) => FilledButton.tonal(
                        onPressed: () => _submit(tuning),
                        child: Text(tuning),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Custom tuning (e.g., D, C#)',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _submit(),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
