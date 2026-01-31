import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String generateTransactionNumber() {
    final now = DateTime.now();
    return 'TRX-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  static double calculateChange(double total, double amountPaid) {
    return amountPaid - total;
  }

  static String getStockStatus(int currentStock, int reorderLevel) {
    if (currentStock <= 0) return 'Out of Stock';
    if (currentStock <= reorderLevel) return 'Low Stock';
    return 'In Stock';
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'In Stock':
        return Colors.green;
      case 'Pending':
      case 'Low Stock':
        return Colors.orange;
      case 'Cancelled':
      case 'Out of Stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static double calculateTotal(List<Map<String, dynamic>> items) {
    return items.fold(0.0, (sum, item) {
      final price = item['price'] ?? 0.0;
      final quantity = item['quantity'] ?? 0;
      return sum + (price * quantity);
    });
  }
}