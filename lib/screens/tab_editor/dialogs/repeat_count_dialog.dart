import 'package:flutter/material.dart';

class RepeatCountDialog {
  static Future<int?> show({
    required BuildContext context,
    required int currentCount,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _RepeatCountDialogContent(currentCount: currentCount);
      },
    );
  }
}

class _RepeatCountDialogContent extends StatefulWidget {
  final int currentCount;

  const _RepeatCountDialogContent({required this.currentCount});

  @override
  State<_RepeatCountDialogContent> createState() => _RepeatCountDialogContentState();
}

class _RepeatCountDialogContentState extends State<_RepeatCountDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentCount.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final count = (int.tryParse(_controller.text) ?? 1).clamp(1, 99);
    Navigator.of(context).pop(count);
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
                    color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.repeat, color: theme.colorScheme.secondary),
                ),
                const SizedBox(width: 12),
                Text(
                  'Repeat Count',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '1-99',
                prefixIcon: Icon(Icons.numbers),
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
