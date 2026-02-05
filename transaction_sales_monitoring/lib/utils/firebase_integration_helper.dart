// lib/utils/firebase_integration_helper.dart
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseIntegrationHelper {
  static const String _rememberMeKey = 'remember_me';
  static const String _usernameKey = 'saved_username';
  static const String _emailKey = 'saved_email';

  // Save login credentials locally (password is not saved for security)
  static Future<void> saveCredentials({
    required String username,
    required String email,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_emailKey, email);
      await prefs.setBool(_rememberMeKey, true);
    } else {
      await prefs.remove(_usernameKey);
      await prefs.remove(_emailKey);
      await prefs.setBool(_rememberMeKey, false);
    }
  }

  // Get saved credentials
  static Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'rememberMe': prefs.getBool(_rememberMeKey) ?? false,
    };
  }

  // Clear all saved credentials
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_rememberMeKey);
  }
}