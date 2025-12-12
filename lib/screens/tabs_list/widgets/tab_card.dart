import 'package:flutter/material.dart';
import '../../../models/tab_model.dart';

class TabCard extends StatelessWidget {
  final GuitarTab tab;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const TabCard({
    super.key,
    required this.tab,
    required this.onTap,
    required this.onView,
    required this.onDelete,
  });

  String _getTabPreview(TabSection section, int stringIndex) {
    if (section.bars.isEmpty) return '----------';
    final bar = section.bars.first;
    String preview = '';
    for (int i = 0; i < bar.columns.length && preview.length < 20; i++) {
      if (stringIndex < bar.columns[i].notes.length) {
        preview += bar.columns[i].notes[stringIndex];
      }
    }
    return preview.isEmpty ? '----------' : preview;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildPreview(context),
              _buildTimestamp(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            tab.songName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          onSelected: (value) {
            if (value == 'view') onView();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined),
                  SizedBox(width: 12),
                  Text('Preview'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (tab.sections.isEmpty || tab.sections.first.bars.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              tab.sections.first.stringCount,
              (i) {
                final section = tab.sections.first;
                return Text(
                  '${section.stringNames[i]}|${_getTabPreview(section, i)}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(tab.modifiedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
