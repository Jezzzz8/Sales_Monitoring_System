import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _darkMode = false;
  bool _autoBackup = true;
  String _selectedCurrency = 'PHP';
  String _selectedTheme = 'Light';

  final List<String> _currencies = ['PHP', 'USD', 'EUR', 'GBP', 'JPY'];
  final List<String> _themes = ['Light', 'Dark', 'System'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Settings
          _buildSection('ACCOUNT SETTINGS'),
          _buildSettingItem(
            Icons.person,
            'Profile Information',
            'Update your personal details',
            () => _showProfileDialog(),
          ),
          _buildSettingItem(
            Icons.security,
            'Security',
            'Password and privacy settings',
            () => _showSecurityDialog(),
          ),

          // Application Settings
          _buildSection('APPLICATION SETTINGS'),
          _buildSettingSwitch(
            Icons.notifications,
            'Push Notifications',
            'Receive push notifications',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSettingSwitch(
            Icons.email,
            'Email Notifications',
            'Receive email updates',
            _emailNotifications,
            (value) => setState(() => _emailNotifications = value),
          ),
          _buildSettingSwitch(
            Icons.backup,
            'Auto Backup',
            'Automatically backup data',
            _autoBackup,
            (value) => setState(() => _autoBackup = value),
          ),

          // Display Settings
          _buildSection('DISPLAY SETTINGS'),
          _buildDropdownSetting(
            Icons.color_lens,
            'Theme',
            'Choose app theme',
            _selectedTheme,
            _themes,
            (value) => setState(() => _selectedTheme = value!),
          ),
          _buildSettingSwitch(
            Icons.dark_mode,
            'Dark Mode',
            'Enable dark theme',
            _darkMode,
            (value) => setState(() => _darkMode = value),
          ),

          // Business Settings
          _buildSection('BUSINESS SETTINGS'),
          _buildDropdownSetting(
            Icons.attach_money,
            'Currency',
            'Set default currency',
            _selectedCurrency,
            _currencies,
            (value) => setState(() => _selectedCurrency = value!),
          ),
          _buildSettingItem(
            Icons.receipt,
            'Receipt Settings',
            'Configure receipt printing',
            () => _showReceiptSettings(),
          ),
          _buildSettingItem(
            Icons.local_offer,
            'Tax Settings',
            'Configure tax rates',
            () => _showTaxSettings(),
          ),

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
            Icons.exit_to_app,
            'Logout',
            'Sign out from account',
            () => _confirmLogout(),
            color: Colors.red,
          ),

          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.deepOrange,
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
          activeColor: Colors.deepOrange,
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

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        _saveSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
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
    );
  }

  void _saveSettings() {
    // Implement save settings logic here
    print('Settings saved:');
    print('Notifications: $_notificationsEnabled');
    print('Email Notifications: $_emailNotifications');
    print('Dark Mode: $_darkMode');
    print('Currency: $_selectedCurrency');
    print('Theme: $_selectedTheme');
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Information'),
        content: const Text('Profile update functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: const Text('Security settings functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReceiptSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Settings'),
        content: const Text('Receipt printing configuration will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTaxSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Settings'),
        content: const Text('Tax configuration functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact Support: support@geneslechon.com'),
            SizedBox(height: 8),
            Text('Phone: (02) 1234-5678'),
            SizedBox(height: 8),
            Text('Business Hours: 8:00 AM - 8:00 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gene\'s Lechon Admin System'),
            SizedBox(height: 8),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 2024.01.01'),
            SizedBox(height: 8),
            Text('© 2024 Gene\'s Lechon. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
              // Close both dialogs and navigate to landing page
              Navigator.pop(context); // Close confirmation dialog
              Navigator.pop(context); // Close settings screen
              
              // Use pushReplacementNamed to clear navigation stack and go to landing page
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false, // Remove all routes
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