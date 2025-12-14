import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import 'widgets/settings_section.dart';
import 'widgets/color_scheme_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  void _showColorSchemePicker() {
    showDialog(
      context: context,
      builder: (context) => ColorSchemeDialog(
        selectedScheme: settingsService.colorScheme,
        onSchemeSelected: (scheme) {
          settingsService.setColorScheme(scheme);
          if (settingsService.hapticFeedback) {
            HapticFeedback.lightImpact();
          }
        },
      ),
    );
  }

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(ThemeMode.system, 'System', Icons.brightness_auto),
            _buildThemeOption(ThemeMode.light, 'Light', Icons.light_mode),
            _buildThemeOption(ThemeMode.dark, 'Dark', Icons.dark_mode),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, String label, IconData icon) {
    final isSelected = settingsService.themeMode == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        settingsService.setThemeMode(mode);
        if (settingsService.hapticFeedback) {
          HapticFeedback.lightImpact();
        }
        Navigator.pop(context);
      },
    );
  }

  void _showFretCountDialog() {
    final fretCounts = [19, 20, 21, 22, 24];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Fret Count'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: fretCounts.map((count) {
            final isSelected = settingsService.defaultFretCount == count;
            return ListTile(
              title: Text('$count frets'),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                settingsService.setDefaultFretCount(count);
                if (settingsService.hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showInstrumentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Instrument'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInstrumentOption('guitar', 'Guitar', Icons.music_note),
            _buildInstrumentOption('bass', 'Bass', Icons.music_note_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentOption(String instrument, String label, IconData icon) {
    final isSelected = settingsService.defaultInstrument == instrument;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        settingsService.setDefaultInstrument(instrument);
        if (settingsService.hapticFeedback) {
          HapticFeedback.lightImpact();
        }
        Navigator.pop(context);
      },
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Appearance Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SettingsSection(
              title: 'APPEARANCE',
              children: [
                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Color Scheme',
                  subtitle: settingsService.colorScheme.displayName,
                  trailing: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              color: settingsService.colorScheme.primary,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              color: settingsService.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  onTap: _showColorSchemePicker,
                ),
                SettingsTile(
                  icon: Icons.brightness_6_outlined,
                  title: 'Theme',
                  subtitle: _getThemeModeName(settingsService.themeMode),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showThemeModeDialog,
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Editor Defaults Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SettingsSection(
              title: 'EDITOR DEFAULTS',
              children: [
                SettingsTile(
                  icon: Icons.straighten_outlined,
                  title: 'Default Fret Count',
                  subtitle: '${settingsService.defaultFretCount} frets',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showFretCountDialog,
                ),
                SettingsTile(
                  icon: Icons.music_note_outlined,
                  title: 'Default Instrument',
                  subtitle: settingsService.defaultInstrument == 'guitar'
                      ? 'Guitar'
                      : 'Bass',
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showInstrumentDialog,
                ),
                SettingsTile(
                  icon: Icons.numbers_outlined,
                  title: 'Show Fret Numbers',
                  subtitle: 'Display fret numbers on fretboard',
                  trailing: Switch(
                    value: settingsService.showFretNumbers,
                    onChanged: (value) {
                      settingsService.setShowFretNumbers(value);
                      if (settingsService.hapticFeedback) {
                        HapticFeedback.lightImpact();
                      }
                    },
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Behavior Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SettingsSection(
              title: 'BEHAVIOR',
              children: [
                SettingsTile(
                  icon: Icons.vibration_outlined,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibrate on button press',
                  trailing: Switch(
                    value: settingsService.hapticFeedback,
                    onChanged: (value) {
                      settingsService.setHapticFeedback(value);
                      if (value) {
                        HapticFeedback.lightImpact();
                      }
                    },
                  ),
                ),
                SettingsTile(
                  icon: Icons.save_outlined,
                  title: 'Auto-save',
                  subtitle: 'Save tabs automatically when editing',
                  trailing: Switch(
                    value: settingsService.autoSave,
                    onChanged: (value) {
                      settingsService.setAutoSave(value);
                      if (settingsService.hapticFeedback) {
                        HapticFeedback.lightImpact();
                      }
                    },
                  ),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SettingsSection(
              title: 'ABOUT',
              children: [
                SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Version',
                  subtitle: '1.0.0',
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/GooseTabsFinal.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'GooseTabs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Made for musicians',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
