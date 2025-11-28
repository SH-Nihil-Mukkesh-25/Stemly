import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // -------------------------------
  // THEME MODE
  // -------------------------------
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool enableDarkMode) {
    _themeMode = enableDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // -------------------------------
  // NOTIFICATIONS TOGGLE
  // -------------------------------
  bool _notifications = true;
  bool get notifications => _notifications;

  void toggleNotifications(bool value) {
    _notifications = value;
    notifyListeners();
  }

  // -------------------------------
  // WI-FI ONLY MODE
  // -------------------------------
  bool _wifiOnly = false;
  bool get wifiOnly => _wifiOnly;

  void toggleWifiOnly(bool value) {
    _wifiOnly = value;
    notifyListeners();
  }
}
