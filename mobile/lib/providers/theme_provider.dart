import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  final Box _settingsBox = Hive.box('settings');
  
  ThemeMode _themeMode = ThemeMode.dark;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  void _loadTheme() {
    final savedTheme = _settingsBox.get(_themeKey, defaultValue: 'dark');
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    await _settingsBox.put(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    await setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
