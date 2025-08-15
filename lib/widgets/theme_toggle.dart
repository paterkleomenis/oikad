import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) => IconButton(
        icon: Icon(
          themeNotifier.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        ),
        onPressed: () => themeNotifier.toggleTheme(),
        tooltip: themeNotifier.isDarkMode ? 'Light Mode' : 'Dark Mode',
      ),
    );
  }
}
