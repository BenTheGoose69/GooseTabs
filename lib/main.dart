import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_menu/main_menu_screen.dart';
import 'theme/app_theme.dart';
import 'services/settings_service.dart';

final settingsService = SettingsService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await settingsService.loadSettings();
  runApp(const TabWriterApp());
}

class TabWriterApp extends StatefulWidget {
  const TabWriterApp({super.key});

  @override
  State<TabWriterApp> createState() => _TabWriterAppState();
}

class _TabWriterAppState extends State<TabWriterApp> {
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
    // Update system UI style based on theme
    final isDark = settingsService.themeMode == ThemeMode.dark ||
        (settingsService.themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GooseTabs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildLightTheme(settingsService.colorScheme),
      darkTheme: AppTheme.buildDarkTheme(settingsService.colorScheme),
      themeMode: settingsService.themeMode,
      home: const MainMenuScreen(),
    );
  }
}
