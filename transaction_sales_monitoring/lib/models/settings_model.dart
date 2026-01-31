import 'package:flutter/material.dart';

class AppSettings {
  // Personalization
  String primaryColor;
  String themeMode;
  String language;
  String dateFormat;
  String timeFormat;
  
  // Notifications
  bool notificationsEnabled;
  bool emailNotifications;
  bool lowStockAlerts;
  bool soundEffects;
  bool vibrationFeedback;
  
  // Interface
  bool showConfirmationDialogs;
  bool autoPrintReceipts;
  int receiptCopies;
  
  // Business
  String currency;
  double taxRate;
  
  // Data
  bool autoBackup;
  int backupFrequency; // in hours
  
  // Default constructor with default values
  AppSettings({
    this.primaryColor = 'Deep Orange',
    this.themeMode = 'Light',
    this.language = 'English',
    this.dateFormat = 'MM/DD/YYYY',
    this.timeFormat = '12-hour',
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.lowStockAlerts = true,
    this.soundEffects = true,
    this.vibrationFeedback = true,
    this.showConfirmationDialogs = true,
    this.autoPrintReceipts = false,
    this.receiptCopies = 1,
    this.currency = 'PHP',
    this.taxRate = 12.0,
    this.autoBackup = true,
    this.backupFrequency = 24,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'themeMode': themeMode,
      'language': language,
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'lowStockAlerts': lowStockAlerts,
      'soundEffects': soundEffects,
      'vibrationFeedback': vibrationFeedback,
      'showConfirmationDialogs': showConfirmationDialogs,
      'autoPrintReceipts': autoPrintReceipts,
      'receiptCopies': receiptCopies,
      'currency': currency,
      'taxRate': taxRate,
      'autoBackup': autoBackup,
      'backupFrequency': backupFrequency,
    };
  }

  // Create from Map
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      primaryColor: map['primaryColor'] ?? 'Deep Orange',
      themeMode: map['themeMode'] ?? 'Light',
      language: map['language'] ?? 'English',
      dateFormat: map['dateFormat'] ?? 'MM/DD/YYYY',
      timeFormat: map['timeFormat'] ?? '12-hour',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      emailNotifications: map['emailNotifications'] ?? true,
      lowStockAlerts: map['lowStockAlerts'] ?? true,
      soundEffects: map['soundEffects'] ?? true,
      vibrationFeedback: map['vibrationFeedback'] ?? true,
      showConfirmationDialogs: map['showConfirmationDialogs'] ?? true,
      autoPrintReceipts: map['autoPrintReceipts'] ?? false,
      receiptCopies: map['receiptCopies'] ?? 1,
      currency: map['currency'] ?? 'PHP',
      taxRate: map['taxRate']?.toDouble() ?? 12.0,
      autoBackup: map['autoBackup'] ?? true,
      backupFrequency: map['backupFrequency'] ?? 24,
    );
  }

  // Copy with method for updates
  AppSettings copyWith({
    String? primaryColor,
    String? themeMode,
    String? language,
    String? dateFormat,
    String? timeFormat,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? lowStockAlerts,
    bool? soundEffects,
    bool? vibrationFeedback,
    bool? showConfirmationDialogs,
    bool? autoPrintReceipts,
    int? receiptCopies,
    String? currency,
    double? taxRate,
    bool? autoBackup,
    int? backupFrequency,
  }) {
    return AppSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      soundEffects: soundEffects ?? this.soundEffects,
      vibrationFeedback: vibrationFeedback ?? this.vibrationFeedback,
      showConfirmationDialogs: showConfirmationDialogs ?? this.showConfirmationDialogs,
      autoPrintReceipts: autoPrintReceipts ?? this.autoPrintReceipts,
      receiptCopies: receiptCopies ?? this.receiptCopies,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
    );
  }

  // Helper methods
  Color get primaryColorValue {
    final colorMap = {
      'Deep Orange': Colors.deepOrange,
      'Blue': Colors.blue,
      'Green': Colors.green,
      'Purple': Colors.purple,
      'Red': Colors.red,
      'Teal': Colors.teal,
      'Indigo': Colors.indigo,
      'Pink': Colors.pink,
      'Cyan': Colors.cyan,
      'Amber': Colors.amber,
    };
    return colorMap[primaryColor] ?? Colors.deepOrange;
  }

  ThemeMode get themeModeValue {
    switch (themeMode) {
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  String get displayDateFormat {
    switch (dateFormat) {
      case 'DD/MM/YYYY':
        return 'dd/MM/yyyy';
      case 'YYYY-MM-DD':
        return 'yyyy-MM-dd';
      default:
        return 'MM/dd/yyyy';
    }
  }

  bool get is24HourFormat => timeFormat == '24-hour';
}