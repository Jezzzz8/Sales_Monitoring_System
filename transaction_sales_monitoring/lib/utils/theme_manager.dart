import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class ThemeManager {
  static const String _themeKey = 'app_theme';
  static const String _colorKey = 'theme_color';
  
  // Material Design 3 Seed Colors
  static const Map<String, Color> seedColors = {
    'Deep Orange': Color(0xFFE64A19), // Material Deep Orange 700
    'Blue': Color(0xFF1976D2),        // Material Blue 700
    'Green': Color(0xFF388E3C),       // Material Green 700
    'Purple': Color(0xFF7B1FA2),      // Material Purple 700
    'Red': Color(0xFFD32F2F),         // Material Red 700
    'Teal': Color(0xFF00796B),        // Material Teal 700
    'Indigo': Color(0xFF303F9F),      // Material Indigo 700
    'Pink': Color(0xFFC2185B),        // Material Pink 700
    'Cyan': Color(0xFF0097A7),        // Material Cyan 700
    'Amber': Color(0xFFFFA000),       // Material Amber 700
  };

  // Generate light theme from seed color
  static ThemeData lightTheme(String colorName) {
    final seedColor = seedColors[colorName] ?? seedColors['Deep Orange']!;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        primary: seedColor,
        secondary: seedColor.withOpacity(0.8),
        tertiary: seedColor.withOpacity(0.6),
      ),
      // Typography
      textTheme: _createTextTheme(Brightness.light),
      // Component themes
      scaffoldBackgroundColor: Colors.grey.shade50,
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(64, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seedColor,
          side: BorderSide(color: seedColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          minimumSize: const Size(64, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.shade400,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: seedColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: Colors.grey.shade800,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: seedColor,
        unselectedItemColor: Colors.grey.shade600,
        elevation: 4,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: seedColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: seedColor.withOpacity(0.1),
        selectedColor: seedColor,
        labelStyle: TextStyle(
          color: Colors.grey.shade800,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: seedColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Generate dark theme from seed color
  static ThemeData darkTheme(String colorName) {
    final seedColor = seedColors[colorName] ?? seedColors['Deep Orange']!;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        primary: seedColor,
        onPrimary: Colors.white,
        secondary: seedColor.withOpacity(0.8),
        onSecondary: Colors.white,
        surface: const Color(0xFF1E1E1E),
        surfaceVariant: const Color(0xFF2D2D2D),
        onSurface: const Color(0xFFE0E0E0),
        background: const Color(0xFF121212),
        onBackground: const Color(0xFFE0E0E0),
      ),
      // Typography for dark mode
      textTheme: _createTextTheme(Brightness.dark),
      // Component themes for dark mode
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFE0E0E0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF333333),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFF1976D2),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        hintStyle: const TextStyle(
          color: Color(0xFF888888),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFFCCCCCC),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 1,
      ),
    );
  }

  // Create text theme with proper contrast
  static TextTheme _createTextTheme(Brightness brightness) {
    final baseTextTheme = brightness == Brightness.dark 
        ? Typography.material2021().white 
        : Typography.material2021().black;
    
    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      ),
      displayMedium: baseTextTheme.displayMedium!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displaySmall: baseTextTheme.displaySmall!.copyWith(
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTextTheme.headlineMedium!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.25,
      ),
      headlineSmall: baseTextTheme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      titleSmall: baseTextTheme.titleSmall!.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        letterSpacing: 0.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        letterSpacing: 0.25,
      ),
      labelLarge: baseTextTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: baseTextTheme.labelSmall!.copyWith(
        letterSpacing: 0.4,
      ),
    );
  }

  // Get theme based on settings
  static ThemeData getThemeFromSettings(AppSettings settings) {
    final themeMode = settings.themeModeValue;
    final colorName = settings.primaryColor;
    
    switch (themeMode) {
      case ThemeMode.dark:
        return darkTheme(colorName);
      case ThemeMode.light:
        return lightTheme(colorName);
      case ThemeMode.system:
      // ignore: unreachable_switch_default
      default:
        // Return light theme by default, but you could check system preference
        return lightTheme(colorName);
    }
  }

  // Save theme preferences
  static Future<void> saveThemePreferences({
    required String themeMode,
    required String colorName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode);
    await prefs.setString(_colorKey, colorName);
  }

  // Load theme preferences
  static Future<Map<String, String>> loadThemePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'themeMode': prefs.getString(_themeKey) ?? 'Light',
      'colorName': prefs.getString(_colorKey) ?? 'Deep Orange',
    };
  }

  // Get contrast color for text/icons on colored backgrounds
  static Color getOnPrimaryColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = (0.299 * backgroundColor.red + 
                      0.587 * backgroundColor.green + 
                      0.114 * backgroundColor.blue) / 255;
    
    // Use white text on dark backgrounds, black on light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Generate accessible text color for surfaces
  static Color getOnSurfaceColor(Color surfaceColor, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return Colors.white.withOpacity(0.87);
    } else {
      return Colors.black.withOpacity(0.87);
    }
  }

  // Generate a color swatch from seed color
  static MaterialColor generateMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final r = color.red, g = color.green, b = color.blue;

    for (var i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }

  // Check if two colors have sufficient contrast
  static bool hasSufficientContrast(Color color1, Color color2) {
    final luminance1 = _relativeLuminance(color1);
    final luminance2 = _relativeLuminance(color2);
    final contrast = (max(luminance1, luminance2) + 0.05) / 
                     (min(luminance1, luminance2) + 0.05);
    return contrast >= 4.5; // WCAG AA standard
  }

  static double _relativeLuminance(Color color) {
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;

    final rsRGB = (r <= 0.03928) ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
    final gsRGB = (g <= 0.03928) ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
    final bsRGB = (b <= 0.03928) ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * rsRGB + 0.7152 * gsRGB + 0.0722 * bsRGB;
  }

  static T max<T extends num>(T a, T b) => a > b ? a : b;
  static T min<T extends num>(T a, T b) => a < b ? a : b;
}