import 'package:flutter/material.dart';

class SectionLabelDialog {
  static Future<String?> show({
    required BuildContext context,
    String? currentLabel,
  }) async {
    final controller = TextEditingController(text: currentLabel ?? '');
    String? result;
    bool submitted = false;

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
                child: Icon(Icons.label_outline, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              const Text('Section Label'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Verse, Chorus, Intro...',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) {
                submitted = true;
                result = controller.text.trim().isEmpty ? null : controller.text.trim();
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
                submitted = true;
                result = controller.text.trim().isEmpty ? null : controller.text.trim();
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return submitted ? result : currentLabel;
  }
}
