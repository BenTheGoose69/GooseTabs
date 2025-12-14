import 'package:flutter/material.dart';
import '../../../models/tab_model.dart';

class SectionSelector extends StatelessWidget {
  final List<TabSection> sections;
  final int selectedIndex;
  final ValueChanged<int> onSectionSelected;
  final VoidCallback onAddSection;
  final ValueChanged<int> onSectionLongPress;

  const SectionSelector({
    super.key,
    required this.sections,
    required this.selectedIndex,
    required this.onSectionSelected,
    required this.onAddSection,
    required this.onSectionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: sections.length + 1,
              itemBuilder: (context, index) {
                if (index == sections.length) {
                  return _AddSectionButton(onTap: onAddSection);
                }
                return _SectionChip(
                  section: sections[index],
                  index: index,
                  isSelected: index == selectedIndex,
                  onTap: () => onSectionSelected(index),
                  onLongPress: () => onSectionLongPress(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSectionButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddSectionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final TabSection section;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SectionChip({
    required this.section,
    required this.index,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
            ),
            alignment: Alignment.center,
            child: Text(
              section.label ?? 'Section ${index + 1}',
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
