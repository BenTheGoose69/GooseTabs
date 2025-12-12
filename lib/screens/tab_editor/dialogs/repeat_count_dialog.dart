import 'package:flutter/material.dart';

class RepeatCountDialog {
  static Future<int?> show({
    required BuildContext context,
    required int currentCount,
  }) async {
    final controller = TextEditingController(text: currentCount.toString());
    int? result;

    await showDialog(
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
              onSubmitted: (_) {
                result = (int.tryParse(controller.text) ?? 1).clamp(1, 99);
                Navigator.pop(ctx);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                result = (int.tryParse(controller.text) ?? 1).clamp(1, 99);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }
}
