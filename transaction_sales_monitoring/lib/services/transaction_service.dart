// lib/services/transaction_service.dart - UPDATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/transaction.dart';
import '../models/product.dart';

class TransactionService {
  static final CollectionReference transactionsCollection = 
      FirebaseConfig.firestore.collection('transactions');

  // Add new transaction
  static Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await transactionsCollection.add(transaction.toMap());
      
      // Update product stocks
      for (final item in transaction.items) {
        // Update product stock in Firestore
        final productRef = FirebaseConfig.firestore.collection('products').doc(item.productId);
        final productDoc = await productRef.get();
        
        if (productDoc.exists) {
          final currentStock = productDoc.data()?['stock'] ?? 0;
          final newStock = currentStock - item.quantity;
          
          await productRef.update({
            'stock': newStock >= 0 ? newStock : 0,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  // Get all transactions
  static Stream<List<TransactionModel>> getTransactionsStream() {
    return transactionsCollection
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return TransactionModel.fromMap({...data, 'id': doc.id});
            }).toList());
  }

  // Get transactions by date range
  static Stream<List<TransactionModel>> getTransactionsByDateRange(
      DateTime startDate, DateTime endDate) {
    return transactionsCollection
        .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return TransactionModel.fromMap({...data, 'id': doc.id});
            }).toList());
  }

  // Get daily summary
  static Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final snapshot = await transactionsCollection
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TransactionModel.fromMap({...data, 'id': doc.id});
      }).toList();

      final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      final totalTransactions = transactions.length;
      final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;

      final paymentMethods = <String, double>{};
      for (final transaction in transactions) {
        paymentMethods[transaction.paymentMethod] =
            (paymentMethods[transaction.paymentMethod] ?? 0) + transaction.totalAmount;
      }

      return {
        'date': date,
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'averageSale': averageSale,
        'paymentMethods': paymentMethods,
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
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TransactionModel.fromMap({...data, 'id': doc.id});
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
        paymentMethodBreakdown[method] =
            (paymentMethodBreakdown[method] ?? 0) + transaction.totalAmount;
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
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TransactionModel.fromMap({...data, 'id': doc.id});
      }).toList();

      // Calculate statistics
      final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      final totalTransactions = transactions.length;
      final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;

      // Top products
      final productSales = <String, Map<String, dynamic>>{};
      for (final transaction in transactions) {
        for (final item in transaction.items) {
          if (!productSales.containsKey(item.productId)) {
            productSales[item.productId] = {
              'name': item.productName,
              'quantity': 0,
              'revenue': 0.0,
            };
          }
          productSales[item.productId]!['quantity'] += item.quantity;
          productSales[item.productId]!['revenue'] += item.total;
        }
      }

      final topProducts = productSales.values.toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

      // Payment method breakdown
      final paymentMethods = <String, double>{};
      for (final transaction in transactions) {
        paymentMethods[transaction.paymentMethod] =
            (paymentMethods[transaction.paymentMethod] ?? 0) + transaction.totalAmount;
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
  static Future<void> updateTransactionStatus(
      String transactionId, String status, String? notes) async {
    try {
      await transactionsCollection.doc(transactionId).update({
        'status': status,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating transaction status: $e');
      rethrow;
    }
  }

  // Generate transaction number
  static String generateTransactionNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = (DateTime.now().millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'TRX-$year$month$day-$random';
  }
}