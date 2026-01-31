import 'package:flutter/material.dart';
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
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSettings();
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
    } catch (e) {
      print('Error loading settings: $e');
      _settings = AppSettings();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    try {
      await SettingsService.saveSettings(_settings);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'primaryColor':
          _settings = _settings.copyWith(primaryColor: value);
          break;
        case 'themeMode':
          _settings = _settings.copyWith(themeMode: value);
          break;
        case 'language':
          _settings = _settings.copyWith(language: value);
          break;
        case 'dateFormat':
          _settings = _settings.copyWith(dateFormat: value);
          break;
        case 'timeFormat':
          _settings = _settings.copyWith(timeFormat: value);
          break;
        case 'notificationsEnabled':
          _settings = _settings.copyWith(notificationsEnabled: value);
          break;
        case 'emailNotifications':
          _settings = _settings.copyWith(emailNotifications: value);
          break;
        case 'lowStockAlerts':
          _settings = _settings.copyWith(lowStockAlerts: value);
          break;
        case 'soundEffects':
          _settings = _settings.copyWith(soundEffects: value);
          break;
        case 'vibrationFeedback':
          _settings = _settings.copyWith(vibrationFeedback: value);
          break;
        case 'showConfirmationDialogs':
          _settings = _settings.copyWith(showConfirmationDialogs: value);
          break;
        case 'autoPrintReceipts':
          _settings = _settings.copyWith(autoPrintReceipts: value);
          break;
        case 'receiptCopies':
          _settings = _settings.copyWith(receiptCopies: value.toInt());
          break;
        case 'currency':
          _settings = _settings.copyWith(currency: value);
          break;
        case 'taxRate':
          _settings = _settings.copyWith(taxRate: value);
          break;
        case 'autoBackup':
          _settings = _settings.copyWith(autoBackup: value);
          break;
        case 'backupFrequency':
          _settings = _settings.copyWith(backupFrequency: value);
          break;
      }
    });
  }

  Future<void> _resetSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SettingsService.resetSettings();
              await _loadSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final primaryColor = _settings.primaryColorValue;
    final isOwner = _currentUser?.role == UserRole.owner;
    final isAdmin = _currentUser?.role == UserRole.admin;
    final isCashier = _currentUser?.role == UserRole.cashier;
    final isStaff = _currentUser?.role == UserRole.staff;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          if (_currentUser != null) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentUser!.roleIcon,
                        color: primaryColor,
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
                            style: const TextStyle(
                              fontSize: 18,
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Enhanced Personalization Settings
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
          if (isOwner || isAdmin || isStaff)
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
          if (isStaff || isOwner || isAdmin) ...[
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
              backgroundColor: primaryColor,
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
    );
  }

  Widget _buildPersonalizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('PERSONALIZATION'),
        
        // Color Theme with Preview
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.color_lens, color: _settings.primaryColorValue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Theme Color',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _settings.primaryColor,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Color Preview
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _settings.primaryColorValue,
                        _settings.primaryColorValue.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Current Theme',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Color Selection Grid with fixed size buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonSize = constraints.maxWidth / 6;
                    return SizedBox(
                      height: buttonSize * 2 + 16,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                          mainAxisExtent: buttonSize,
                        ),
                        itemCount: SettingsConstants.colorThemes.length,
                        itemBuilder: (context, index) {
                          final theme = SettingsConstants.colorThemes[index];
                          final color = _getColorFromTheme(theme);
                          final isSelected = _settings.primaryColor == theme;
                          
                          return GestureDetector(
                            onTap: () => _updateSetting('primaryColor', theme),
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.grey.shade300,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Icon(Icons.check, 
                                        color: Colors.white, 
                                        size: buttonSize * 0.4,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Theme Mode with Icons
        _buildThemeModeSetting(),
        
        // Language
        _buildDropdownSetting(
          Icons.language,
          'Language',
          'Select app language',
          _settings.language,
          SettingsConstants.languages,
          (value) => _updateSetting('language', value!),
        ),
        
        // Date Format
        _buildDropdownSetting(
          Icons.date_range,
          'Date Format',
          'Select date display format',
          _settings.dateFormat,
          SettingsConstants.dateFormats,
          (value) => _updateSetting('dateFormat', value!),
        ),
        
        // Time Format
        _buildDropdownSetting(
          Icons.access_time,
          'Time Format',
          'Select time display format',
          _settings.timeFormat,
          SettingsConstants.timeFormats,
          (value) => _updateSetting('timeFormat', value!),
        ),
        
        // Date & Time Preview
        _buildDateTimePreview(),
      ],
    );
  }

  Widget _buildThemeModeSetting() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_paint, color: _settings.primaryColorValue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Theme Mode',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  _settings.themeMode,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: SettingsConstants.themeModes.map((mode) {
                final isSelected = _settings.themeMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _updateSetting('themeMode', mode),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? _settings.primaryColorValue.withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? _settings.primaryColorValue 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            mode == 'Light' ? Icons.wb_sunny 
                              : mode == 'Dark' ? Icons.nightlight 
                              : Icons.settings,
                            color: isSelected 
                                ? _settings.primaryColorValue 
                                : Colors.grey.shade600,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected 
                                  ? _settings.primaryColorValue 
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.schedule),
        title: const Text(
          'Backup Frequency',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: const Text(
          'How often to backup data',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: DropdownButton<String>(
          value: currentLabel,
          underline: const SizedBox(),
          items: SettingsConstants.backupFrequencies.map((freq) {
            final label = freq['label'] as String;
            return DropdownMenuItem<String>(
              value: label,
              child: Text(label),
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
    );
  }

  Widget _buildDateTimePreview() {
    final now = DateTime.now();
    final dateFormats = {
      'MM/DD/YYYY': 'MM/dd/yyyy',
      'DD/MM/YYYY': 'dd/MM/yyyy',
      'YYYY-MM-DD': 'yyyy-MM-dd',
      'MMMM DD, YYYY': 'MMMM dd, yyyy',
      'DD MMMM YYYY': 'dd MMMM yyyy',
    };
    
    final timeFormats = {
      '12-hour': 'h:mm a',
      '24-hour': 'HH:mm',
    };
    
    final selectedDateFormat = dateFormats[_settings.dateFormat] ?? 'MM/dd/yyyy';
    final selectedTimeFormat = timeFormats[_settings.timeFormat] ?? 'h:mm a';
    
    final formattedDate = _formatDate(now, selectedDateFormat);
    final formattedTime = _formatTime(now, selectedTimeFormat);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.preview, color: Colors.grey),
                SizedBox(width: 12),
                Text(
                  'Date & Time Preview',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, 
                          color: _settings.primaryColorValue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _settings.primaryColorValue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, 
                          color: _settings.primaryColorValue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _settings.primaryColorValue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Example: Today at $formattedTime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, String format) {
    switch (format) {
      case 'dd/MM/yyyy':
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      case 'yyyy-MM-dd':
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      case 'MMMM dd, yyyy':
        return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
      case 'dd MMMM yyyy':
        return '${date.day} ${_getMonthName(date.month)} ${date.year}';
      default: // 'MM/dd/yyyy'
        return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _formatTime(DateTime time, String format) {
    if (format == 'HH:mm') {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hour % 12;
      final displayHour = hour == 0 ? 12 : hour;
      final amPm = time.hour < 12 ? 'AM' : 'PM';
      return '$displayHour:${time.minute.toString().padLeft(2, '0')} $amPm';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Color _getColorFromTheme(String theme) {
    switch (theme) {
      case 'Deep Orange': return Colors.deepOrange;
      case 'Blue': return Colors.blue;
      case 'Green': return Colors.green;
      case 'Purple': return Colors.purple;
      case 'Red': return Colors.red;
      case 'Teal': return Colors.teal;
      case 'Indigo': return Colors.indigo;
      case 'Pink': return Colors.pink;
      case 'Cyan': return Colors.cyan;
      case 'Amber': return Colors.amber;
      default: return Colors.deepOrange;
    }
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _settings.primaryColorValue,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback onTap,
      {Color color = Colors.black}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingSwitch(IconData icon, String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Switch.adaptive(
          value: value,
          activeColor: _settings.primaryColorValue,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox(),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                    activeColor: _settings.primaryColorValue,
                    inactiveColor: Colors.grey.shade300,
                    onChanged: onChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _settings.primaryColorValue,
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
                  color: _settings.primaryColorValue,
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
                backgroundColor: _settings.primaryColorValue,
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