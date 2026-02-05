// lib/main.dart - SEPARATE FILE
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'providers/theme_provider.dart';
import 'screens/admin_login.dart';
import 'screens/category_management.dart';
import 'screens/sales_monitoring.dart';
import 'screens/inventory_monitoring.dart';
import 'screens/product_management.dart';
import 'screens/user_management.dart';
import 'screens/admin_dashboard.dart';
import 'screens/owner_dashboard.dart';
import 'screens/cashier_dashboard.dart';
import 'screens/staff_dashboard.dart';
import 'screens/settings.dart';
import 'services/settings_service.dart';
import 'models/settings_model.dart';
import 'utils/theme_manager.dart';
import 'firebase/firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  
  try {
    await FirebaseConfig.initialize();
    print('Firebase initialized successfully before runApp');
  } catch (e) {
    print('Critical: Firebase failed to initialize: $e');
  }

  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider({
        'colorName': 'Deep Orange',
        'themeMode': 'Light',
      }),
      child: const GenesLechonSystemApp(),
    ),
  );
}

class GenesLechonSystemApp extends StatefulWidget {
  const GenesLechonSystemApp({super.key});

  @override
  State<GenesLechonSystemApp> createState() => _GenesLechonSystemAppState();
}

class _GenesLechonSystemAppState extends State<GenesLechonSystemApp> {
  AppSettings? _currentSettings;
  bool _hasInternet = true;
  bool _checkingInternet = true;
  bool _showNoInternetDialog = false;
  bool _firebaseInitialized = false;
  bool _settingsLoaded = false;
  
  @override
  void initState() {
    super.initState();
    
    _firebaseInitialized = FirebaseConfig.isInitialized;
    
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    await _loadSettings();
    _checkInternetConnection(); 
    
    if (mounted) {
      setState(() {
        _checkingInternet = false;
      });
    }
  }
  
  Future<void> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          setState(() => _hasInternet = false);
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_showNoInternetDialog) {
            _showInternetDialog();
          }
        });
      }
    } catch (e) {
      print('Error checking internet: $e');
    }
  }
  
  void _showInternetDialog() {
    if (!mounted) return;
    
    _showNoInternetDialog = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              SizedBox(width: 10),
              Text('No Internet Connection'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gene\'s Lechon System requires internet connection to function properly.'),
              SizedBox(height: 10),
              Text('Please check your:'),
              SizedBox(height: 5),
              Text('• WiFi connection'),
              Text('• Mobile data'),
              Text('• Network settings'),
              SizedBox(height: 15),
              Text(
                'The app will automatically retry when connection is restored.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showNoInternetDialog = false;
                _checkInternetConnection();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showNoInternetDialog = false;
              },
              child: const Text('Continue Offline'),
            ),
          ],
        );
      },
    ).then((_) {
      _showNoInternetDialog = false;
    });
  }
  
  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _currentSettings = SettingsService.notifier.currentSettings;
      });
    }
  }
  
  Future<void> _loadSettings() async {
    try {
      final settings = await SettingsService.loadSettings(forceReload: true);
      if (mounted) {
        setState(() {
          _currentSettings = settings;
          _settingsLoaded = true;
        });
      }
      
      SettingsService.notifier.addListener(_onSettingsChanged);
    } catch (e) {
      print('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _settingsLoaded = true;
        });
      }
    }
  }
  
  @override
  void dispose() {
    SettingsService.notifier.removeListener(_onSettingsChanged);
    super.dispose();
  }
  
  Widget _buildLoadingScreen() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.deepOrange.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.deepOrange, width: 2),
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 60,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                color: Colors.deepOrange,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                _getLoadingMessage(),
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getLoadingMessage() {
    if (!_firebaseInitialized) {
      return 'Initializing Firebase...';
    } else if (!_settingsLoaded) {
      return 'Loading settings...';
    } else if (_checkingInternet) {
      return 'Checking connection...';
    }
    return 'Loading app...';
  }
  
  bool get _isAppReady {
    return _firebaseInitialized && _settingsLoaded;
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isAppReady) {
      return _buildLoadingScreen();
    }

    final settings = _currentSettings ?? AppSettings.defaultSettings();
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Gene's Lechon Transaction & Sales Monitoring System",
      theme: ThemeManager.lightTheme(settings.primaryColor),
      darkTheme: ThemeManager.darkTheme(settings.primaryColor),
      themeMode: settings.themeModeValue,
      home: const AdminLogin(),
      routes: {
        '/login': (context) => const AdminLogin(),
        '/dashboard': (context) => const AdminDashboard(),
        '/owner-dashboard': (context) => const OwnerDashboard(),
        '/cashier-dashboard': (context) => const CashierDashboard(),
        '/staff-dashboard': (context) => const StaffDashboard(),
        '/inventory-categories': (context) => const CategoryManagement(categoryType: 'inventory'),
        '/product-categories': (context) => const CategoryManagement(categoryType: 'product'),
        '/sales': (context) => const SalesMonitoring(),
        '/inventory': (context) => const InventoryMonitoring(),
        '/products': (context) => const ProductManagement(),
        '/users': (context) => const UserManagement(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}