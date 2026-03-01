import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _currentThemeMode = ThemeMode.system;

  ThemeMode get currentThemeMode => _currentThemeMode;

  bool get isDarkMode => _currentThemeMode == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    if (_currentThemeMode == mode) {
      return;
    }

    _currentThemeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _currentThemeMode =
        _currentThemeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
