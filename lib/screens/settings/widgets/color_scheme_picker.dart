import 'package:flutter/material.dart';
import '../../../services/settings_service.dart';

class ColorSchemePicker extends StatelessWidget {
  final ColorSchemeType selectedScheme;
  final ValueChanged<ColorSchemeType> onSchemeSelected;

  const ColorSchemePicker({
    super.key,
    required this.selectedScheme,
    required this.onSchemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: ColorSchemeType.values.length,
      itemBuilder: (context, index) {
        final scheme = ColorSchemeType.values[index];
        final isSelected = scheme == selectedScheme;

        return GestureDetector(
          onTap: () => onSchemeSelected(scheme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Column(
                children: [
                  Expanded(
                    child: Container(color: scheme.primary),
                  ),
                  Expanded(
                    child: Container(color: scheme.secondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ColorSchemeDialog extends StatelessWidget {
  final ColorSchemeType selectedScheme;
  final ValueChanged<ColorSchemeType> onSchemeSelected;

  const ColorSchemeDialog({
    super.key,
    required this.selectedScheme,
    required this.onSchemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Scheme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your accent colors',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),
            ColorSchemePicker(
              selectedScheme: selectedScheme,
              onSchemeSelected: (scheme) {
                onSchemeSelected(scheme);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                selectedScheme.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selectedScheme.primary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
