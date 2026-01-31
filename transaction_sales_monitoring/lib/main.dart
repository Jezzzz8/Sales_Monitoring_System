import 'package:flutter/material.dart';
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

void main() {
  runApp(const GenesLechonSystemApp());
}

class GenesLechonSystemApp extends StatefulWidget {
  const GenesLechonSystemApp({super.key});

  @override
  State<GenesLechonSystemApp> createState() => _GenesLechonSystemAppState();
}

class _GenesLechonSystemAppState extends State<GenesLechonSystemApp> {
  late Future<AppSettings> _settingsFuture;
  
  @override
  void initState() {
    super.initState();
    _settingsFuture = SettingsService.loadSettings();
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                ),
              ),
            ),
          );
        }
        
        final settings = snapshot.data ?? AppSettings();
        
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Gene's Lechon Transaction & Sales Monitoring System",
          theme: ThemeData(
            primarySwatch: _createMaterialColor(settings.primaryColorValue),
            colorScheme: ColorScheme.fromSeed(
              seedColor: settings.primaryColorValue,
              brightness: Brightness.light,
            ),
            fontFamily: 'Roboto',
            appBarTheme: AppBarTheme(
              backgroundColor: settings.primaryColorValue,
              foregroundColor: Colors.white,
              elevation: 2,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: settings.primaryColorValue,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.primaryColorValue,
                foregroundColor: Colors.white,
              ),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            primarySwatch: _createMaterialColor(settings.primaryColorValue),
            colorScheme: ColorScheme.fromSeed(
              seedColor: settings.primaryColorValue,
              brightness: Brightness.dark,
            ),
            fontFamily: 'Roboto',
            appBarTheme: AppBarTheme(
              backgroundColor: settings.primaryColorValue,
              foregroundColor: Colors.white,
              elevation: 2,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: settings.primaryColorValue,
              foregroundColor: Colors.white,
            ),
            useMaterial3: true,
          ),
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
        );
      },
    );
  }
  
  MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(color.value, swatch);
  }
}