import 'package:flutter/material.dart';

class SlideDialog {
  static Future<String?> show({
    required BuildContext context,
    required String slideType,
    required String previousNote,
  }) async {
    final controller = TextEditingController();
    String? result;

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
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slideType,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
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
              onSubmitted: (_) {
                result = controller.text.trim();
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
                result = controller.text.trim();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }
}
