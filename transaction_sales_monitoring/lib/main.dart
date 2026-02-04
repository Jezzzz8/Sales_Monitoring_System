import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/theme_provider.dart';
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

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider({
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
  
  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _loadSettings();
    
    // Listen for settings changes
    SettingsService.notifier.addListener(_onSettingsChanged);
    
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      _checkInternetConnection();
    });
  }
  
  @override
  void dispose() {
    SettingsService.notifier.removeListener(_onSettingsChanged);
    super.dispose();
  }
  
  Future<void> _checkInternetConnection() async {
    setState(() {
      _checkingInternet = true;
    });
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = connectivityResult != ConnectivityResult.none;
      
      setState(() {
        _hasInternet = hasConnection;
        _checkingInternet = false;
      });
      
      // Show/hide dialog based on connection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasConnection && !_showNoInternetDialog && mounted) {
          _showNoInternetDialog = true;
          _showInternetDialog();
        } else if (hasConnection && _showNoInternetDialog && mounted) {
          _showNoInternetDialog = false;
          // Dialog will auto-dismiss when connection is restored
        }
      });
    } catch (e) {
      setState(() {
        _hasInternet = false;
        _checkingInternet = false;
      });
    }
  }
  
  void _showInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must take action
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              const SizedBox(width: 10),
              const Text('No Internet Connection'),
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
              child: const Text('Exit App'),
            ),
          ],
        );
      },
    ).then((_) {
      // When dialog is dismissed
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
    final settings = await SettingsService.loadSettings(forceReload: true);
    setState(() {
      _currentSettings = settings;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Check internet connection
    if (_checkingInternet) {
      return Material(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Checking connection...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Get the theme provider from context
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Only build the app when theme provider is ready
    if (themeProvider.isLoading || _currentSettings == null) {
      return const Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final settings = _currentSettings!;
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Gene's Lechon Transaction & Sales Monitoring System",
      // Use ThemeManager to get proper themes
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
        '/inventory-categories': (context) => CategoryManagement(categoryType: 'inventory'),
        '/product-categories': (context) => CategoryManagement(categoryType: 'product'),
        '/sales': (context) => const SalesMonitoring(),
        '/inventory': (context) => const InventoryMonitoring(),
        '/products': (context) => const ProductManagement(),
        '/users': (context) => const UserManagement(),
        '/settings': (context) => const SettingsScreen(),
      },
      builder: (context, child) {
        return AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: child!,
        );
      },
    );
  }
}