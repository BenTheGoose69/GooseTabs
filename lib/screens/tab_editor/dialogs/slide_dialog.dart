import 'package:flutter/material.dart';

class SlideDialog {
  static Future<String?> show({
    required BuildContext context,
    required String slideType,
    required String previousNote,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _SlideDialogContent(
          slideType: slideType,
          previousNote: previousNote,
        );
      },
    );
  }
}

class _SlideDialogContent extends StatefulWidget {
  final String slideType;
  final String previousNote;

  const _SlideDialogContent({
    required this.slideType,
    required this.previousNote,
  });

  @override
  State<_SlideDialogContent> createState() => _SlideDialogContentState();
}

class _SlideDialogContentState extends State<_SlideDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
                  child: Text(
                    widget.slideType,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.slideType == '/' ? 'Slide Up' : 'Slide Down',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Target fret (0-24)',
                prefixIcon: const Icon(Icons.music_note),
                prefixText: widget.previousNote != '-'
                    ? '${widget.previousNote}${widget.slideType}'
                    : widget.slideType,
              ),
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
