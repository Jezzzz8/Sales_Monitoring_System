import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import 'theme_manager.dart';
import '../models/settings_model.dart';

class AppTheme {
  final AppSettings settings;
  late final ThemeData _lightTheme;
  late final ThemeData _darkTheme;
  
  AppTheme(this.settings) {
    _lightTheme = ThemeManager.lightTheme(settings.primaryColor);
    _darkTheme = ThemeManager.darkTheme(settings.primaryColor);
  }

  ThemeData get currentTheme {
    switch (settings.themeModeValue) {
      case ThemeMode.dark:
        return _darkTheme;
      case ThemeMode.light:
        return _lightTheme;
      case ThemeMode.system:
        // In a real app, you'd check the system theme
        return _lightTheme;
    }
  }

  static Widget withTransition({
    required BuildContext context,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    
    return AnimatedTheme(
      data: themeProvider.themeData,
      duration: duration,
      curve: Curves.easeInOut,
      child: child,
    );
  }

  String get themeModeDisplayName {
    switch (settings.themeModeValue) {
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.system:
        return 'System Mode';
    }
  }

  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  String get colorSchemeName => settings.primaryColor;
  bool get isDarkTheme => settings.themeModeValue == ThemeMode.dark;

  Color getContrastColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = (0.299 * backgroundColor.red + 
                      0.587 * backgroundColor.green + 
                      0.114 * backgroundColor.blue) / 255;
    
    // Use white text on dark backgrounds, black on light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Convenience getters for commonly used colors
  Color get primaryColor => currentTheme.colorScheme.primary;
  Color get secondaryColor => currentTheme.colorScheme.secondary;
  Color get backgroundColor => currentTheme.colorScheme.surface;
  Color get surfaceColor => currentTheme.colorScheme.surface;
  Color get onPrimaryColor => currentTheme.colorScheme.onPrimary;
  Color get onSurfaceColor => currentTheme.colorScheme.onSurface;
  Color get errorColor => currentTheme.colorScheme.error;

  // Text styles
  TextStyle get displayLarge => currentTheme.textTheme.displayLarge!;
  TextStyle get displayMedium => currentTheme.textTheme.displayMedium!;
  TextStyle get displaySmall => currentTheme.textTheme.displaySmall!;
  TextStyle get headlineMedium => currentTheme.textTheme.headlineMedium!;
  TextStyle get headlineSmall => currentTheme.textTheme.headlineSmall!;
  TextStyle get titleLarge => currentTheme.textTheme.titleLarge!;
  TextStyle get titleMedium => currentTheme.textTheme.titleMedium!;
  TextStyle get titleSmall => currentTheme.textTheme.titleSmall!;
  TextStyle get bodyLarge => currentTheme.textTheme.bodyLarge!;
  TextStyle get bodyMedium => currentTheme.textTheme.bodyMedium!;
  TextStyle get bodySmall => currentTheme.textTheme.bodySmall!;
  TextStyle get labelLarge => currentTheme.textTheme.labelLarge!;
  TextStyle get labelSmall => currentTheme.textTheme.labelSmall!;

  // Custom styles
  TextStyle get cardTitleStyle => titleMedium.copyWith(
    fontWeight: FontWeight.w600,
  );

  TextStyle get cardSubtitleStyle => bodySmall.copyWith(
    color: currentTheme.textTheme.bodySmall!.color!.withOpacity(0.6),
  );

  TextStyle get sectionHeaderStyle => labelLarge.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: primaryColor,
  );

  // Widget builders
  Card createCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Container createSectionHeader(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: sectionHeaderStyle,
      ),
    );
  }

  ElevatedButton createPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool fullWidth = true,
    EdgeInsetsGeometry? padding,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        minimumSize: fullWidth ? const Size(double.infinity, 50) : null,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(text),
    );
  }

  OutlinedButton createSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    bool fullWidth = true,
  }) {
    final effectiveColor = color ?? primaryColor;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveColor,
        side: BorderSide(color: effectiveColor),
        minimumSize: fullWidth ? const Size(double.infinity, 50) : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(text),
    );
  }

  // Helper to check if we're in dark mode
  bool get isDarkMode => settings.themeModeValue == ThemeMode.dark;

  // Generate a shimmer gradient based on theme
  List<Color> get shimmerGradientColors {
    if (isDarkMode) {
      return [
        const Color(0xFF2D2D2D),
        const Color(0xFF3A3A3A),
        const Color(0xFF2D2D2D),
      ];
    } else {
      return [
        Colors.grey.shade100,
        Colors.grey.shade200,
        Colors.grey.shade100,
      ];
    }
  }

  // Get appropriate icon color for surfaces
  Color getIconColor({Color? surfaceColor, bool? isSelected}) {
    if (isSelected == true) {
      return primaryColor;
    }
    
    if (!isDarkMode) {
      return Colors.black.withOpacity(0.54);
    }
    
    final effectiveSurface = surfaceColor ?? this.surfaceColor;
    final onSurface = ThemeManager.getOnSurfaceColor(
      effectiveSurface,
      Brightness.dark,
    );
    
    return onSurface.withOpacity(0.7);
  }

  // Get appropriate text color for surfaces
  Color getTextColor({Color? surfaceColor, bool? emphasized}) {
    final effectiveSurface = surfaceColor ?? this.surfaceColor;
    
    // For light theme, use black text
    if (!isDarkMode) {
      if (emphasized == true) {
        return Colors.black.withOpacity(0.87);
      } else {
        return Colors.black.withOpacity(0.6);
      }
    }
    
    // For dark theme, use white text
    final onSurface = ThemeManager.getOnSurfaceColor(
      effectiveSurface,
      Brightness.dark,
    );
    
    if (emphasized == true) {
      return onSurface;
    } else {
      return onSurface.withOpacity(0.87);
    }
  }

  Color getSubtitleColor({Color? surfaceColor}) {
    if (!isDarkMode) {
      return Colors.black.withOpacity(0.54);
    }
    
    final effectiveSurface = surfaceColor ?? this.surfaceColor;
    final onSurface = ThemeManager.getOnSurfaceColor(
      effectiveSurface,
      Brightness.dark,
    );
    
    return onSurface.withOpacity(0.6);
  }

  // Update theme when settings change
  AppTheme copyWithSettings(AppSettings newSettings) {
    return AppTheme(newSettings);
  }
}