// lib/services/sales_service.dart - UPDATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';

class SalesService {
  static final CollectionReference transactionsCollection = 
      FirebaseConfig.firestore.collection('transactions');
  
  static final CollectionReference productsCollection = 
      FirebaseConfig.firestore.collection('products');

  // Get sales summary for date range
  static Future<Map<String, dynamic>> getSalesSummary(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await transactionsCollection
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'Completed')
          .get();

      final transactions = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      final totalSales = transactions.fold<double>(0, (sum, t) => sum + (t['totalAmount'] ?? 0));
      final totalTransactions = transactions.length;
      final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;

      // Calculate daily breakdown
      final dailyBreakdown = <String, double>{};
      for (final transaction in transactions) {
        final date = (transaction['transactionDate'] as Timestamp).toDate();
        final dayName = _getDayName(date.weekday);
        dailyBreakdown[dayName] = (dailyBreakdown[dayName] ?? 0) + (transaction['totalAmount'] ?? 0);
      }

      // Calculate top products
      final productSales = <String, Map<String, dynamic>>{};
      for (final transaction in transactions) {
        final items = transaction['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final itemData = item as Map<String, dynamic>;
          final productName = itemData['productName'] ?? 'Unknown';
          final quantity = (itemData['quantity'] ?? 0).toInt();
          final total = (itemData['total'] ?? 0).toDouble();

          if (!productSales.containsKey(productName)) {
            productSales[productName] = {
              'sales': 0.0,
              'quantity': 0,
            };
          }
          productSales[productName]!['sales'] += total;
          productSales[productName]!['quantity'] += quantity;
        }
      }

      final topProducts = productSales.entries
          .map((entry) => {
                'name': entry.key,
                'sales': entry.value['sales'],
                'quantity': entry.value['quantity'],
              })
          .toList()
        ..sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

