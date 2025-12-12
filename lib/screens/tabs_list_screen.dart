import 'package:flutter/material.dart';
import '../models/tab_model.dart';
import '../services/storage_service.dart';
import 'tab_editor_screen.dart';
import 'tab_viewer_screen.dart';

class TabsListScreen extends StatefulWidget {
  const TabsListScreen({super.key});

  @override
  State<TabsListScreen> createState() => _TabsListScreenState();
}

class _TabsListScreenState extends State<TabsListScreen> {
  List<GuitarTab> _tabs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTabs();
  }

  Future<void> _loadTabs() async {
    setState(() => _isLoading = true);
    final tabs = await StorageService.loadAllTabs();
    setState(() {
      _tabs = tabs;
      _isLoading = false;
    });
  }

  Future<void> _deleteTab(GuitarTab tab) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tab'),
        content: Text('Delete "${tab.songName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteTab(tab.id);
      _loadTabs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${tab.songName}" deleted')),
        );
      }
    }
  }

  void _editTab(GuitarTab tab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TabEditorScreen(tab: tab)),
    ).then((_) => _loadTabs());
  }

  void _viewTab(GuitarTab tab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TabViewerScreen(tab: tab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tabs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTabs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tabs.isEmpty
              ? _buildEmptyState()
              : _buildTabsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.library_music_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tabs yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first tab to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsList() {
    return RefreshIndicator(
      onRefresh: _loadTabs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          return _TabCard(
            tab: tab,
            onTap: () => _editTab(tab),
            onView: () => _viewTab(tab),
            onDelete: () => _deleteTab(tab),
          );
        },
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  final GuitarTab tab;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _TabCard({
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tab.songName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.tune,
                              label: tab.tuning.split(' ').first,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.layers,
                              label: '${tab.sections.length}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu
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
              ),
              // Preview
              if (tab.sections.isNotEmpty && tab.sections.first.bars.isNotEmpty) ...[
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
                      tab.sections.first.stringCount.clamp(0, 4),
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
              // Time
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
          ),
        ),
      ),
    );
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
