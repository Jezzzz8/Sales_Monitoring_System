// utils/settings_mixin.dart
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

mixin SettingsMixin<T extends StatefulWidget> on State<T> {
  AppSettings? _settings;
  bool _isLoadingSettings = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Listen for settings changes
    SettingsService.notifier.addListener(_onSettingsChanged);
  }
  
  @override
  void dispose() {
    SettingsService.notifier.removeListener(_onSettingsChanged);
    super.dispose();
  }
  
  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _settings = SettingsService.notifier.currentSettings;
      });
    }
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      _settings = await SettingsService.loadSettings();
    } catch (e) {
      print('Error loading settings: $e');
      _settings = AppSettings();
    }
    setState(() => _isLoadingSettings = false);
  }
  
  Color getPrimaryColor() {
    return _settings?.primaryColorValue ?? Colors.deepOrange;
  }
  
  AppSettings? get settings => _settings;
  bool get isLoadingSettings => _isLoadingSettings;
}