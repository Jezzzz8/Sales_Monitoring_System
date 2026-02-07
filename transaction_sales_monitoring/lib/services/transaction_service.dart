// lib/services/transaction_service.dart - UPDATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/transaction.dart';
import '../models/product.dart';
import 'product_service.dart';

class TransactionService {
  static final CollectionReference transactionsCollection = 
      FirebaseConfig.firestore.collection('transactions');

  // Add new transaction to Firebase
  static Future<Map<String, dynamic>> addTransaction(TransactionModel transaction) async {
    try {
      // Create Firestore document
      final docRef = await transactionsCollection.add(transaction.toFirestore());
      
      // Update the transaction ID with Firestore document ID
      final updatedTransaction = transaction.copyWith(id: docRef.id);
      
      // Update transaction in Firestore with the correct ID
      await docRef.update({
        'firestoreId': docRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update product stocks
      final batch = FirebaseConfig.firestore.batch();
      final productsCollection = FirebaseConfig.firestore.collection('products');
      
      for (final item in transaction.items) {
        final productRef = productsCollection.doc(item.productId);
        
        // Get current stock
        final productDoc = await productRef.get();
        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          final currentStock = (productData['stock'] ?? 0).toInt();
          final newStock = currentStock - item.quantity;
          
          batch.update(productRef, {
            'stock': newStock >= 0 ? newStock : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Commit all product stock updates
      await batch.commit();

      return {
        'success': true,
        'transactionId': docRef.id,
        'transaction': updatedTransaction,
        'message': 'Transaction completed successfully',
      };
    } catch (e) {
      print('Error adding transaction to Firebase: $e');
      return {
        'success': false,
        'error': 'Failed to process transaction: ${e.toString()}',
      };
    }
  }

  // Get all transactions stream - FIXED VERSION
  static Stream<List<TransactionModel>> getTransactionsStream() {
    return transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('Total documents in snapshot: ${snapshot.docs.length}');
          
          final transactions = snapshot.docs.map((doc) {
            try {
              final transaction = TransactionModel.fromFirestore(doc);
              print('Successfully parsed transaction: ${transaction.transactionNumber}');
              return transaction;
            } catch (e) {
              print('Error parsing document ${doc.id}: $e');
              print('Document data: ${doc.data()}');
              return TransactionModel(
                id: doc.id,
                transactionNumber: '#ERROR-${doc.id}',
                transactionDate: DateTime.now(),
                customerName: 'Error Loading',
                customerPhone: '-',
                paymentMethod: 'Cash',
                totalAmount: 0,
                amountPaid: 0,
                change: 0,
                status: 'Error',
                items: [],
                notes: 'Error loading transaction data',
                createdAt: DateTime.now(),
              );
            }
          }).toList();
          
          print('Successfully parsed ${transactions.length} transactions');
          return transactions;
        });
  }

  // Get transactions by date range
  static Stream<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    return transactionsCollection
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  // Get today's transactions
  static Stream<List<TransactionModel>> getTodayTransactions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  // Get daily summary - FIXED VERSION
  static Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final snapshot = await transactionsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final transactions = snapshot.docs.map((doc) {
        return TransactionModel.fromFirestore(doc);
      }).toList();

      final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      final totalTransactions = transactions.length;
      final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;

      final paymentMethods = <String, double>{};
      for (final transaction in transactions) {
        final method = transaction.paymentMethod;
        paymentMethods[method] = (paymentMethods[method] ?? 0) + transaction.totalAmount;
      }

      // Get top selling products
      final productSales = <String, Map<String, dynamic>>{};
      for (final transaction in transactions) {
        for (final item in transaction.items) {
          final productId = item.productId;
          if (!productSales.containsKey(productId)) {
            productSales[productId] = {
              'name': item.productName,
              'quantity': 0,
              'revenue': 0.0,
            };
          }
          productSales[productId]!['quantity'] = (productSales[productId]!['quantity'] as int) + item.quantity;
          productSales[productId]!['revenue'] = (productSales[productId]!['revenue'] as double) + item.total;
        }
      }

      final topProducts = productSales.values.toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      return {
        'date': date,
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'averageSale': averageSale,
        'paymentMethods': paymentMethods,
        'topProducts': topProducts.take(5).toList(),
        'transactions': transactions,
      };
    } catch (e) {
      print('Error getting daily summary: $e');
      return {
        'date': date,
        'totalSales': 0,
        'totalTransactions': 0,
        'averageSale': 0,
        'paymentMethods': {},
        'topProducts': [],
        'transactions': [],
      };
    }
  }

  // Get monthly summary
  static Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    try {
      final snapshot = await transactionsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs.map((doc) {
        return TransactionModel.fromFirestore(doc);
      }).toList();

      final dailySales = <int, double>{};
      final dailyTransactions = <int, int>{};

      for (final transaction in transactions) {
        final day = transaction.transactionDate.day;
        dailySales[day] = (dailySales[day] ?? 0) + transaction.totalAmount;
        dailyTransactions[day] = (dailyTransactions[day] ?? 0) + 1;
      }

      final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      final totalTransactions = transactions.length;

      // Calculate payment method breakdown
      final paymentMethodBreakdown = <String, double>{};
      for (final transaction in transactions) {
        final method = transaction.paymentMethod;
        paymentMethodBreakdown[method] = (paymentMethodBreakdown[method] ?? 0) + transaction.totalAmount;
      }

      return {
        'year': year,
        'month': month,
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'dailySales': dailySales,
        'dailyTransactions': dailyTransactions,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'transactions': transactions,
      };
    } catch (e) {
      print('Error getting monthly summary: $e');
      return {
        'year': year,
        'month': month,
        'totalSales': 0,
        'totalTransactions': 0,
        'dailySales': {},
        'dailyTransactions': {},
        'paymentMethodBreakdown': {},
        'transactions': [],
      };
    }
  }

