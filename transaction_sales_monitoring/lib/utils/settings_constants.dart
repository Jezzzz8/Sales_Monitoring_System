class SettingsConstants {
  // Personalization options
  static const List<String> colorThemes = [
    'Deep Orange',
    'Blue',
    'Green',
    'Purple',
    'Red',
    'Teal',
    'Indigo',
    'Pink',
    'Cyan',
    'Amber',
  ];

  static const List<String> themeModes = [
    'Light',
    'Dark',
    'System',
  ];

  static const List<String> languages = [
    'English',
    'Filipino',
    'Spanish',
    'Chinese',
    'Japanese',
    'Korean',
  ];

  static const List<String> dateFormats = [
    'MM/DD/YYYY',
    'DD/MM/YYYY',
    'YYYY-MM-DD',
    'MMMM DD, YYYY',
    'DD MMMM YYYY',
  ];

  static const List<String> timeFormats = [
    '12-hour',
    '24-hour',
  ];

  // Business options
  static const List<String> currencies = [
    'PHP',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'SGD',
    'HKD',
    'CNY',
  ];

  // Color mapping
  static Map<String, String> get colorHexValues {
    return {
      'Deep Orange': '#FF5722',
      'Blue': '#2196F3',
      'Green': '#4CAF50',
      'Purple': '#9C27B0',
      'Red': '#F44336',
      'Teal': '#009688',
      'Indigo': '#3F51B5',
      'Pink': '#E91E63',
      'Cyan': '#00BCD4',
      'Amber': '#FFC107',
    };
  }

  // Language codes
  static Map<String, String> get languageCodes {
    return {
      'English': 'en',
      'Filipino': 'fil',
      'Spanish': 'es',
      'Chinese': 'zh',
      'Japanese': 'ja',
      'Korean': 'ko',
    };
  }

  // Currency symbols
  static Map<String, String> get currencySymbols {
    return {
      'PHP': '₱',
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'CNY': '¥',
    };
  }

  // Theme descriptions
  static Map<String, String> get themeDescriptions {
    return {
      'Light': 'Bright theme for daytime use',
      'Dark': 'Dark theme for nighttime use',
      'System': 'Follow system theme settings',
    };
  }

  // Backup frequency options
  static const List<Map<String, dynamic>> backupFrequencies = [
    {'label': 'Every 6 hours', 'value': 6},
    {'label': 'Every 12 hours', 'value': 12},
    {'label': 'Every 24 hours', 'value': 24},
    {'label': 'Every 48 hours', 'value': 48},
    {'label': 'Weekly', 'value': 168},
  ];

  // Receipt customization options
  static const List<String> receiptOptions = [
    'Business Logo',
    'Business Address',
    'Business Contact',
    'Thank You Message',
    'QR Code',
    'Tax Breakdown',
    'Payment Method',
    'Cashier Name',
    'Order Number',
    'Date & Time',
  ];

  // Notification sound options
  static const List<String> notificationSounds = [
    'Default',
    'Chime',
    'Bell',
    'Beep',
    'Alert',
    'Custom',
  ];

  // Font size options
  static const List<String> fontSizeOptions = [
    'Small',
    'Medium',
    'Large',
    'Extra Large',
  ];

  // Font family options
  static const List<String> fontFamilyOptions = [
    'Roboto',
    'Open Sans',
    'Montserrat',
    'Poppins',
    'Inter',
    'Lato',
  ];

  // Animation speed options
  static const List<String> animationSpeeds = [
    'Fast',
    'Normal',
    'Slow',
    'Disabled',
  ];

  // Data retention options
  static const List<Map<String, dynamic>> dataRetentionOptions = [
    {'label': '30 days', 'value': 30},
    {'label': '90 days', 'value': 90},
    {'label': '180 days', 'value': 180},
    {'label': '1 year', 'value': 365},
    {'label': 'Forever', 'value': 0},
  ];
}