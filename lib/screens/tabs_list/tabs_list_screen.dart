import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../services/storage_service.dart';
import '../tab_editor/tab_editor_screen.dart';
import '../tab_viewer/tab_viewer_screen.dart';
import 'widgets/tab_card.dart';

class TabsListScreen extends StatefulWidget {
  const TabsListScreen({super.key});

  @override
  State<TabsListScreen> createState() => _TabsListScreenState();
}

class _TabsListScreenState extends State<TabsListScreen> {
  List<GuitarTab> _tabs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  List<GuitarTab> get _filteredTabs {
    if (_searchQuery.isEmpty) return _tabs;
    return _tabs
        .where((tab) =>
            tab.songName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTabs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsList() {
    final tabs = _filteredTabs;

    return RefreshIndicator(
      onRefresh: _loadTabs,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tabs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: tabs.isEmpty
                ? Center(
                    child: Text(
                      'No tabs match "$_searchQuery"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      return TabCard(
                        tab: tab,
                        onTap: () => _editTab(tab),
                        onView: () => _viewTab(tab),
                        onDelete: () => _deleteTab(tab),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
