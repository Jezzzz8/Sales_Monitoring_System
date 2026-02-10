// lib/services/transaction_service.dart - UPDATED VERSION with Partial Payment Support
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/transaction.dart';
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

      // Update product stocks (only if transaction is completed or partial with paid amount)
      if (transaction.status == 'Completed' || transaction.status == 'Partial') {
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
      }

      return {
        'success': true,
        'transactionId': docRef.id,
        'transaction': updatedTransaction,
        'message': 'Transaction ${transaction.status == 'Partial' ? 'partial payment' : 'completed'} successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to process transaction: ${e.toString()}',
      };
    }
  }

  // Update transaction payment (for partial payments)
  static Future<Map<String, dynamic>> updateTransactionPayment(
    String transactionId, 
    double additionalPayment,
    String? notes
  ) async {
    try {
      
      // Get current transaction
      final doc = await transactionsCollection.doc(transactionId).get();
      if (!doc.exists) {
        return {'success': false, 'error': 'Transaction not found'};
      }
      
      final transaction = TransactionModel.fromFirestore(doc);
      final currentAmountPaid = transaction.amountPaid;
      final currentCashReceived = transaction.cashReceived;
      final currentChange = transaction.change;
      final currentStatus = transaction.status;
      
      // Calculate new values
      final newAmountPaid = currentAmountPaid + additionalPayment;
      final newCashReceived = currentCashReceived + additionalPayment;
      final totalDue = transaction.totalAmount;
      
      // Determine new status
      String newStatus = currentStatus;
      if (newAmountPaid >= totalDue) {
        newStatus = 'Completed';
      } else {
        newStatus = 'Partial';
      }
      
      // Calculate new change
      double newChange = 0;
      if (newCashReceived > newAmountPaid) {
        newChange = newCashReceived - newAmountPaid;
      }
      
      // Update transaction
      await transactionsCollection.doc(transactionId).update({
        'amountPaid': newAmountPaid,
        'cashReceived': newCashReceived,
        'change': newChange,
        'status': newStatus,
        'notes': '${transaction.notes ?? ''}\nAdditional payment: ₱${additionalPayment.toStringAsFixed(2)} - ${DateTime.now().toIso8601String()}${notes != null ? '\n$notes' : ''}',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': 'Payment updated successfully. New amount paid: ₱${newAmountPaid.toStringAsFixed(2)}',
        'newAmountPaid': newAmountPaid,
        'newStatus': newStatus,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to update payment: ${e.toString()}',
      };
    }
  }

  // Get all transactions stream - FIXED VERSION
  static Stream<List<TransactionModel>> getTransactionsStream() {
    return transactionsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          
          final transactions = snapshot.docs.map((doc) {
            try {
              final transaction = TransactionModel.fromFirestore(doc);
              return transaction;
            } catch (e) {
              return TransactionModel(
                id: doc.id,
                transactionNumber: '#ERROR-${doc.id}',
                transactionDate: DateTime.now(),
                customerName: 'Error Loading',
                customerPhone: '-',
                paymentMethod: 'Cash',
                totalAmount: 0,
                amountPaid: 0,
                cashReceived: 0,
                change: 0,
                status: 'Error',
                items: [],
                notes: 'Error loading transaction data',
                createdAt: DateTime.now(),
              );
            }
          }).toList();
          
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

      // Calculate totals
      final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      final cashReceived = transactions.fold(0.0, (sum, t) => sum + t.cashReceived);
      final amountPaid = transactions.fold(0.0, (sum, t) => sum + t.amountPaid);
      final totalTransactions = transactions.length;
      final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;
      
      // Count partial payments
      final partialTransactions = transactions.where((t) => t.status == 'Partial').length;
      final completedTransactions = transactions.where((t) => t.status == 'Completed').length;
      
      // Calculate outstanding balance
      final outstandingBalance = transactions.fold(0.0, (sum, t) => 
        sum + (t.status == 'Partial' ? (t.totalAmount - t.amountPaid) : 0));

      final paymentMethods = <String, double>{};
      for (final transaction in transactions) {
        final method = transaction.paymentMethod;
        paymentMethods[method] = (paymentMethods[method] ?? 0) + transaction.cashReceived;
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
        'cashReceived': cashReceived,
        'amountPaid': amountPaid,
        'totalTransactions': totalTransactions,
        'completedTransactions': completedTransactions,
        'partialTransactions': partialTransactions,
        'outstandingBalance': outstandingBalance,
        'averageSale': averageSale,
        'paymentMethods': paymentMethods,
        'topProducts': topProducts.take(5).toList(),
        'transactions': transactions,
      };
    } catch (e) {
      return {
        'date': date,
        'totalSales': 0,
        'cashReceived': 0,
        'amountPaid': 0,
        'totalTransactions': 0,
        'completedTransactions': 0,
        'partialTransactions': 0,
        'outstandingBalance': 0,
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
      final dailyCashReceived = <int, double>{};
      final dailyTransactions = <int, int>{};

      for (final transaction in transactions) {
        final day = transaction.transactionDate.day;
        dailySales[day] = (dailySales[day] ?? 0) + transaction.totalAmount;
        dailyCashReceived[day] = (dailyCashReceived[day] ?? 0) + transaction.cashReceived;
        dailyTransactions[day] = (dailyTransactions[day] ?? 0) + 1;
      }

      final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
      final totalCashReceived = transactions.fold(0.0, (sum, t) => sum + t.cashReceived);
      final totalTransactions = transactions.length;
      
      // Calculate outstanding balance for the month
      final monthlyOutstandingBalance = transactions.fold(0.0, (sum, t) => 
        sum + (t.status == 'Partial' ? (t.totalAmount - t.amountPaid) : 0));

      // Calculate payment method breakdown
      final paymentMethodBreakdown = <String, double>{};
      for (final transaction in transactions) {
        final method = transaction.paymentMethod;
        paymentMethodBreakdown[method] = (paymentMethodBreakdown[method] ?? 0) + transaction.cashReceived;
      }

      return {
        'year': year,
        'month': month,
        'totalSales': totalSales,
        'totalCashReceived': totalCashReceived,
        'totalTransactions': totalTransactions,
        'monthlyOutstandingBalance': monthlyOutstandingBalance,
        'dailySales': dailySales,
        'dailyCashReceived': dailyCashReceived,
        'dailyTransactions': dailyTransactions,
        'paymentMethodBreakdown': paymentMethodBreakdown,
        'transactions': transactions,
      };
    } catch (e) {
      return {
        'year': year,
        'month': month,
        'totalSales': 0,
        'totalCashReceived': 0,
        'totalTransactions': 0,
        'monthlyOutstandingBalance': 0,
        'dailySales': {},
        'dailyCashReceived': {},
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
      final cashReceived = transactions.fold(0.0, (sum, t) => sum + t.cashReceived);
      final amountPaid = transactions.fold(0.0, (sum, t) => sum + t.amountPaid);
      final totalTransactions = transactions.length;
      final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;
      
      // Outstanding balance
      final outstandingBalance = transactions.fold(0.0, (sum, t) => 
        sum + (t.status == 'Partial' ? (t.totalAmount - t.amountPaid) : 0));
      
      // Transaction status breakdown
      final completedCount = transactions.where((t) => t.status == 'Completed').length;
      final partialCount = transactions.where((t) => t.status == 'Partial').length;
      final cancelledCount = transactions.where((t) => t.status == 'Cancelled').length;

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
        paymentMethods[method] = (paymentMethods[method] ?? 0) + transaction.cashReceived;
      }

      return {
        'totalSales': totalSales,
        'cashReceived': cashReceived,
        'amountPaid': amountPaid,
        'outstandingBalance': outstandingBalance,
        'totalTransactions': totalTransactions,
        'completedTransactions': completedCount,
        'partialTransactions': partialCount,
        'cancelledTransactions': cancelledCount,
        'averageSale': averageSale,
        'topProducts': topProducts.take(5).toList(),
        'paymentMethods': paymentMethods,
        'transactions': transactions,
      };
    } catch (e) {
      return {
        'totalSales': 0,
        'cashReceived': 0,
        'amountPaid': 0,
        'outstandingBalance': 0,
        'totalTransactions': 0,
        'completedTransactions': 0,
        'partialTransactions': 0,
        'cancelledTransactions': 0,
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
      // Get current transaction
      final doc = await transactionsCollection.doc(transactionId).get();
      if (!doc.exists) {
        return {'success': false, 'error': 'Transaction not found'};
      }
      
      final transaction = TransactionModel.fromFirestore(doc);
      
      // Update transaction status
      await transactionsCollection.doc(transactionId).update({
        'status': status,
        'notes': '${transaction.notes ?? ''}\nStatus changed to $status - ${DateTime.now().toIso8601String()}${notes != null ? '\n$notes' : ''}',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // If transaction is cancelled/refunded, restore product stocks
      if (status == 'Cancelled' || status == 'Refunded') {
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

      return {'success': true, 'message': 'Transaction status updated to $status'};
    } catch (e) {
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
    return '#ORD-$year$month$day-$random';
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
      return null;
    }
  }

  // Delete transaction (for cleanup)
  static Future<Map<String, dynamic>> deleteTransaction(String transactionId) async {
    try {
      await transactionsCollection.doc(transactionId).delete();
      return {'success': true, 'message': 'Transaction deleted'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to delete transaction: ${e.toString()}'};
    }
  }

  // Get partial transactions
  static Stream<List<TransactionModel>> getPartialTransactions() {
    return transactionsCollection
        .where('status', isEqualTo: 'Partial')
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

  // Get outstanding partial payments (with balance > 0)
  static Stream<List<TransactionModel>> getOutstandingPartialPayments() {
    return transactionsCollection
        .where('status', isEqualTo: 'Partial')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .where((transaction) => transaction.amountPaid < transaction.totalAmount)
            .toList();
        });
  }

  // Get weekly summary
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
      double cashReceived = 0.0;
      double amountPaid = 0.0;
      int totalTransactions = transactions.length;
      Map<String, double> categorySales = {};
      Map<DateTime, double> dailySales = {};
      Map<DateTime, double> dailyCash = {};
      Map<int, double> hourlySales = {};

      for (final transaction in transactions) {
        totalSales += transaction.totalAmount;
        cashReceived += transaction.cashReceived;
        amountPaid += transaction.amountPaid;
        
        // Daily sales
        final date = DateTime(
          transaction.transactionDate.year,
          transaction.transactionDate.month,
          transaction.transactionDate.day,
        );
        dailySales[date] = (dailySales[date] ?? 0) + transaction.totalAmount;
        dailyCash[date] = (dailyCash[date] ?? 0) + transaction.cashReceived;
        
        // Hourly sales
        final hour = transaction.transactionDate.hour;
        hourlySales[hour] = (hourlySales[hour] ?? 0) + transaction.totalAmount;
      }

      // Calculate outstanding balance
      final outstandingBalance = transactions.fold(0.0, (sum, t) => 
        sum + (t.status == 'Partial' ? (t.totalAmount - t.amountPaid) : 0));

      // Prepare daily data
      final dailyData = dailySales.entries.map((entry) => {
        'date': entry.key,
        'sales': entry.value,
        'cash': dailyCash[entry.key] ?? 0.0,
      }).toList();
      
      // Prepare hourly data
      final hourlyData = List.generate(24, (hour) => {
        'hour': '$hour:00',
        'sales': hourlySales[hour] ?? 0.0,
      });

      return {
        'totalSales': totalSales,
        'cashReceived': cashReceived,
        'amountPaid': amountPaid,
        'outstandingBalance': outstandingBalance,
        'totalTransactions': totalTransactions,
        'averageSale': totalTransactions > 0 ? totalSales / totalTransactions : 0.0,
        'topCategories': [], // Empty for now - would need product data
        'categorySales': categorySales,
        'dailyData': dailyData,
        'hourlyData': hourlyData,
      };
    } catch (e) {
      return {
        'totalSales': 0.0,
        'cashReceived': 0.0,
        'amountPaid': 0.0,
        'outstandingBalance': 0.0,
        'totalTransactions': 0,
        'averageSale': 0.0,
        'topCategories': [],
        'categorySales': {},
        'dailyData': [],
        'hourlyData': [],
      };
    }
  }

  // Get payment summary by method
  static Future<Map<String, double>> getPaymentMethodSummary(DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await transactionsCollection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();

      final paymentMethodSummary = <String, double>{};
      for (final transaction in transactions) {
        final method = transaction.paymentMethod;
        paymentMethodSummary[method] = (paymentMethodSummary[method] ?? 0) + transaction.cashReceived;
      }

      return paymentMethodSummary;
    } catch (e) {
      return {};
    }
  }

  // Calculate total outstanding balance
  static Future<double> getTotalOutstandingBalance() async {
    try {
      final snapshot = await transactionsCollection
          .where('status', isEqualTo: 'Partial')
          .get();

      // Convert the documents to TransactionModel list FIRST
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // Now perform the fold operation on the List, not in the return statement
      double totalOutstanding = 0.0;
      
      for (final transaction in transactions) {
        totalOutstanding += (transaction.totalAmount - transaction.amountPaid);
      }
      
      return totalOutstanding;
      
      // OR using fold (this also works once we have the list)
      // return transactions.fold(0.0, (sum, t) => sum + (t.totalAmount - t.amountPaid));
    } catch (e) {
      return 0.0;
    }
  }
}