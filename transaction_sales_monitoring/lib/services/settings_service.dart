import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';
  static AppSettings? _cachedSettings;

  // Load settings from local storage
  static Future<AppSettings> loadSettings() async {
    // Return cached settings if available
    if (_cachedSettings != null) {
      return _cachedSettings!;
    }

    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      try {
        // Parse JSON string
        final Map<String, dynamic> settingsMap = 
            Map<String, dynamic>.from(settingsJson.split('&').map((entry) {
          final parts = entry.split('=');
          if (parts.length == 2) {
            return MapEntry(parts[0], parts[1]);
          }
          return MapEntry('', '');
        }).where((entry) => entry.key.isNotEmpty) as Map<dynamic, dynamic>);

        // Convert string values to proper types
        final Map<String, dynamic> convertedMap = {};
        
        for (var entry in settingsMap.entries) {
          final key = entry.key;
          final value = entry.value;
          
          if (key.endsWith('_bool')) {
            convertedMap[key.replaceAll('_bool', '')] = value == 'true';
          } else if (key.endsWith('_int')) {
            convertedMap[key.replaceAll('_int', '')] = int.tryParse(value) ?? 0;
          } else if (key.endsWith('_double')) {
            convertedMap[key.replaceAll('_double', '')] = double.tryParse(value) ?? 0.0;
          } else {
            convertedMap[key] = value;
          }
        }

        _cachedSettings = AppSettings.fromMap(convertedMap);
        return _cachedSettings!;
      } catch (e) {
        print('Error loading settings: $e');
        // Return default settings if there's an error
        _cachedSettings = AppSettings();
        return _cachedSettings!;
      }
    } else {
      // Return default settings if none saved
      _cachedSettings = AppSettings();
      return _cachedSettings!;
    }
  }

  // Save settings to local storage
  static Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert settings to query string format for simple storage
      final Map<String, String> settingsMap = {};
      
      // Add string values
      settingsMap['primaryColor'] = settings.primaryColor;
      settingsMap['themeMode'] = settings.themeMode;
      settingsMap['language'] = settings.language;
      settingsMap['dateFormat'] = settings.dateFormat;
      settingsMap['timeFormat'] = settings.timeFormat;
      settingsMap['currency'] = settings.currency;
      
      // Add boolean values with suffix
      settingsMap['notificationsEnabled_bool'] = settings.notificationsEnabled.toString();
      settingsMap['emailNotifications_bool'] = settings.emailNotifications.toString();
      settingsMap['lowStockAlerts_bool'] = settings.lowStockAlerts.toString();
      settingsMap['soundEffects_bool'] = settings.soundEffects.toString();
      settingsMap['vibrationFeedback_bool'] = settings.vibrationFeedback.toString();
      settingsMap['showConfirmationDialogs_bool'] = settings.showConfirmationDialogs.toString();
      settingsMap['autoPrintReceipts_bool'] = settings.autoPrintReceipts.toString();
      settingsMap['autoBackup_bool'] = settings.autoBackup.toString();
      
      // Add numeric values with suffix
      settingsMap['receiptCopies_int'] = settings.receiptCopies.toString();
      settingsMap['taxRate_double'] = settings.taxRate.toString();
      settingsMap['backupFrequency_int'] = settings.backupFrequency.toString();
      
      // Convert to query string
      final settingsString = settingsMap.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('&');
      
      await prefs.setString(_settingsKey, settingsString);
      
      // Update cache
      _cachedSettings = settings;
      
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
}