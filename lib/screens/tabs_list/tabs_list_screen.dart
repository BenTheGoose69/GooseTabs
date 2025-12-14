import 'package:flutter/material.dart';
import '../../models/tab_model.dart';
import '../../models/folder_model.dart';
import '../../services/storage_service.dart';
import '../tab_editor/tab_editor_screen.dart';
import '../tab_viewer/tab_viewer_screen.dart';
import 'widgets/tab_card.dart';
import 'widgets/folder_card.dart';
import 'dialogs/folder_name_dialog.dart';
import 'dialogs/folder_options_dialog.dart';
import 'dialogs/move_to_folder_dialog.dart';

class TabsListScreen extends StatefulWidget {
  const TabsListScreen({super.key});

  @override
  State<TabsListScreen> createState() => _TabsListScreenState();
}

class _TabsListScreenState extends State<TabsListScreen> {
  List<GuitarTab> _tabs = [];
  List<TabFolder> _folders = [];
  final Set<String> _expandedFolderIds = {};
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

  List<TabFolder> get _filteredFolders {
    if (_searchQuery.isEmpty) return _folders;
    // Show folders that either match the search or contain matching tabs
    return _folders.where((folder) {
      final folderMatches =
          folder.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final hasMatchingTabs = _filteredTabs.any((t) => t.folderId == folder.id);
      return folderMatches || hasMatchingTabs;
    }).toList();
  }

  List<GuitarTab> _getTabsInFolder(String folderId) {
    return _filteredTabs.where((t) => t.folderId == folderId).toList();
  }

  List<GuitarTab> get _unfiledTabs {
    return _filteredTabs.where((t) => t.folderId == null).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tabs = await StorageService.loadAllTabs();
    final folders = await StorageService.loadAllFolders();
    setState(() {
      _tabs = tabs;
      _folders = folders;
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
      _loadData();
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
    ).then((_) => _loadData());
  }

  void _viewTab(GuitarTab tab) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TabViewerScreen(tab: tab)),
    );
  }

  Future<void> _createFolder() async {
    final name = await FolderNameDialog.show(context: context);
    if (name != null && name.isNotEmpty) {
      final folder = TabFolder(
        id: StorageService.generateId(),
        name: name,
        createdAt: DateTime.now(),
      );
      await StorageService.saveFolder(folder);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "$name" created')),
        );
      }
    }
  }

  Future<void> _renameFolder(TabFolder folder) async {
    final newName = await FolderNameDialog.show(
      context: context,
      currentName: folder.name,
    );
    if (newName != null && newName.isNotEmpty && newName != folder.name) {
      folder.name = newName;
      await StorageService.saveFolder(folder);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder renamed to "$newName"')),
        );
      }
    }
  }

  Future<void> _deleteFolder(TabFolder folder) async {
    final tabCount = _tabs.where((t) => t.folderId == folder.id).length;
    final message = tabCount > 0
        ? 'Delete "${folder.name}"? The $tabCount ${tabCount == 1 ? 'tab' : 'tabs'} inside will be moved to unfiled.'
        : 'Delete "${folder.name}"?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text(message),
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
      await StorageService.deleteFolder(folder.id);
      _expandedFolderIds.remove(folder.id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "${folder.name}" deleted')),
        );
      }
    }
  }

  Future<void> _showFolderOptions(TabFolder folder) async {
    final action = await FolderOptionsDialog.show(
      context: context,
      folder: folder,
    );

    if (action == FolderAction.rename) {
      _renameFolder(folder);
    } else if (action == FolderAction.delete) {
      _deleteFolder(folder);
    }
  }

  void _toggleFolderExpansion(String folderId) {
    setState(() {
      if (_expandedFolderIds.contains(folderId)) {
        _expandedFolderIds.remove(folderId);
      } else {
        _expandedFolderIds.add(folderId);
      }
    });
  }

  Future<void> _moveTab(GuitarTab tab) async {
    final result = await MoveToFolderDialog.show(
      context: context,
      folders: _folders,
      currentFolderId: tab.folderId,
    );

    if (result != null) {
      // Empty string means unfiled (root)
      final newFolderId = result.isEmpty ? null : result;
      if (newFolderId != tab.folderId) {
        await StorageService.moveTabToFolder(tab.id, newFolderId);
        _loadData();
        if (mounted) {
          final folderName = newFolderId == null
              ? 'unfiled'
              : _folders.firstWhere((f) => f.id == newFolderId).name;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Moved to $folderName')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('My Tabs'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_tabs.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _createFolder,
            tooltip: 'New folder',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tabs.isEmpty && _folders.isEmpty
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
    final folders = _filteredFolders;
    final unfiledTabs = _unfiledTabs;
    final hasContent = folders.isNotEmpty || unfiledTabs.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadData,
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
            child: !hasContent
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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      // Folders section
                      ...folders.map((folder) => _buildFolderSection(folder)),
                      // Unfiled tabs section
                      if (unfiledTabs.isNotEmpty && folders.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            'Unfiled',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ...unfiledTabs.map((tab) => TabCard(
                            tab: tab,
                            onTap: () => _editTab(tab),
                            onView: () => _viewTab(tab),
                            onDelete: () => _deleteTab(tab),
                            onMove: () => _moveTab(tab),
                          )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSection(TabFolder folder) {
    final isExpanded = _expandedFolderIds.contains(folder.id);
    final tabsInFolder = _getTabsInFolder(folder.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FolderCard(
          folder: folder,
          tabCount: tabsInFolder.length,
          isExpanded: isExpanded,
          onTap: () => _toggleFolderExpansion(folder.id),
          onLongPress: () => _showFolderOptions(folder),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: tabsInFolder.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No tabs in this folder',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                      ),
                    ]
                  : tabsInFolder
                      .map((tab) => TabCard(
                            tab: tab,
                            onTap: () => _editTab(tab),
                            onView: () => _viewTab(tab),
                            onDelete: () => _deleteTab(tab),
                            onMove: () => _moveTab(tab),
                          ))
                      .toList(),
            ),
          ),
      ],
    );
  }
}
