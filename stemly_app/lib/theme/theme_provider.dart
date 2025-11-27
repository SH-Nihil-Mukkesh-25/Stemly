import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool enableDarkMode) {
    _themeMode = enableDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
