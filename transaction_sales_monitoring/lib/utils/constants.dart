import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = "Gene's Lechon System";
  static const String appVersion = "1.0.0";
  
  // Business Information
  static const String businessName = "Gene's Lechon";
  static const String businessAddress = "123 Main St, Cagayan de Oro City";
  static const String businessPhone = "(02) 8123-4567";
  static const String businessEmail = "contact@geneslechon.com";
  
  // Business Hours
  static const String businessHours = "8:00 AM - 8:00 PM (Monday-Sunday)";
  
  // Default values
  static const double taxRate = 0.12; // 12% VAT
  static const int defaultReorderLevel = 10;
  static const int maxLechonPerOrder = 5;
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'GCash',
    'Bank Transfer',
  ];
  
  // Product Categories
  static const List<String> productCategories = [
    'Whole Lechon',
    'Lechon Belly',
    'Appetizers',
    'Main Course',
    'Desserts',
  ];
  
  // Inventory Categories
  static const List<String> inventoryCategories = [
    'Raw Materials',
    'Supplies',
    'Seasonings',
    'Packaging',
  ];
}

class AppColors {
  static const Color primary = Colors.deepOrange;
  static const Color secondary = Colors.orange;
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color info = Colors.blue;
}