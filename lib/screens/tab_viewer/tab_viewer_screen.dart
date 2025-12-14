import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tab_model.dart';
import '../../services/storage_service.dart';
import 'widgets/action_button.dart';
import 'widgets/info_tag.dart';
import 'widgets/date_info.dart';

class TabViewerScreen extends StatelessWidget {
  final GuitarTab tab;

  const TabViewerScreen({super.key, required this.tab});

  Future<void> _copyToClipboard(BuildContext context) async {
    final text = tab.toTabFormat();
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 12),
              const Text('Tab copied to clipboard!'),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _exportTab(BuildContext context) async {
    await StorageService.exportTabToFile(tab);
  }

  Future<void> _downloadTab(BuildContext context) async {
    final path = await StorageService.downloadTabToDownloads(tab);
    if (context.mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Saved to Downloads')),
            ],
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _hasUsedSymbols() {
    final allContent = tab.sections
        .expand((s) => s.bars)
        .expand((b) => b.columns)
        .expand((c) => c.notes)
        .join();

    for (final symbol in tab.legend.keys) {
      if (allContent.contains(symbol)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(tab.songName),
        actions: [
          ActionButton(
            icon: Icons.copy_outlined,
            tooltip: 'Copy to Clipboard',
            onTap: () => _copyToClipboard(context),
          ),
          ActionButton(
            icon: Icons.download_outlined,
            tooltip: 'Download',
            onTap: () => _downloadTab(context),
          ),
          ActionButton(
            icon: Icons.share_outlined,
            tooltip: 'Share',
            onTap: () => _exportTab(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTabContent(context),
            if (_hasUsedSymbols()) ...[
              const SizedBox(height: 20),
              _buildLegend(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tab.songName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InfoTag(
                            icon: Icons.tune,
                            label: tab.tuning.split(' ').first,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          InfoTag(
                            icon: Icons.layers,
                            label: '${tab.sections.length} sections',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  DateInfo(
                    icon: Icons.add_circle_outline,
                    label: 'Created',
                    date: _formatDate(tab.createdAt),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                  DateInfo(
                    icon: Icons.edit_outlined,
                    label: 'Modified',
                    date: _formatDate(tab.modifiedAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tab.sections.map((section) => _buildSection(context, section)).toList(),
    );
  }

  Widget _buildSection(BuildContext context, TabSection section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.label != null && section.label!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            section.label!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (section.repeatCount > 1) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 14,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'x${section.repeatCount}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(section.stringCount, (stringIdx) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                          children: _buildColoredLine(context, section, stringIdx),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build colored text spans for a section line
  List<TextSpan> _buildColoredLine(BuildContext context, TabSection section, int stringIdx) {
    final spans = <TextSpan>[];
    final scheme = Theme.of(context).colorScheme;

    // Colors
    final stringNameColor = scheme.primary;
    final barLineColor = scheme.outline;
    final dashColor = scheme.onSurface.withOpacity(0.3);
    final fretColor = scheme.primary;
    const techniqueColor = Colors.cyan;
    const slideColor = Colors.orange;
    const vibratoColor = Colors.purple;
    const harmonicColor = Colors.tealAccent;
    final repeatColor = scheme.secondary;

    // Find max string name length for alignment
    int maxNameLen = 1;
    for (final name in section.stringNames) {
      if (name.length > maxNameLen) maxNameLen = name.length;
    }

    // String name (padded for alignment)
    var stringName = section.stringNames[stringIdx];
    while (stringName.length < maxNameLen) {
      stringName = '$stringName ';
    }
    spans.add(TextSpan(
      text: stringName,
      style: TextStyle(color: stringNameColor, fontWeight: FontWeight.bold),
    ));
    spans.add(TextSpan(text: '|', style: TextStyle(color: barLineColor)));

    for (int barIdx = 0; barIdx < section.bars.length; barIdx++) {
      final bar = section.bars[barIdx];

      for (int colIdx = 0; colIdx < bar.columns.length; colIdx++) {
        final column = bar.columns[colIdx];
        final columnWidth = column.width;

        var note = column.notes[stringIdx];

        // Pad note with dashes to match column width
        while (note.length < columnWidth) {
          note += '-';
        }

        // Color each character
        for (int i = 0; i < note.length; i++) {
          final char = note[i];
          Color color;
          if (char == '-') {
            color = dashColor;
          } else if (RegExp(r'\d').hasMatch(char)) {
            color = fretColor;
          } else if ('hpbt'.contains(char)) {
            color = techniqueColor;
          } else if (char == '/' || char == '\\') {
            color = slideColor;
          } else if (char == '~') {
            color = vibratoColor;
          } else if (char == '+') {
            color = harmonicColor;
          } else {
            color = fretColor;
          }
          spans.add(TextSpan(text: char, style: TextStyle(color: color)));
        }

        // Add separator dash after each column
        spans.add(TextSpan(text: '-', style: TextStyle(color: dashColor)));
      }
      spans.add(TextSpan(text: '|', style: TextStyle(color: barLineColor)));
    }

    // Repeat marker on last string
    if (stringIdx == section.stringCount - 1 && section.repeatCount > 1) {
      spans.add(TextSpan(
        text: ' x${section.repeatCount}',
        style: TextStyle(color: repeatColor, fontWeight: FontWeight.bold),
      ));
    }

    return spans;
  }

  Widget _buildLegend(BuildContext context) {
    final allContent = tab.sections
        .expand((s) => s.bars)
        .expand((b) => b.columns)
        .expand((c) => c.notes)
        .join();

    final usedSymbols = tab.legend.entries
        .where((e) => allContent.contains(e.key))
        .toList();

    if (usedSymbols.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Legend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: usedSymbols
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                    Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                e.key,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              e.value,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
