import 'package:flutter/material.dart';

class SectionOptions extends StatelessWidget {
  final String? sectionLabel;
  final int repeatCount;
  final VoidCallback onLabelTap;
  final VoidCallback onRepeatTap;

  const SectionOptions({
    super.key,
    required this.sectionLabel,
    required this.repeatCount,
    required this.onLabelTap,
    required this.onRepeatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LabelButton(
              label: sectionLabel,
              onTap: onLabelTap,
            ),
          ),
          const SizedBox(width: 12),
          _RepeatButton(
            repeatCount: repeatCount,
            onTap: onRepeatTap,
          ),
        ],
      ),
    );
  }
}

class _LabelButton extends StatelessWidget {
  final String? label;
  final VoidCallback onTap;

  const _LabelButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.label_outline, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label ?? 'Add section label...',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: label == null
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  final int repeatCount;
  final VoidCallback onTap;

  const _RepeatButton({
    required this.repeatCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = repeatCount > 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.repeat,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Text(
              'x$repeatCount',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
