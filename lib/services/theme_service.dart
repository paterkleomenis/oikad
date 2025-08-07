import 'package:flutter/material.dart';
import 'config_service.dart';

class ThemeService {
  static ThemeData getLightTheme() {
    return ThemeData(
      colorSchemeSeed: Colors.teal,
      brightness: Brightness.light,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      cardTheme: CardThemeData(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ConfigService.cardBorderRadius),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: ConfigService.defaultPadding,
          horizontal: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ConfigService.defaultBorderRadius,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ConfigService.defaultBorderRadius,
          ),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ConfigService.defaultBorderRadius,
          ),
          borderSide: const BorderSide(color: Colors.teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ConfigService.defaultBorderRadius,
          ),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ConfigService.defaultBorderRadius,
          ),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ConfigService.defaultPadding,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: ConfigService.defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ConfigService.defaultBorderRadius,
            ),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 3,
          shadowColor: Colors.black26,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ConfigService.defaultBorderRadius,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ConfigService.defaultPadding,
            vertical: ConfigService.smallPadding,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(thickness: 1, space: 32),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ConfigService.defaultBorderRadius,
          ),
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ConfigService.defaultBorderRadius,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ConfigService.defaultPadding,
            vertical: 14,
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ConfigService.cardBorderRadius),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    final lightTheme = getLightTheme();
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      cardTheme: lightTheme.cardTheme?.copyWith(shadowColor: Colors.black45),
      inputDecorationTheme: lightTheme.inputDecorationTheme?.copyWith(
        fillColor: Colors.grey.shade800,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ConfigService.defaultBorderRadius,
          ),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: lightTheme.elevatedButtonTheme?.style?.copyWith(
          shadowColor: MaterialStateProperty.all(Colors.black54),
        ),
      ),
    );
  }

  static ColorScheme getLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    );
  }

  static ColorScheme getDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    );
  }

  // Animation curves for smooth transitions
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  // Custom page transition builder
  static Widget pageTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.05);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    final tween = Tween(begin: begin, end: end);
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: tween.animate(curvedAnimation),
        child: child,
      ),
    );
  }

  // Helper method to get appropriate text color based on background
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  // Helper method to get contrast color
  static Color getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
