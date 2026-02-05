import 'package:flutter/material.dart';
import '../utils/theme_manager.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../utils/settings_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  late AppSettings _originalSettings;
  bool _isLoading = true;
  User? _currentUser;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSettings();
    
    // Listen for theme changes
    SettingsService.notifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    SettingsService.notifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      // When theme changes externally, update our local settings
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final updatedSettings = await SettingsService.loadSettings();
        if (mounted) {
          setState(() {
            _settings = updatedSettings;
            _originalSettings = updatedSettings.copyWith();
            _hasUnsavedChanges = false;
          });
        }
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      _settings = await SettingsService.loadSettings();
      _originalSettings = _settings.copyWith();
    } catch (e) {
      print('Error loading settings: $e');
      _settings = AppSettings();
      _originalSettings = AppSettings();
    }
    setState(() => _isLoading = false);
  }

  Future<bool> _saveSettings() async {
    try {
      await SettingsService.saveSettings(_settings);
      
      // Update the theme provider immediately
      final themeProvider = ThemeProvider.instance(context);
      await themeProvider.refreshTheme();
      
      setState(() {
        _hasUnsavedChanges = false;
        _originalSettings = _settings.copyWith();
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  void _updateSetting(String key, dynamic value) {
    // Create new settings with the update
    AppSettings newSettings;
    
    switch (key) {
      case 'primaryColor':
        newSettings = _settings.copyWith(primaryColor: value);
        break;
      case 'themeMode':
        newSettings = _settings.copyWith(themeMode: value);
        break;
      case 'language':
        newSettings = _settings.copyWith(language: value);
        break;
      case 'dateFormat':
        newSettings = _settings.copyWith(dateFormat: value);
        break;
      case 'timeFormat':
        newSettings = _settings.copyWith(timeFormat: value);
        break;
      case 'notificationsEnabled':
        newSettings = _settings.copyWith(notificationsEnabled: value);
        break;
      case 'emailNotifications':
        newSettings = _settings.copyWith(emailNotifications: value);
        break;
      case 'lowStockAlerts':
        newSettings = _settings.copyWith(lowStockAlerts: value);
        break;
      case 'soundEffects':
        newSettings = _settings.copyWith(soundEffects: value);
        break;
      case 'vibrationFeedback':
        newSettings = _settings.copyWith(vibrationFeedback: value);
        break;
      case 'showConfirmationDialogs':
        newSettings = _settings.copyWith(showConfirmationDialogs: value);
        break;
      case 'autoPrintReceipts':
        newSettings = _settings.copyWith(autoPrintReceipts: value);
        break;
      case 'receiptCopies':
        newSettings = _settings.copyWith(receiptCopies: value.toInt());
        break;
      case 'currency':
        newSettings = _settings.copyWith(currency: value);
        break;
      case 'taxRate':
        newSettings = _settings.copyWith(taxRate: value);
        break;
      case 'autoBackup':
        newSettings = _settings.copyWith(autoBackup: value);
        break;
      case 'backupFrequency':
        newSettings = _settings.copyWith(backupFrequency: value);
        break;
      default:
        return;
    }
    
    setState(() {
      _settings = newSettings;
      _hasUnsavedChanges = true;
      SettingsService.setPendingChanges(_settings);
    });
    
    // INSTANT THEME UPDATE - Apply immediately without waiting
    if (key == 'primaryColor' || key == 'themeMode') {
      _applyThemeUpdateInstantly(newSettings, key); // Pass the key here
    }
  }

  void _applyThemeUpdateInstantly(AppSettings newSettings, String settingKey) {
    // Update the theme provider immediately
    final themeProvider = ThemeProvider.instance(context);
    
    // Update theme provider with new settings
    themeProvider.updateSettings(newSettings);
    
    // Also update the SettingsService cache
    SettingsService.setPendingChanges(newSettings);
    
    // Force immediate rebuild of the entire SettingsScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // This ensures the preview updates instantly
        });
      }
    });
    
    // Show immediate feedback with appropriate message
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    
    String message;
    Color snackbarColor;
    
    if (settingKey == 'both') {
      message = 'Theme reset to defaults! (${newSettings.primaryColor}, ${newSettings.themeMode})';
      snackbarColor = ThemeProvider.of(context).primaryColor;
    } else if (settingKey == 'primaryColor') {
      message = 'Color updated instantly! (${newSettings.primaryColor})';
      snackbarColor = ThemeManager.seedColors[newSettings.primaryColor] ?? ThemeManager.seedColors['Deep Orange']!;
    } else {
      // Theme mode change
      final isDark = newSettings.themeMode == 'Dark';
      message = 'Switched to ${newSettings.themeMode} Mode!';
      snackbarColor = isDark ? Colors.grey[900]! : Colors.grey[100]!;
      
      // Special effect for theme mode change
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: snackbarColor,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: snackbarColor,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to save them before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                // If discarding, revert to original settings
                if (_settings.primaryColor != _originalSettings.primaryColor || 
                    _settings.themeMode != _originalSettings.themeMode) {
                  // Revert theme changes
                  final themeProvider = ThemeProvider.instance(context);
                  themeProvider.updateSettings(_originalSettings);
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () async {
                final success = await _saveSettings();
                Navigator.of(context).pop(success);
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true;
  }

  Future<void> _resetSettings() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final defaultSettings = AppSettings();
      setState(() {
        _settings = defaultSettings;
        _hasUnsavedChanges = true;
        SettingsService.setPendingChanges(_settings);
      });
      
      // Apply theme changes immediately - pass 'both' since we're resetting both color and theme
      _applyThemeUpdateInstantly(defaultSettings, 'both');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings have been reset to defaults. Don\'t forget to save!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = ThemeProvider.of(context);
    final isOwner = _currentUser?.role == UserRole.owner;
    final isAdmin = _currentUser?.role == UserRole.admin;
    final isCashier = _currentUser?.role == UserRole.cashier;
    final isClerk = _currentUser?.role == UserRole.clerk;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: theme.primaryColor,
          foregroundColor: theme.onPrimaryColor,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: theme.onPrimaryColor),
              onPressed: () {
                _loadSettings();
                final themeProvider = ThemeProvider.instance(context);
                themeProvider.refreshTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings reloaded'),
                    backgroundColor: theme.primaryColor,
                  ),
                );
              },
              tooltip: 'Reload Settings',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Info Card
            if (_currentUser != null) ...[
              theme.createCard(
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentUser!.roleIcon,
                        color: theme.primaryColor, // INSTANT: Icon color updates
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentUser!.fullName,
                            style: theme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _currentUser!.roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentUser!.roleDisplayName,
                              style: TextStyle(
                                color: _currentUser!.roleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentUser!.email,
                            style: theme.bodySmall.copyWith(
                              color: theme.getSubtitleColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Personalization Section with M3 theme preview
            _buildPersonalizationSection(),

            // Notification Settings
            _buildSection('NOTIFICATIONS'),
            _buildSettingSwitch(
              Icons.notifications,
              'Push Notifications',
              'Receive push notifications',
              _settings.notificationsEnabled,
              (value) => _updateSetting('notificationsEnabled', value),
            ),
            _buildSettingSwitch(
              Icons.email,
              'Email Notifications',
              'Receive email updates',
              _settings.emailNotifications,
              (value) => _updateSetting('emailNotifications', value),
            ),
            if (isOwner || isAdmin || isClerk)
              _buildSettingSwitch(
                Icons.inventory,
                'Low Stock Alerts',
                'Get alerts for low stock items',
                _settings.lowStockAlerts,
                (value) => _updateSetting('lowStockAlerts', value),
              ),

            // Interface Settings
            _buildSection('INTERFACE'),
            _buildSettingSwitch(
              Icons.volume_up,
              'Sound Effects',
              'Enable sound effects',
              _settings.soundEffects,
              (value) => _updateSetting('soundEffects', value),
            ),
            _buildSettingSwitch(
              Icons.vibration,
              'Vibration Feedback',
              'Enable vibration feedback',
              _settings.vibrationFeedback,
              (value) => _updateSetting('vibrationFeedback', value),
            ),
            _buildSettingSwitch(
              Icons.confirmation_number,
              'Confirmation Dialogs',
              'Show confirmation dialogs',
              _settings.showConfirmationDialogs,
              (value) => _updateSetting('showConfirmationDialogs', value),
            ),

            // Cashier-specific Settings
            if (isCashier || isOwner || isAdmin) ...[
              _buildSection('CASHIER SETTINGS'),
              _buildSettingSwitch(
                Icons.print,
                'Auto Print Receipts',
                'Automatically print receipts after sale',
                _settings.autoPrintReceipts,
                (value) => _updateSetting('autoPrintReceipts', value),
              ),
              _buildSliderSetting(
                Icons.content_copy,
                'Receipt Copies',
                'Number of receipt copies to print',
                _settings.receiptCopies.toDouble(),
                1,
                3,
                (value) => _updateSetting('receiptCopies', value.toInt()),
              ),
            ],

            // Business Settings (Owner/Admin only)
            if (isOwner || isAdmin) ...[
              _buildSection('BUSINESS SETTINGS'),
              _buildDropdownSetting(
                Icons.attach_money,
                'Currency',
                'Set default currency',
                _settings.currency,
                SettingsConstants.currencies,
                (value) => _updateSetting('currency', value!),
              ),
              _buildSliderSetting(
                Icons.percent,
                'Tax Rate',
                'Set default tax rate (%)',
                _settings.taxRate,
                0,
                30,
                (value) => _updateSetting('taxRate', value),
              ),
            ],

            // Data Settings
            if (isClerk || isOwner || isAdmin) ...[
              _buildSection('DATA SETTINGS'),
              _buildSettingSwitch(
                Icons.backup,
                'Auto Backup',
                'Automatically backup inventory data',
                _settings.autoBackup,
                (value) => _updateSetting('autoBackup', value),
              ),
              _buildBackupFrequencyDropdown(),
            ],

            // System Settings
            _buildSection('SYSTEM'),
            _buildSettingItem(
              Icons.help,
              'Help & Support',
              'Get help and contact support',
              () => _showHelpDialog(),
            ),
            _buildSettingItem(
              Icons.info,
              'About',
              'App version and information',
              () => _showAboutDialog(),
            ),
            _buildSettingItem(
              Icons.data_usage,
              'Data & Storage',
              'Manage app data and storage',
              () => _showDataManagement(),
            ),

            // Logout
            _buildSettingItem(
              Icons.exit_to_app,
              'Logout',
              'Sign out from account',
              () => _confirmLogout(),
              color: Colors.red,
            ),

            const SizedBox(height: 32),
          
            // Save Button
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor, // INSTANT: Button color updates
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'SAVE SETTINGS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Reset Button
            OutlinedButton(
              onPressed: _resetSettings,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'RESET TO DEFAULTS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection() {
    final theme = ThemeProvider.of(context);
    final colorName = _settings.primaryColor;
    final color = ThemeManager.seedColors[colorName] ?? ThemeManager.seedColors['Deep Orange']!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        theme.createSectionHeader('PERSONALIZATION'),
        
        // Theme Preview Card
        theme.createCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Preview Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.color_lens,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Preview',
                          style: theme.titleMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$colorName • ${_settings.themeMode} Mode',
                          style: theme.bodySmall.copyWith(
                            color: theme.getSubtitleColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'INSTANT',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Theme Preview Widget
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.isDarkMode ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    // Preview App Bar
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              theme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              color: ThemeManager.getOnPrimaryColor(color),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${theme.isDarkMode ? 'Dark' : 'Light'} Mode',
                              style: TextStyle(
                                color: ThemeManager.getOnPrimaryColor(color),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Preview Content
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              theme.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme.isDarkMode ? 'Dark Theme Active' : 'Light Theme Active',
                                  style: theme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Tap to change theme mode',
                                  style: theme.bodySmall.copyWith(
                                    color: theme.getSubtitleColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bolt,
                                  color: color,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Live',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Color Selection
              Text(
                'Primary Color',
                style: theme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ThemeManager.seedColors.entries.map((entry) {
                  final name = entry.key;
                  final swatchColor = entry.value;
                  final isSelected = _settings.primaryColor == name;
                  
                  return GestureDetector(
                    onTap: () => _updateSetting('primaryColor', name),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: swatchColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.getTextColor(emphasized: true)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: swatchColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? Center(
                                  child: Icon(
                                    Icons.check,
                                    color: ThemeManager.getOnPrimaryColor(swatchColor),
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name.split(' ').first,
                          style: theme.bodySmall.copyWith(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? color : theme.getSubtitleColor(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Theme Mode Selection
        _buildThemeModeSelector(),
        
        // Language Selection
        _buildDropdownSetting(
          Icons.translate,
          'Language',
          'App display language',
          _settings.language,
          SettingsConstants.languages,
          (value) => _updateSetting('language', value!),
        ),
        
        // Date & Time Format Section
        theme.createCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.date_range, color: theme.getTextColor()),
                  const SizedBox(width: 12),
                  Text(
                    'Date & Time Format',
                    style: theme.titleMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date Format
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date Format',
                          style: theme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How dates are displayed',
                          style: theme.bodySmall.copyWith(
                            color: theme.getSubtitleColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButton<String>(
                      value: _settings.dateFormat,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: SettingsConstants.dateFormats.map((format) {
                        return DropdownMenuItem<String>(
                          value: format,
                          child: Text(
                            format,
                            style: TextStyle(
                              color: theme.getTextColor(),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => _updateSetting('dateFormat', value!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              Divider(
                color: theme.getSubtitleColor().withOpacity(0.2),
                height: 1,
              ),
              const SizedBox(height: 12),
              
              // Time Format
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Format',
                          style: theme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '12-hour or 24-hour clock',
                          style: theme.bodySmall.copyWith(
                            color: theme.getSubtitleColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButton<String>(
                      value: _settings.timeFormat,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: SettingsConstants.timeFormats.map((format) {
                        return DropdownMenuItem<String>(
                          value: format,
                          child: Text(
                            format,
                            style: TextStyle(
                              color: theme.getTextColor(),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => _updateSetting('timeFormat', value!),
                    ),
                  ),
                ],
              ),
              
              // Live Preview
              const SizedBox(height: 16),
              Divider(
                color: theme.getSubtitleColor().withOpacity(0.2),
                height: 1,
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Preview',
                      style: theme.bodySmall.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date: ${_formatDate(DateTime.now(), _settings.displayDateFormat)}',
                                style: theme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time: ${_formatTime(DateTime.now(), _settings.is24HourFormat ? 'HH:mm' : 'h:mm a')}',
                                style: theme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.visibility,
                          color: theme.primaryColor,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildThemeModeSelector() {
    final theme = ThemeProvider.of(context);
    
    return theme.createCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.brightness_medium, color: theme.getTextColor()),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Theme Mode',
                  style: theme.titleMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'INSTANT',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            children: SettingsConstants.themeModes.map((mode) {
              final isSelected = _settings.themeMode == mode;
              final isDark = mode == 'Dark';
              final isSystem = mode == 'System';
              
              return GestureDetector(
                onTap: () => _updateSetting('themeMode', mode),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 72) / 3,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor.withOpacity(0.1)
                        : theme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : theme.isDarkMode
                              ? Colors.grey.shade800
                              : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isSystem
                            ? Icons.settings_suggest_outlined
                            : isDark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.getIconColor(),
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mode,
                        style: theme.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? theme.primaryColor
                              : theme.getTextColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Changes apply instantly to current session',
            style: theme.bodySmall.copyWith(
              color: theme.getSubtitleColor(),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupFrequencyDropdown() {
    // Find the current backup frequency label
    String currentLabel = 'Every 24 hours';
    for (var freq in SettingsConstants.backupFrequencies) {
      if (freq['value'] == _settings.backupFrequency) {
        currentLabel = freq['label'] as String;
        break;
      }
    }
    
    final theme = ThemeProvider.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.surfaceColor,
      elevation: 1,
      child: ListTile(
        leading: Icon(Icons.schedule, color: theme.getTextColor()),
        title: Text(
          'Backup Frequency',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.getTextColor(),
          ),
        ),
        subtitle: Text(
          'How often to backup data',
          style: TextStyle(
            fontSize: 12,
            color: theme.getSubtitleColor(),
          ),
        ),
        trailing: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: theme.surfaceColor,
          ),
          child: DropdownButton<String>(
            value: currentLabel,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: theme.getTextColor()),
            style: TextStyle(color: theme.getTextColor()),
            dropdownColor: theme.surfaceColor,
            items: SettingsConstants.backupFrequencies.map((freq) {
              final label = freq['label'] as String;
              return DropdownMenuItem<String>(
                value: label,
                child: Text(label, style: TextStyle(color: theme.getTextColor())),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                final freq = SettingsConstants.backupFrequencies
                    .firstWhere((f) => f['label'] == value)['value'] as int;
                _updateSetting('backupFrequency', freq);
              }
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, String formatPattern) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final monthName = _getMonthName(date.month);
    
    switch (formatPattern) {
      case 'DD/MM/YYYY':
        return '$day/$month/$year';
      case 'YYYY-MM-DD':
        return '$year-$month-$day';
      case 'MMMM DD, YYYY':
        return '$monthName $day, $year';
      case 'DD MMMM YYYY':
        return '$day $monthName $year';
      default: // 'MM/DD/YYYY'
        return '$month/$day/$year';
    }
  }

  String _formatTime(DateTime time, String formatPattern) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    
    if (formatPattern == 'HH:mm') {
      return '$hour:$minute';
    } else {
      final hour12 = time.hour % 12;
      final displayHour = hour12 == 0 ? '12' : hour12.toString().padLeft(2, '0');
      final amPm = time.hour < 12 ? 'AM' : 'PM';
      return '$displayHour:$minute $amPm';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildSection(String title) {
    final theme = ThemeProvider.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback onTap,
    {Color color = Colors.black}) {
    final theme = ThemeProvider.of(context);
    final effectiveColor = color == Colors.black ? theme.getIconColor() : color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.surfaceColor,
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: effectiveColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.getTextColor(),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.getSubtitleColor(),
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: theme.getIconColor()),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingSwitch(IconData icon, String title, String subtitle, bool value,
    ValueChanged<bool> onChanged) {
    final theme = ThemeProvider.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.surfaceColor,
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: theme.getIconColor()),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.getTextColor(),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.getSubtitleColor(),
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          activeColor: theme.primaryColor,
          inactiveTrackColor: theme.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
          thumbColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.white;
              }
              return theme.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade50;
            },
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    IconData icon,
    String title,
    String subtitle,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final theme = ThemeProvider.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.surfaceColor,
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: theme.getIconColor()),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.getTextColor(),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: theme.getSubtitleColor(),
          ),
        ),
        trailing: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: theme.surfaceColor,
          ),
          child: DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: theme.getIconColor()),
            style: TextStyle(color: theme.getTextColor()),
            dropdownColor: theme.surfaceColor,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(color: theme.getTextColor())),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    IconData icon,
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final theme = ThemeProvider.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.surfaceColor,
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: theme.getIconColor()),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.getTextColor(),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.getSubtitleColor(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: (max - min).toInt(),
                    label: value.toStringAsFixed(1),
                    activeColor: theme.primaryColor,
                    inactiveColor: theme.isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    thumbColor: theme.primaryColor,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help? Contact our support team:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildContactItem(Icons.email, 'Email:', 'support@geneslechon.com'),
              _buildContactItem(Icons.phone, 'Phone:', '(02) 1234-5678'),
              _buildContactItem(Icons.access_time, 'Business Hours:', '8:00 AM - 8:00 PM'),
              _buildContactItem(Icons.location_on, 'Address:', '123 Main St, Cagayan de Oro City'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final theme = ThemeProvider.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  Icons.restaurant,
                  size: 60,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Gene\'s Lechon Admin System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              _buildAboutItem('Version:', '1.0.0'),
              _buildAboutItem('Build:', '2024.01.01'),
              _buildAboutItem('Last Updated:', 'January 2024'),
              _buildAboutItem('Developer:', 'Gene\'s Lechon IT Team'),
              _buildAboutItem('License:', 'Proprietary'),
              const SizedBox(height: 16),
              const Text(
                '© 2024 Gene\'s Lechon. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDataManagement() {
    final theme = ThemeProvider.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data & Storage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage your app data and storage:'),
            const SizedBox(height: 16),
            _buildStorageItem('Settings', '2 MB'),
            _buildStorageItem('Cache', '10 MB'),
            _buildStorageItem('Backups', '35 MB'),
            const Divider(),
            _buildStorageItem('Total Storage', '47 MB'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Clear cache
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Clear Cache'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(String label, String size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            size,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AuthService.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}