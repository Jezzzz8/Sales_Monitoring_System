import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final String _keyUsername = 'admin_username';
  static final String _keyPassword = 'admin_password';
  static final String _keyRememberMe = 'remember_me';

  static Future<bool> login(String username, String password) async {
    // For demo purposes, accept any non-empty credentials
    // In production, this would validate against a database
    if (username.isNotEmpty && password.isNotEmpty) {
      return true;
    }
    return false;
  }

  static Future<void> saveCredentials(
      String username, String password, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyPassword, password);
      await prefs.setBool(_keyRememberMe, true);
    } else {
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyPassword);
      await prefs.setBool(_keyRememberMe, false);
    }
  }

  static Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    final password = prefs.getString(_keyPassword);
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    
    return {
      'username': username,
      'password': password,
      'rememberMe': rememberMe,
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyRememberMe);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) != null;
  }
}