import 'package:flutter/material.dart';
import 'screens/landing_page.dart';
import 'screens/admin_login.dart';
import 'screens/dashboard.dart';
import 'screens/category_management.dart';
import 'screens/sales_monitoring.dart';
import 'screens/inventory_monitoring.dart';
import 'screens/product_management.dart';

void main() {
  runApp(const GenesLechonSystemApp());
}

class GenesLechonSystemApp extends StatelessWidget {
  const GenesLechonSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Gene's Lechon Transaction & Sales Monitoring System",
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const LandingPage(),
      routes: {
        '/login': (context) => const AdminLogin(),
        '/dashboard': (context) => const Dashboard(),
        '/inventory-categories': (context) => CategoryManagement(categoryType: 'inventory'),
        '/product-categories': (context) => CategoryManagement(categoryType: 'product'),
        '/sales': (context) => const SalesMonitoring(),
        '/inventory': (context) => const InventoryMonitoring(),
        '/products': (context) => const ProductManagement(),
      },
    );
  }
}