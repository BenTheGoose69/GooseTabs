import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tab_model.dart';
import '../../services/storage_service.dart';
import 'widgets/action_button.dart';
import 'widgets/info_tag.dart';
import 'widgets/date_info.dart';

class TabViewerScreen extends StatefulWidget {
  final GuitarTab tab;

  const TabViewerScreen({super.key, required this.tab});

  @override
  State<TabViewerScreen> createState() => _TabViewerScreenState();
}

class _TabViewerScreenState extends State<TabViewerScreen> {
  late TextEditingController _structureController;

  @override
  void initState() {
    super.initState();
    // Load saved structure or generate default from section labels
    final initialText = widget.tab.songStructure ?? _getDefaultStructure();
    _structureController = TextEditingController(text: initialText);
    _structureController.addListener(_onStructureChanged);
  }

  @override
  void dispose() {
    _structureController.removeListener(_onStructureChanged);
    _structureController.dispose();
    super.dispose();
  }

  void _onStructureChanged() {
    // Save structure to tab when changed
    widget.tab.songStructure = _structureController.text;
    StorageService.saveTab(widget.tab);
  }

  /// Returns section names, one per line
  String _getDefaultStructure() {
    final sectionNames = <String>[];
    for (final section in widget.tab.sections) {
      if (section.label?.isNotEmpty == true) {
        sectionNames.add(section.label!);
      }
    }
    return sectionNames.join('\n');
  }

  /// Get unique section labels for quick-insert buttons
  List<String> _getUniqueSectionLabels() {
    final labels = <String>{};
    for (final section in widget.tab.sections) {
      if (section.label?.isNotEmpty == true) {
        labels.add(section.label!);
      }
    }
    return labels.toList();
  }

  void _insertSectionName(String name) {
    final text = _structureController.text;
    final selection = _structureController.selection;

    final newText = text.replaceRange(
      selection.baseOffset,
      selection.extentOffset,
      name,
    );

    _structureController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + name.length,
      ),
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final text = _getExportText();
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
    await StorageService.exportTabToFileWithStructure(widget.tab, _structureController.text);
  }

  Future<void> _downloadTab(BuildContext context) async {
    final path = await StorageService.downloadTabToDownloadsWithStructure(widget.tab, _structureController.text);
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

  String _getExportText() {
    return widget.tab.toTabFormatWithStructure(_structureController.text);
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _hasUsedSymbols() {
    final allContent = widget.tab.sections
        .expand((s) => s.bars)
        .expand((b) => b.columns)
        .expand((c) => c.notes)
        .join();

    for (final symbol in widget.tab.legend.keys) {
      if (allContent.contains(symbol)) {
        return true;
      }
    }
    return false;
  }

  bool _hasLabeledSections() {
    return widget.tab.sections.any((s) => s.label?.isNotEmpty == true);
  }

  void _resetStructure() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Structure'),
        content: const Text('Reset the song structure to the default based on section labels?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _structureController.text = _getDefaultStructure();
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
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
        title: Text(widget.tab.songName),
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
            if (_hasLabeledSections()) ...[
              const SizedBox(height: 16),
              _buildSongStructure(context),
            ],
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
                        widget.tab.songName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          InfoTag(
                            icon: Icons.tune,
                            label: widget.tab.tuning.split(' ').first,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          InfoTag(
                            icon: Icons.layers,
                            label: '${widget.tab.sections.length} sections',
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
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  DateInfo(
                    icon: Icons.add_circle_outline,
                    label: 'Created',
                    date: _formatDate(widget.tab.createdAt),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  DateInfo(
                    icon: Icons.edit_outlined,
                    label: 'Modified',
                    date: _formatDate(widget.tab.modifiedAt),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongStructure(BuildContext context) {
    final sectionLabels = _getUniqueSectionLabels();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.format_list_bulleted,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Song Structure',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 20,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  tooltip: 'Reset to original',
                  onPressed: _resetStructure,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Text field for structure
            TextField(
              controller: _structureController,
              maxLines: 10,
              minLines: 5,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'e.g., Intro -> Verse -> Chorus -> Verse -> Chorus -> Outro',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.outline,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            if (sectionLabels.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Quick insert:',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sectionLabels.map((label) => _buildQuickInsertChip(context, label)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsertChip(BuildContext context, String label) {
    return InkWell(
      onTap: () => _insertSectionName(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveSectionUp(int index) {
    if (index <= 0) return;
    setState(() {
      final section = widget.tab.sections.removeAt(index);
      widget.tab.sections.insert(index - 1, section);
    });
    StorageService.saveTab(widget.tab);
  }

  void _moveSectionDown(int index) {
    if (index >= widget.tab.sections.length - 1) return;
    setState(() {
      final section = widget.tab.sections.removeAt(index);
      widget.tab.sections.insert(index + 1, section);
    });
    StorageService.saveTab(widget.tab);
  }

  Widget _buildTabContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        widget.tab.sections.length,
        (index) => _buildSection(context, widget.tab.sections[index], index),
      ),
    );
  }

  Widget _buildSection(BuildContext context, TabSection section, int index) {
    final isFirst = index == 0;
    final isLast = index == widget.tab.sections.length - 1;
    final showReorderButtons = widget.tab.sections.length > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (section.label != null && section.label!.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
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
                  )
                else
                  const Spacer(),
                if (showReorderButtons) ...[
                  IconButton(
                    icon: Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: isFirst
                          ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: isFirst ? null : () => _moveSectionUp(index),
                    tooltip: 'Move up',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: isLast
                          ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                          : Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: isLast ? null : () => _moveSectionDown(index),
                    tooltip: 'Move down',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            if (section.label != null && section.label!.isNotEmpty)
              const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
    final dashColor = scheme.onSurface.withValues(alpha: 0.3);
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
    final allContent = widget.tab.sections
        .expand((s) => s.bars)
        .expand((b) => b.columns)
        .expand((c) => c.notes)
        .join();

    final usedSymbols = widget.tab.legend.entries
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
                                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
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
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
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
