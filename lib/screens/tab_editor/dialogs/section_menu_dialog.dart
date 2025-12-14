import 'package:flutter/material.dart';

enum SectionMenuAction { editLabel, setRepeats, delete }

class SectionMenuDialog {
  static Future<SectionMenuAction?> show({
    required BuildContext context,
    required bool canDelete,
  }) async {
    SectionMenuAction? result;

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.label_outline, color: Theme.of(ctx).colorScheme.primary),
              ),
              title: const Text('Edit Label'),
              subtitle: const Text('Change section name'),
              onTap: () {
                result = SectionMenuAction.editLabel;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.repeat, color: Theme.of(ctx).colorScheme.secondary),
              ),
              title: const Text('Set Repeats'),
              subtitle: const Text('How many times to repeat'),
              onTap: () {
                result = SectionMenuAction.setRepeats;
                Navigator.pop(ctx);
              },
            ),
            if (canDelete)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
                ),
                title: Text('Delete', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
                subtitle: const Text('Remove this section'),
                onTap: () {
                  result = SectionMenuAction.delete;
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return result;
  }
}
