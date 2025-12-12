import 'package:flutter/material.dart';

class SectionLabelDialog {
  static Future<String?> show({
    required BuildContext context,
    String? currentLabel,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _SectionLabelDialogContent(currentLabel: currentLabel);
      },
    );
  }
}

class _SectionLabelDialogContent extends StatefulWidget {
  final String? currentLabel;

  const _SectionLabelDialogContent({this.currentLabel});

  @override
  State<_SectionLabelDialogContent> createState() => _SectionLabelDialogContentState();
}

class _SectionLabelDialogContentState extends State<_SectionLabelDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLabel ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Text(
                  'Section Label',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Verse, Chorus, Intro...',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(widget.currentLabel),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
