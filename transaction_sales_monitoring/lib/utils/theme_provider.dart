import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';
import 'theme_manager.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  late AppSettings _settings;
  late AppTheme _appTheme;
  bool _isLoading = true;

  AppTheme get appTheme => _appTheme;
  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  ThemeProvider(Map<String, String> initialPreferences) {
    // Initialize with preferences from main.dart
    _settings = AppSettings(
      primaryColor: initialPreferences['colorName'] ?? 'Deep Orange',
      themeMode: initialPreferences['themeMode'] ?? 'Light',
    );
    _appTheme = AppTheme(_settings);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load settings from service
      _settings = await SettingsService.loadSettings();
      _appTheme = AppTheme(_settings);
    } catch (e) {
      print('Error loading theme settings: $e');
      // Use default settings
      _settings = AppSettings();
      _appTheme = AppTheme(_settings);
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    _appTheme = AppTheme(_settings);
    
    // Force immediate rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    
    // Save to storage in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveToStorage();
    });
  }

  void updatePrimaryColor(String colorName) {
    _settings = _settings.copyWith(primaryColor: colorName);
    _appTheme = AppTheme(_settings);
    notifyListeners();
    
    // Save to storage in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveToStorage();
    });
  }

  void updateThemeMode(String themeMode) {
    _settings = _settings.copyWith(themeMode: themeMode);
    _appTheme = AppTheme(_settings);
    notifyListeners();
    
    // Save to storage in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveToStorage();
    });
  }

  Future<void> _saveToStorage() async {
    try {
      await SettingsService.saveSettings(_settings);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> saveTheme() async {
    try {
      await SettingsService.saveSettings(_settings);
    } catch (e) {
      print('Error saving theme: $e');
      rethrow;
    }
  }

  void forceUpdate() {
    notifyListeners();
  }

  Future<void> refreshTheme() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Force reload settings
      _settings = await SettingsService.loadSettings(forceReload: true);
      _appTheme = AppTheme(_settings);
    } catch (e) {
      print('Error refreshing theme: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  ThemeData get themeData => ThemeManager.getThemeFromSettings(_settings);

  // Static helper to get theme from context
  static AppTheme of(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false).appTheme;
  }

  // Static helper to get theme provider from context
  static ThemeProvider instance(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: false);
  }

  static AppTheme ofListenable(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: true).appTheme;
  }

  static AppTheme watch(BuildContext context) {
    return Provider.of<ThemeProvider>(context, listen: true).appTheme;
  }
}