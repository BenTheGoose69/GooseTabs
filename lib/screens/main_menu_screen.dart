import 'package:flutter/material.dart';
import '../models/tab_model.dart';
import '../services/storage_service.dart';
import 'tab_editor_screen.dart';
import 'tabs_list_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _recentTabsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadRecentCount();
  }

  Future<void> _loadRecentCount() async {
    final tabs = await StorageService.loadAllTabs();
    setState(() => _recentTabsCount = tabs.length);
  }

  void _createNewTab(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewTabSheet(
        onCreated: (tab) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TabEditorScreen(tab: tab)),
          ).then((_) => _loadRecentCount());
        },
      ),
    );
  }

  void _viewTabs(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TabsListScreen()),
    ).then((_) => _loadRecentCount());
  }

  Future<void> _importTab(BuildContext context) async {
    final tab = await StorageService.importTabFromFile();
    if (tab != null && context.mounted) {
      await StorageService.saveTab(tab);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported "${tab.songName}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TabEditorScreen(tab: tab)),
      ).then((_) => _loadRecentCount());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo & Title
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GooseTabs',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'The Tab Writer',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_music,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_recentTabsCount',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          'Saved tabs',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Menu buttons
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 16),
              _MenuCard(
                icon: Icons.add_circle_outline,
                title: 'New Tab',
                subtitle: 'Create a new guitar or bass tab',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _createNewTab(context),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.folder_outlined,
                title: 'My Tabs',
                subtitle: 'View and edit your saved tabs',
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => _viewTabs(context),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.upload_file_outlined,
                title: 'Import Tab',
                subtitle: 'Import from a .txt or .tab file',
                color: const Color(0xFFFD79A8),
                onTap: () => _importTab(context),
              ),
              const Spacer(),
              // Footer
              Center(
                child: Text(
                  'Made for musicians',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTabSheet extends StatefulWidget {
  final Function(GuitarTab) onCreated;

  const _NewTabSheet({required this.onCreated});

  @override
  State<_NewTabSheet> createState() => _NewTabSheetState();
}

class _NewTabSheetState extends State<_NewTabSheet> {
  final _songNameController = TextEditingController();
  String _instrument = 'Guitar'; // Guitar or Bass
  int _stringCount = 6;

  @override
  void dispose() {
    _songNameController.dispose();
    super.dispose();
  }

  List<String> _getDefaultStrings() {
    if (_instrument == 'Bass') {
      if (_stringCount == 4) return ['G', 'D', 'A', 'E'];
      if (_stringCount == 5) return ['G', 'D', 'A', 'E', 'B'];
      return ['C', 'G', 'D', 'A', 'E', 'B']; // 6-string bass
    } else {
      if (_stringCount == 4) return ['e', 'B', 'G', 'D']; // Ukulele-style
      if (_stringCount == 7) return ['e', 'B', 'G', 'D', 'A', 'E', 'B'];
      if (_stringCount == 8) return ['e', 'B', 'G', 'D', 'A', 'E', 'B', 'F#'];
      return ['e', 'B', 'G', 'D', 'A', 'E']; // Standard 6-string
    }
  }

  void _create() {
    final songName = _songNameController.text.trim();
    if (songName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a song name')),
      );
      return;
    }

    final stringNames = _getDefaultStrings();
    final tab = GuitarTab(
      id: StorageService.generateId(),
      songName: songName,
      tuning: '$_instrument $_stringCount-string',
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    // Create first section with the selected string configuration
    final section = TabSection(stringNames: stringNames);
    for (int i = 0; i < 16; i++) {
      section.bars[0].addColumn();
    }
    tab.sections.add(section);

    Navigator.pop(context);
    widget.onCreated(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create New Tab',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _songNameController,
              decoration: const InputDecoration(
                labelText: 'Song Name',
                hintText: 'Enter the song name',
                prefixIcon: Icon(Icons.music_note_outlined),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 20),
            // Instrument selection
            Text(
              'Instrument',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InstrumentOption(
                    label: 'Guitar',
                    icon: Icons.music_note,
                    isSelected: _instrument == 'Guitar',
                    onTap: () => setState(() {
                      _instrument = 'Guitar';
                      if (_stringCount < 6) _stringCount = 6;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InstrumentOption(
                    label: 'Bass',
                    icon: Icons.graphic_eq,
                    isSelected: _instrument == 'Bass',
                    onTap: () => setState(() {
                      _instrument = 'Bass';
                      if (_stringCount > 6) _stringCount = 4;
                      if (_stringCount == 6) _stringCount = 4;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // String count selection
            Text(
              'Strings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _getStringOptions().map((count) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _StringCountOption(
                      count: count,
                      isSelected: _stringCount == count,
                      onTap: () => setState(() => _stringCount = count),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('Create Tab'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<int> _getStringOptions() {
    if (_instrument == 'Bass') {
      return [4, 5, 6];
    } else {
      return [6, 7, 8];
    }
  }
}

class _InstrumentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _InstrumentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.black
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StringCountOption extends StatelessWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StringCountOption({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
