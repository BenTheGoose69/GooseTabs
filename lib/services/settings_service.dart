import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorSchemeType {
  orange('Sunset Orange', Color(0xFFFFAB91), Color(0xFFFFCC80)),
  blue('Ocean Blue', Color(0xFF81D4FA), Color(0xFF80DEEA)),
  green('Forest Green', Color(0xFFA5D6A7), Color(0xFFC5E1A5)),
  purple('Royal Purple', Color(0xFFCE93D8), Color(0xFFB39DDB)),
  red('Cherry Red', Color(0xFFEF9A9A), Color(0xFFFFAB91)),
  teal('Teal Vibes', Color(0xFF80CBC4), Color(0xFF80DEEA)),
  pink('Cotton Candy', Color(0xFFF48FB1), Color(0xFFCE93D8)),
  amber('Golden Amber', Color(0xFFFFD54F), Color(0xFFFFE082));

  final String displayName;
  final Color primary;
  final Color secondary;

  const ColorSchemeType(this.displayName, this.primary, this.secondary);
}

class SettingsService extends ChangeNotifier {
  static const String _colorSchemeKey = 'color_scheme';
  static const String _themeModeKey = 'theme_mode';
  static const String _defaultInstrumentKey = 'default_instrument';
  static const String _defaultStringsKey = 'default_strings';
  static const String _hapticFeedbackKey = 'haptic_feedback';
  static const String _autoSaveKey = 'auto_save';

  ColorSchemeType _colorScheme = ColorSchemeType.orange;
  ThemeMode _themeMode = ThemeMode.dark;
  String _defaultInstrument = 'guitar';
  int _defaultStrings = 6;
  bool _hapticFeedback = true;
  bool _autoSave = true;

  ColorSchemeType get colorScheme => _colorScheme;
  ThemeMode get themeMode => _themeMode;
  String get defaultInstrument => _defaultInstrument;
  int get defaultStrings => _defaultStrings;
  bool get hapticFeedback => _hapticFeedback;
  bool get autoSave => _autoSave;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final colorSchemeIndex = prefs.getInt(_colorSchemeKey) ?? 0;
    _colorScheme = ColorSchemeType.values[colorSchemeIndex.clamp(0, ColorSchemeType.values.length - 1)];

    final themeModeIndex = prefs.getInt(_themeModeKey) ?? 2; // Default to dark
    _themeMode = ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];

    _defaultInstrument = prefs.getString(_defaultInstrumentKey) ?? 'guitar';
    _defaultStrings = prefs.getInt(_defaultStringsKey) ?? (_defaultInstrument == 'bass' ? 4 : 6);
    _hapticFeedback = prefs.getBool(_hapticFeedbackKey) ?? true;
    _autoSave = prefs.getBool(_autoSaveKey) ?? true;

    notifyListeners();
  }

  Future<void> setColorScheme(ColorSchemeType scheme) async {
    _colorScheme = scheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeKey, scheme.index);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setDefaultInstrument(String instrument) async {
    _defaultInstrument = instrument;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultInstrumentKey, instrument);
    notifyListeners();
  }

  Future<void> setDefaultStrings(int strings) async {
    _defaultStrings = strings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultStringsKey, strings);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedback = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, enabled);
    notifyListeners();
  }

  Future<void> setAutoSave(bool enabled) async {
    _autoSave = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, enabled);
    notifyListeners();
  }
}
