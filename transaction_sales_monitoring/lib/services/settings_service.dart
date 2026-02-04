import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsNotifier extends ChangeNotifier {
  AppSettings? _currentSettings;
  
  AppSettings? get currentSettings => _currentSettings;
  
  void updateSettings(AppSettings newSettings) {
    _currentSettings = newSettings;
    notifyListeners();
  }
}

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static AppSettings? _cachedSettings;
  static bool _hasUnsavedChanges = false;
  static AppSettings? _pendingChanges;
  static final SettingsNotifier _notifier = SettingsNotifier();
  static SettingsNotifier get notifier => _notifier;

  // Load settings from local storage - FORCE RELOAD
  static Future<AppSettings> loadSettings({bool forceReload = false}) async {
    if (_cachedSettings != null && !forceReload) {
      return _cachedSettings!;
    }

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settingsMap = json.decode(settingsJson);
        _cachedSettings = AppSettings.fromMap(settingsMap);
        _notifier.updateSettings(_cachedSettings!);
        return _cachedSettings!;
      } catch (e) {
        print('Error loading settings: $e');
        _cachedSettings = AppSettings();
        _notifier.updateSettings(_cachedSettings!);
        return _cachedSettings!;
      }
    } else {
      _cachedSettings = AppSettings();
      _notifier.updateSettings(_cachedSettings!);
      return _cachedSettings!;
    }
  }

  // Save settings to local storage - CLEAR CACHE
  static Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toMap());
      await prefs.setString(_settingsKey, settingsJson);
      
      // Update cache
      _cachedSettings = settings;
      _hasUnsavedChanges = false;
      _pendingChanges = null;
      
      // Notify all listeners WITHOUT forcing app rebuild
      _notifier.updateSettings(settings);
      
      print('Settings saved successfully');
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }

  // Reset settings to defaults
  static Future<void> resetSettings() async {
    final defaultSettings = AppSettings();
    await saveSettings(defaultSettings);
  }

  // Check if settings exist
  static Future<bool> hasSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_settingsKey);
  }

  // Clear all settings
  static Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
    _cachedSettings = null;
    _hasUnsavedChanges = false;
    _pendingChanges = null;
  }

  // Get specific setting value
  static Future<dynamic> getSetting(String key) async {
    final settings = await loadSettings();
    
    switch (key) {
      case 'primaryColor':
        return settings.primaryColor;
      case 'themeMode':
        return settings.themeMode;
      case 'language':
        return settings.language;
      case 'dateFormat':
        return settings.dateFormat;
      case 'timeFormat':
        return settings.timeFormat;
      case 'notificationsEnabled':
        return settings.notificationsEnabled;
      case 'emailNotifications':
        return settings.emailNotifications;
      case 'lowStockAlerts':
        return settings.lowStockAlerts;
      case 'soundEffects':
        return settings.soundEffects;
      case 'vibrationFeedback':
        return settings.vibrationFeedback;
      case 'showConfirmationDialogs':
        return settings.showConfirmationDialogs;
      case 'autoPrintReceipts':
        return settings.autoPrintReceipts;
      case 'receiptCopies':
        return settings.receiptCopies;
      case 'currency':
        return settings.currency;
      case 'taxRate':
        return settings.taxRate;
      case 'autoBackup':
        return settings.autoBackup;
      case 'backupFrequency':
        return settings.backupFrequency;
      default:
        return null;
    }
  }

  // Update a single setting
  static Future<void> updateSetting(String key, dynamic value) async {
    final currentSettings = await loadSettings();
    
    AppSettings updatedSettings;
    
    switch (key) {
      case 'primaryColor':
        updatedSettings = currentSettings.copyWith(primaryColor: value as String);
        break;
      case 'themeMode':
        updatedSettings = currentSettings.copyWith(themeMode: value as String);
        break;
      case 'language':
        updatedSettings = currentSettings.copyWith(language: value as String);
        break;
      case 'dateFormat':
        updatedSettings = currentSettings.copyWith(dateFormat: value as String);
        break;
      case 'timeFormat':
        updatedSettings = currentSettings.copyWith(timeFormat: value as String);
        break;
      case 'notificationsEnabled':
        updatedSettings = currentSettings.copyWith(notificationsEnabled: value as bool);
        break;
      case 'emailNotifications':
        updatedSettings = currentSettings.copyWith(emailNotifications: value as bool);
        break;
      case 'lowStockAlerts':
        updatedSettings = currentSettings.copyWith(lowStockAlerts: value as bool);
        break;
      case 'soundEffects':
        updatedSettings = currentSettings.copyWith(soundEffects: value as bool);
        break;
      case 'vibrationFeedback':
        updatedSettings = currentSettings.copyWith(vibrationFeedback: value as bool);
        break;
      case 'showConfirmationDialogs':
        updatedSettings = currentSettings.copyWith(showConfirmationDialogs: value as bool);
        break;
      case 'autoPrintReceipts':
        updatedSettings = currentSettings.copyWith(autoPrintReceipts: value as bool);
        break;
      case 'receiptCopies':
        updatedSettings = currentSettings.copyWith(receiptCopies: value as int);
        break;
      case 'currency':
        updatedSettings = currentSettings.copyWith(currency: value as String);
        break;
      case 'taxRate':
        updatedSettings = currentSettings.copyWith(taxRate: value as double);
        break;
      case 'autoBackup':
        updatedSettings = currentSettings.copyWith(autoBackup: value as bool);
        break;
      case 'backupFrequency':
        updatedSettings = currentSettings.copyWith(backupFrequency: value as int);
        break;
      default:
        throw Exception('Unknown setting key: $key');
    }
    
    await saveSettings(updatedSettings);
  }

  // NEW: Check for unsaved changes
  static bool get hasUnsavedChanges => _hasUnsavedChanges;
  
  static void setPendingChanges(AppSettings settings) {
    _pendingChanges = settings;
    _hasUnsavedChanges = true;
  }
  
  static AppSettings? get pendingChanges => _pendingChanges;
  
  static void discardPendingChanges() {
    _pendingChanges = null;
    _hasUnsavedChanges = false;
  }
}