  // Get sales statistics
  static Future<Map<String, dynamic>> getSalesStatistics(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await transactionsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs.map((doc) {
        return TransactionModel.fromFirestore(doc);
      }).toList();

      // Calculate statistics
      final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      final totalTransactions = transactions.length;
      final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;

      // Top products
      final productSales = <String, Map<String, dynamic>>{};
      for (final transaction in transactions) {
        for (final item in transaction.items) {
          final productId = item.productId;
          if (!productSales.containsKey(productId)) {
            productSales[productId] = {
              'name': item.productName,
              'quantity': 0,
              'revenue': 0.0,
            };
          }
          productSales[productId]!['quantity'] = (productSales[productId]!['quantity'] as int) + item.quantity;
          productSales[productId]!['revenue'] = (productSales[productId]!['revenue'] as double) + item.total;
        }
      }

      final topProducts = productSales.values.toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      // Payment method breakdown
      final paymentMethods = <String, double>{};
      for (final transaction in transactions) {
        final method = transaction.paymentMethod;
        paymentMethods[method] = (paymentMethods[method] ?? 0) + transaction.totalAmount;
      }

      return {
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'averageSale': averageSale,
        'topProducts': topProducts.take(5).toList(),
        'paymentMethods': paymentMethods,
        'transactions': transactions,
      };
    } catch (e) {
      print('Error getting sales statistics: $e');
      return {
        'totalSales': 0,
        'totalTransactions': 0,
        'averageSale': 0,
        'topProducts': [],
        'paymentMethods': {},
        'transactions': [],
      };
    }
  }

  // Update transaction status (for refunds/cancellations)
  static Future<Map<String, dynamic>> updateTransactionStatus(
      String transactionId, String status, String? notes) async {
    try {
      await transactionsCollection.doc(transactionId).update({
        'status': status,
        'notes': notes ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If transaction is cancelled/refunded, restore product stocks
      if (status == 'Cancelled' || status == 'Refunded') {
        final doc = await transactionsCollection.doc(transactionId).get();
        if (doc.exists) {
          final transaction = TransactionModel.fromFirestore(doc);
          final batch = FirebaseConfig.firestore.batch();
          final productsCollection = FirebaseConfig.firestore.collection('products');
          
          for (final item in transaction.items) {
            final productRef = productsCollection.doc(item.productId);
            final productDoc = await productRef.get();
            
            if (productDoc.exists) {
              final productData = productDoc.data() as Map<String, dynamic>;
              final currentStock = (productData['stock'] ?? 0).toInt();
              final newStock = currentStock + item.quantity;
              
              batch.update(productRef, {
                'stock': newStock,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
          
          await batch.commit();
        }
      }

      return {'success': true, 'message': 'Transaction status updated'};
    } catch (e) {
      print('Error updating transaction status: $e');
      return {'success': false, 'error': 'Failed to update status: ${e.toString()}'};
    }
  }

  // Generate transaction number
  static String generateTransactionNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return '#ORD-${year}${month}${day}-${random}';
  }

  // Get transaction by ID
  static Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final doc = await transactionsCollection.doc(transactionId).get();
      if (doc.exists) {
        return TransactionModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  // Delete transaction (for cleanup)
  static Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      await transactionsCollection.doc(transactionId).delete();
      return {'success': true, 'message': 'Transaction deleted'};
    } catch (e) {
      print('Error deleting transaction: $e');
      return {'success': false, 'error': 'Failed to delete transaction: ${e.toString()}'};
    }
  }

  // Get pending transactions
  static Stream<List<TransactionModel>> getPendingTransactions() {
    return transactionsCollection
        .where('status', isEqualTo: 'Pending')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  // Get completed transactions
  static Stream<List<TransactionModel>> getCompletedTransactions() {
    return transactionsCollection
        .where('status', isEqualTo: 'Completed')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  static Future<Map<String, dynamic>> getWeeklySummary() async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
      final endOfWeekDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final snapshot = await transactionsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeekDate))
          .get();

      final transactions = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();

      // Calculate summary data
      double totalSales = 0.0;
      int totalTransactions = transactions.length;
      Map<String, double> categorySales = {};
      Map<DateTime, double> dailySales = {};
      Map<int, double> hourlySales = {};

      for (final transaction in transactions) {
        totalSales += transaction.totalAmount;
        
        // Daily sales
        final date = DateTime(
          transaction.transactionDate.year,
          transaction.transactionDate.month,
          transaction.transactionDate.day,
        );
        dailySales[date] = (dailySales[date] ?? 0) + transaction.totalAmount;
        
        // Hourly sales
        final hour = transaction.transactionDate.hour;
        hourlySales[hour] = (hourlySales[hour] ?? 0) + transaction.totalAmount;
        
        // Category sales (simplified - would need product details for accurate)
        // For now, we'll just track transaction-level data
      }

      // Prepare daily data
      final dailyData = dailySales.entries.map((entry) => {
        'date': entry.key,
        'sales': entry.value,
      }).toList();
      
      // Prepare hourly data
      final hourlyData = List.generate(24, (hour) => {
        'hour': '$hour:00',
        'sales': hourlySales[hour] ?? 0.0,
      });

      return {
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'averageSale': totalTransactions > 0 ? totalSales / totalTransactions : 0.0,
        'topCategories': [], // Empty for now - would need product data
        'categorySales': categorySales,
        'dailyData': dailyData,
        'hourlyData': hourlyData,
      };
    } catch (e) {
      print('Error getting weekly summary: $e');
      return {
        'totalSales': 0.0,
        'totalTransactions': 0,
        'averageSale': 0.0,
        'topCategories': [],
        'categorySales': {},
        'dailyData': [],
        'hourlyData': [],
      };
    }
  }

}