import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';

class AuthService {
  // Static user cache - no SharedPreferences needed for demo
  static User? _currentUser;
  static Map<String, String> _savedCredentials = {};
  static bool _rememberMe = false;

  // Demo users for testing
  static final List<User> _demoUsers = [
    User(
      id: '1',
      username: 'owner',
      password: _hashPassword('owner123'),
      fullName: 'Gene Lechon Owner',
      email: 'owner@geneslechon.com',
      role: UserRole.owner,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    User(
      id: '2',
      username: 'admin',
      password: _hashPassword('admin123'),
      fullName: 'System Administrator',
      email: 'admin@geneslechon.com',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
    User(
      id: '3',
      username: 'cashier1',
      password: _hashPassword('cashier123'),
      fullName: 'Maria Santos',
      email: 'maria@geneslechon.com',
      role: UserRole.cashier,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    User(
      id: '4',
      username: 'staff1',
      password: _hashPassword('staff123'),
      fullName: 'Juan Dela Cruz',
      email: 'juan@geneslechon.com',
      role: UserRole.staff,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];

  static String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // INSTANT login - no async delays
  static Map<String, dynamic> login(String username, String password) {
    final hashedPassword = _hashPassword(password);
    
    try {
      final user = _demoUsers.firstWhere(
        (u) => u.username == username && u.password == hashedPassword && u.isActive,
        orElse: () => User(id: '', username: '', password: '', fullName: '', email: '', role: UserRole.staff, isActive: false, createdAt: DateTime.now()),
      );

      if (user.id.isNotEmpty) {
        // Set current user
        _currentUser = user;
        
        return {
          'success': true,
          'user': user,
        };
      }
      
      return {
        'success': false,
        'message': 'Invalid username or password',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error. Please try again.',
      };
    }
  }

  // Remove all SharedPreferences calls - use in-memory cache
  static void saveCredentials(String username, String password, bool rememberMe) {
    _rememberMe = rememberMe;
    if (rememberMe) {
      _savedCredentials = {
        'username': username,
        'password': password,
      };
    } else {
      _savedCredentials = {};
    }
  }

  // Instant credentials retrieval
  static Map<String, dynamic> getSavedCredentials() {
    return {
      'username': _savedCredentials['username'] ?? '',
      'password': _savedCredentials['password'] ?? '',
      'rememberMe': _rememberMe,
    };
  }

  // Instant authentication check
  static bool isAuthenticated() {
    return _currentUser != null;
  }

  // Instant current user retrieval - CHANGED to async
  static Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  static void logout() {
    _currentUser = null;
  }

  // User management functions (for admin only)
  static List<User> getUsers() {
    return List.from(_demoUsers);
  }

  static void addUser(User user) {
    final newUser = user.copyWith(
      id: (_demoUsers.length + 1).toString(),
      password: _hashPassword(user.password),
      createdAt: DateTime.now(),
    );
    _demoUsers.add(newUser);
  }

  static void updateUser(User user) {
    final index = _demoUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      final originalPassword = _demoUsers[index].password;
      final updatedUser = user.copyWith(
        password: user.password.isEmpty ? originalPassword : _hashPassword(user.password),
        updatedAt: DateTime.now(),
      );
      _demoUsers[index] = updatedUser;
    }
  }

  static void deleteUser(String userId) {
    _demoUsers.removeWhere((u) => u.id == userId);
  }

  static void toggleUserStatus(String userId) {
    final index = _demoUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _demoUsers[index];
      _demoUsers[index] = user.copyWith(
        isActive: !user.isActive,
        updatedAt: DateTime.now(),
      );
    }
  }

  // Role-based access control
  static bool hasPermission(UserRole role, String screen) {
    switch (role) {
      case UserRole.owner:
        return _ownerPermissions.contains(screen);
      case UserRole.admin:
        return _adminPermissions.contains(screen);
      case UserRole.cashier:
        return _cashierPermissions.contains(screen);
      case UserRole.staff:
        return _staffPermissions.contains(screen);
      }
  }

  // Permission lists
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
    'users', // Only admin has user management
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

  // Check if user can access a route
  static bool canAccessRoute(UserRole role, String route) {
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