      return {
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'averageSale': averageSale,
        'dailyBreakdown': dailyBreakdown,
        'topProducts': topProducts.take(5).toList(),
      };
    } catch (e) {
      print('Error getting sales summary: $e');
      return {
        'totalSales': 0.0,
        'totalTransactions': 0,
        'averageSale': 0.0,
        'dailyBreakdown': {},
        'topProducts': [],
      };
    }
  }

  // Get sales trend
  static Future<List<Map<String, dynamic>>> getSalesTrend(
      DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await transactionsCollection
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'Completed')
          .orderBy('transactionDate')
          .get();

      final transactions = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Group by date
      final salesByDate = <DateTime, Map<String, dynamic>>{};
      for (final transaction in transactions) {
        final date = (transaction['transactionDate'] as Timestamp).toDate();
        final dateOnly = DateTime(date.year, date.month, date.day);
        
        if (!salesByDate.containsKey(dateOnly)) {
          salesByDate[dateOnly] = {
            'sales': 0.0,
            'transactions': 0,
          };
        }
        salesByDate[dateOnly]!['sales'] += (transaction['totalAmount'] ?? 0);
        salesByDate[dateOnly]!['transactions'] += 1;
      }

      // Fill in missing dates
      final trend = <Map<String, dynamic>>[];
      DateTime current = startDate;
      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        final dateOnly = DateTime(current.year, current.month, current.day);
        final data = salesByDate[dateOnly] ?? {'sales': 0.0, 'transactions': 0};
        
        trend.add({
          'date': dateOnly,
          'sales': data['sales'],
          'transactions': data['transactions'],
        });
        
        current = current.add(const Duration(days: 1));
      }

      return trend;
    } catch (e) {
      print('Error getting sales trend: $e');
      return [];
    }
  }

  // Get category sales
  static Future<Map<String, double>> getCategorySales(
      DateTime startDate, DateTime endDate) async {
    try {
      // First get categories
      final categoriesSnapshot = await FirebaseConfig.firestore
          .collection('categories')
          .where('type', isEqualTo: 'product')
          .where('isActive', isEqualTo: true)
          .get();

      final categories = categoriesSnapshot.docs.map((doc) => doc.data()).toList();
      
      // Get transactions
      final transactionsSnapshot = await transactionsCollection
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'Completed')
          .get();

      final transactions = transactionsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Initialize category sales
      final categorySales = <String, double>{};
      for (final category in categories) {
        categorySales[category['name'] as String] = 0.0;
      }

      // Calculate sales by category
      for (final transaction in transactions) {
        final items = transaction['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final itemData = item as Map<String, dynamic>;
          final productId = itemData['productId'] as String?;
          
          if (productId != null) {
            // Get product category
            final productDoc = await productsCollection.doc(productId).get();
            if (productDoc.exists) {
              final productData = productDoc.data() as Map<String, dynamic>;
              final categoryId = productData['categoryId'] as String?;
              
              if (categoryId != null) {
                // Find category name
                final category = categories.firstWhere(
                  (cat) => cat['id'] == categoryId,
                  orElse: () => {'name': 'Other'},
                );
                final categoryName = category['name'] as String;
                final itemTotal = (itemData['total'] ?? 0).toDouble();
                
                categorySales[categoryName] = (categorySales[categoryName] ?? 0) + itemTotal;
              }
            }
          }
        }
      }

      return categorySales;
    } catch (e) {
      print('Error getting category sales: $e');
      return {};
    }
  }

  // Get hourly sales breakdown
  static Future<Map<String, dynamic>> getHourlySales(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await transactionsCollection
          .where('transactionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('transactionDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'Completed')
          .get();

      final transactions = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Initialize hourly sales
      final hourlySales = List<double>.filled(24, 0.0);
      final hourlyTransactions = List<int>.filled(24, 0);

      for (final transaction in transactions) {
        final date = (transaction['transactionDate'] as Timestamp).toDate();
        final hour = date.hour;
        final totalAmount = (transaction['totalAmount'] ?? 0).toDouble();

        hourlySales[hour] += totalAmount;
        hourlyTransactions[hour] += 1;
      }

      // Format for display
      final hourlyLabels = List<String>.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00');
      final hourlyData = hourlySales.asMap().entries.map((entry) {
        return {
          'hour': hourlyLabels[entry.key],
          'sales': entry.value,
          'transactions': hourlyTransactions[entry.key],
        };
      }).toList();

      return {
        'hourlyLabels': hourlyLabels,
        'hourlySales': hourlySales,
        'hourlyTransactions': hourlyTransactions,
        'hourlyData': hourlyData,
        'peakHour': _findPeakHour(hourlySales),
      };
    } catch (e) {
      print('Error getting hourly sales: $e');
      return {
        'hourlyLabels': List<String>.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00'),
        'hourlySales': List<double>.filled(24, 0.0),
        'hourlyTransactions': List<int>.filled(24, 0),
        'hourlyData': [],
        'peakHour': -1,
      };
    }
  }

  // Get sales comparison (current vs previous period)
  static Future<Map<String, dynamic>> getSalesComparison(
      DateTime currentStart, DateTime currentEnd,
      DateTime previousStart, DateTime previousEnd) async {
    try {
      final currentSummary = await getSalesSummary(currentStart, currentEnd);
      final previousSummary = await getSalesSummary(previousStart, previousEnd);

      final currentTotal = currentSummary['totalSales'] as double;
      final previousTotal = previousSummary['totalSales'] as double;
      final changeAmount = currentTotal - previousTotal;
      final changePercentage = previousTotal > 0 ? (changeAmount / previousTotal) * 100 : 100;

      return {
        'currentPeriod': {
          'totalSales': currentTotal,
          'totalTransactions': currentSummary['totalTransactions'],
          'averageSale': currentSummary['averageSale'],
        },
        'previousPeriod': {
          'totalSales': previousTotal,
          'totalTransactions': previousSummary['totalTransactions'],
          'averageSale': previousSummary['averageSale'],
        },
        'change': {
          'amount': changeAmount,
          'percentage': changePercentage,
          'isIncrease': changeAmount >= 0,
        },
      };
    } catch (e) {
      print('Error getting sales comparison: $e');
      return {
        'currentPeriod': {'totalSales': 0, 'totalTransactions': 0, 'averageSale': 0},
        'previousPeriod': {'totalSales': 0, 'totalTransactions': 0, 'averageSale': 0},
        'change': {'amount': 0, 'percentage': 0, 'isIncrease': true},
      };
    }
  }

  // Helper methods
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  static int _findPeakHour(List<double> hourlySales) {
    double maxSales = 0;
    int peakHour = -1;

    for (int i = 0; i < hourlySales.length; i++) {
      if (hourlySales[i] > maxSales) {
        maxSales = hourlySales[i];
        peakHour = i;
      }
    }

    return peakHour;
  }
}