// lib/services/auth_service.dart - UPDATED VERSION
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase/firebase_config.dart';
import '../models/user_model.dart' as app_user;
import 'user_service.dart';
import 'firebase_auth_service.dart';

class AuthService {
  static app_user.User? _currentUser;
  static SharedPreferences? _prefs;

  // Initialize shared preferences
  static Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Main login method using Firebase Authentication
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Use Firebase Authentication
      final result = await FirebaseAuthService.signInWithEmailAndPassword(email, password);
      
      if (result['success'] == true) {
        final user = result['user'] as app_user.User;
        _currentUser = user;
        
        // Save login state
        await _saveLoginState(user);
        
        return {
          'success': true,
          'user': user,
        };
      } else {
        // If Firebase Auth fails, fallback to Firestore check (for migration)
        return await _fallbackLogin(email, password);
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Login error. Please try again.',
      };
    }
  }

  // Fallback login using Firestore (for migration purposes)
  static Future<Map<String, dynamic>> _fallbackLogin(String email, String password) async {
    try {
      // Get user from Firestore
      final user = await UserService.getUserByEmail(email);
      
      if (user == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }
      
      // Check if user is active
      if (!user.isActive) {
        return {
          'success': false,
          'message': 'Account is deactivated',
        };
      }
      
      // Verify password
      final hashedPassword = hashPassword(password);
      if (user.password != hashedPassword) {
        return {
          'success': false,
          'message': 'Invalid password',
        };
      }
      
      // Set current user
      _currentUser = user;
      
      // Save login state
      await _saveLoginState(user);
      
      // Try to create Firebase Auth account for migration
      try {
        await FirebaseAuthService.createFirebaseUser(
          email,
          password,
          user.toMap(),
        );
      } catch (e) {
        print('Migration warning: $e');
      }
      
      return {
        'success': true,
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed. Please try again.',
      };
    }
  }

  // Save login state to shared preferences
  static Future<void> _saveLoginState(app_user.User user) async {
    await _initPrefs();
    await _prefs!.setString('current_user_id', user.id);
    await _prefs!.setString('current_user_email', user.email);
    await _prefs!.setString('current_user_name', user.fullName);
    await _prefs!.setString('current_user_role', user.role.name);
  }

  // Load saved credentials
  static Future<Map<String, dynamic>> getSavedCredentials() async {
    await _initPrefs();
    return {
      'email': _prefs?.getString('saved_email') ?? '',
      'password': _prefs?.getString('saved_password') ?? '',
      'rememberMe': _prefs?.getBool('remember_me') ?? false,
    };
  }

  // Save credentials if remember me is checked
  static Future<void> saveCredentials(String email, String password, bool rememberMe) async {
    await _initPrefs();
    
    if (rememberMe) {
      await _prefs!.setString('saved_email', email);
      await _prefs!.setString('saved_password', password);
      await _prefs!.setBool('remember_me', true);
    } else {
      await _prefs!.remove('saved_email');
      await _prefs!.remove('saved_password');
      await _prefs!.setBool('remember_me', false);
    }
  }

  // Check authentication status
  static Future<bool> isAuthenticated() async {
    await _initPrefs();
    
    // Check Firebase Auth first
    if (FirebaseAuthService.isAuthenticated()) {
      return true;
    }
    
    // Fallback to shared preferences
    final userId = _prefs?.getString('current_user_id');
    
    if (userId != null && _currentUser == null) {
      // Try to load user from Firestore
      _currentUser = await UserService.getUserById(userId);
    }
    
    return _currentUser != null;
  }

  // Get current user
  static Future<app_user.User?> getCurrentUser() async {
    if (_currentUser == null) {
      await isAuthenticated(); // This will try to load the user
    }
    return _currentUser;
  }

  // Logout
  static Future<void> logout() async {
    await _initPrefs();
    
    // Sign out from Firebase Auth
    await FirebaseAuthService.signOut();
    
    // Clear shared preferences
    await _prefs!.remove('current_user_id');
    await _prefs!.remove('current_user_email');
    await _prefs!.remove('current_user_name');
    await _prefs!.remove('current_user_role');
    
    // Clear current user
    _currentUser = null;
  }

  // Password reset with Firebase
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    return await FirebaseAuthService.sendPasswordResetEmail(email);
  }

  // Check if user is logged in via Firebase
  static bool isFirebaseAuthenticated() {
    return FirebaseAuthService.isAuthenticated();
  }

  // Role-based access control (keep your existing methods)
  static bool hasPermission(app_user.UserRole role, String screen) {
    switch (role) {
      case app_user.UserRole.owner:
        return _ownerPermissions.contains(screen);
      case app_user.UserRole.admin:
        return _adminPermissions.contains(screen);
      case app_user.UserRole.cashier:
        return _cashierPermissions.contains(screen);
      case app_user.UserRole.clerk:
        return _staffPermissions.contains(screen);
    }
  }

  static final List<String> _ownerPermissions = [
    'dashboard',
    'pos',
    'transactions',
    'sales',
    'inventory',
    'products',
    'settings',
    'notifications',
  ];

  static final List<String> _adminPermissions = [
    'dashboard',
    'pos',
    'transactions',
    'sales',
    'inventory',
    'products',
    'settings',
    'notifications',
    'users',
  ];

  static final List<String> _cashierPermissions = [
    'pos',
    'transactions',
    'sales',
    'notifications',
  ];

  static final List<String> _staffPermissions = [
    'inventory',
    'products',
    'notifications',
  ];

  static bool canAccessRoute(app_user.UserRole role, String route) {
    final routeMap = {
      '/dashboard': 'dashboard',
      '/owner-dashboard': 'dashboard',
      '/cashier-dashboard': 'dashboard',
      '/staff-dashboard': 'dashboard',
      '/pos': 'pos',
      '/transactions': 'transactions',
      '/sales': 'sales',
      '/inventory': 'inventory',
      '/products': 'products',
      '/settings': 'settings',
      '/users': 'users',
    };

    final screen = routeMap[route] ?? route;
    return hasPermission(role, screen);
  }
}