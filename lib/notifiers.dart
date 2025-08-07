import 'package:flutter/material.dart';

class LocaleNotifier extends ChangeNotifier {
  String _locale = 'en';
  String get locale => _locale;
  void toggleLocale() {
    _locale = _locale == 'en' ? 'el' : 'en';
    notifyListeners();
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
