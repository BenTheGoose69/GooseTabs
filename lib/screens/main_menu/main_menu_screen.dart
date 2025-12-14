import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../tab_editor/tab_editor_screen.dart';
import '../tabs_list/tabs_list_screen.dart';
import '../secret/blackjack_screen.dart';
import 'widgets/menu_card.dart';
import 'widgets/new_tab_sheet.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _recentTabsCount = 0;
  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadRecentCount();
  }

  void _onSecretTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _secretTapCount = 0;
    }
    _lastTapTime = now;
    _secretTapCount++;

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const BlackjackScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
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
      builder: (context) => NewTabSheet(
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
      if (!context.mounted) return;
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
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48, // Account for padding
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            _buildHeader(context),
                            const SizedBox(height: 48),
                            _buildStatsCard(context),
                            const SizedBox(height: 32),
                            _buildQuickActionsHeader(context),
                            const SizedBox(height: 16),
                            _buildMenuCards(context),
                          ],
                        ),
                        _buildFooter(context),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Secret tap zone - bottom left corner
          Positioned(
            left: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _onSecretTap,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 80,
                height: 80,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsHeader(BuildContext context) {
    return Text(
      'Quick Actions',
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
    );
  }

  Widget _buildMenuCards(BuildContext context) {
    return Column(
      children: [
        MenuCard(
          icon: Icons.add_circle_outline,
          title: 'New Tab',
          subtitle: 'Create a new guitar or bass tab',
          color: Theme.of(context).colorScheme.primary,
          onTap: () => _createNewTab(context),
        ),
        const SizedBox(height: 12),
        MenuCard(
          icon: Icons.folder_outlined,
          title: 'My Tabs',
          subtitle: 'View and edit your saved tabs',
          color: Theme.of(context).colorScheme.secondary,
          onTap: () => _viewTabs(context),
        ),
        const SizedBox(height: 12),
        MenuCard(
          icon: Icons.upload_file_outlined,
          title: 'Import Tab',
          subtitle: 'Import from a .txt or .tab file',
          color: const Color(0xFFFD79A8),
          onTap: () => _importTab(context),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Text(
        'Made for musicians',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
      ),
    );
  }
}
