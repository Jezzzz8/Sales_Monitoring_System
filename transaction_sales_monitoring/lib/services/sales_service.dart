// lib/services/sales_service.dart - UPDATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/category_model.dart';
import '../models/transaction.dart';

class SalesService {
  static final CollectionReference transactionsCollection = 
      FirebaseConfig.firestore.collection('transactions');
  
  static final CollectionReference productsCollection = 
      FirebaseConfig.firestore.collection('products');
  
  static final CollectionReference categoriesCollection = 
      FirebaseConfig.firestore.collection('categories');

  // Get comprehensive sales analytics
  static Future<Map<String, dynamic>> getSalesAnalytics(
      DateTime startDate, DateTime endDate) async {
    try {
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);
      
      print('Fetching transactions from $startDate to $endDate');
      
      // Get all completed transactions in date range
      final transactionsSnapshot = await transactionsCollection
          .where('date', isGreaterThanOrEqualTo: startTimestamp)
          .where('date', isLessThanOrEqualTo: endTimestamp)
          .orderBy('date', descending: true)
          .get();

      print('Found ${transactionsSnapshot.docs.length} transactions');
      
      final transactions = transactionsSnapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // Fetch all categories once
      final categoriesSnapshot = await categoriesCollection.get();
      final categoryMap = <String, ProductCategory>{};
      for (var doc in categoriesSnapshot.docs) {
        final category = ProductCategory.fromFirestore(doc);
        categoryMap[category.id] = category;
      }
      
      // Fetch all products once to avoid multiple queries
      final productIds = <String>{};
      for (final transaction in transactions) {
        for (final item in transaction.items) {
          productIds.add(item.productId);
        }
      }
      
      final productsMap = <String, Map<String, dynamic>>{};
      for (final productId in productIds) {
        try {
          final productDoc = await productsCollection.doc(productId).get();
          if (productDoc.exists) {
            productsMap[productId] = productDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          print('Error fetching product $productId: $e');
        }
      }

      // Calculate basic metrics
      double totalSales = 0.0;
      int totalTransactions = transactions.length;
      Map<String, double> paymentMethods = {};
      Map<String, double> categorySales = {};
      Map<String, Map<String, dynamic>> productSales = {};
      Map<DateTime, double> dailySales = {};
      Map<int, double> hourlySales = {};

      // Process all transactions
      for (final transaction in transactions) {
        totalSales += transaction.totalAmount;

        // Payment method breakdown
        final method = transaction.paymentMethod;
        paymentMethods[method] = (paymentMethods[method] ?? 0) + transaction.totalAmount;

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

        // Process items for category and product analysis
        for (final item in transaction.items) {
          print('Processing item: ${item.productName} - ₱${item.total}');
          
          // Get product details from pre-fetched map
          final productData = productsMap[item.productId];
          String categoryName = 'Uncategorized';
          String categoryId = '';
          String productName = item.productName;

          if (productData != null) {
            // Get categoryId from product
            categoryId = productData['categoryId'] as String? ?? '';
            productName = productData['name'] as String? ?? item.productName;
            
            // Use categoryId to get category name from categoryMap
            if (categoryId.isNotEmpty && categoryMap.containsKey(categoryId)) {
              final category = categoryMap[categoryId];
              categoryName = category?.name ?? 'Uncategorized';
            } else {
              // Fallback to category field if categoryId doesn't exist or doesn't match
              categoryName = productData['category'] as String? ?? 'Uncategorized';
          }
        }

        print('Product: $productName, Category: $categoryName');

        // Category sales - now using correct category name
        categorySales[categoryName] = 
            (categorySales[categoryName] ?? 0) + item.total;

        // Product sales tracking
        if (!productSales.containsKey(item.productId)) {
          productSales[item.productId] = {
            'name': productName,
            'category': categoryName,
            'categoryId': categoryId,
            'totalSales': 0.0,
            'totalQuantity': 0,
            'unitPrice': item.unitPrice,
          };
        }
        productSales[item.productId]!['totalSales'] += item.total;
        productSales[item.productId]!['totalQuantity'] += item.quantity;
      }
    }

    print('Total sales: ₱$totalSales');
    print('Total transactions: $totalTransactions');
    print('Categories found: ${categorySales.keys.toList()}');

    // Calculate average sale
    final averageSale = totalTransactions > 0 ? totalSales / totalTransactions : 0;

    // Get top products (sorted by sales)
    final topProducts = productSales.values.toList()
      ..sort((a, b) => (b['totalSales'] as double).compareTo(a['totalSales'] as double));

    // Get top categories (sorted by sales)
    final topCategories = categorySales.entries
        .map((entry) => {
              'name': entry.key,
              'sales': entry.value,
              'percentage': totalSales > 0 ? (entry.value / totalSales * 100) : 0,
            })
        .toList()
      ..sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

    // Prepare hourly data for charts
    final hourlyData = List.generate(24, (hour) {
      return {
        'hour': '$hour:00',
        'sales': hourlySales[hour] ?? 0.0,
        'label': '$hour:00',
      };
    });

    // Prepare daily data for charts
    final dailyData = dailySales.entries.map((entry) {
      return {
        'date': entry.key,
        'sales': entry.value,
        'label': '${entry.key.day}/${entry.key.month}',
      };
    }).toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    return {
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'averageSale': averageSale,
      'paymentMethods': paymentMethods,
      'topCategories': topCategories,
      'topProducts': topProducts.take(10).toList(),
      'hourlyData': hourlyData,
      'dailyData': dailyData,
      'categorySales': categorySales,
      'startDate': startDate,
      'endDate': endDate,
      'transactions': transactions,
    };
  } catch (e) {
    print('Error getting sales analytics: $e');
    print('Error stack trace: ${e.toString()}');
    return {
      'totalSales': 0.0,
      'totalTransactions': 0,
      'averageSale': 0.0,
      'paymentMethods': {},
      'topCategories': [],
      'topProducts': [],
      'hourlyData': [],
      'dailyData': [],
      'categorySales': {},
      'startDate': startDate,
      'endDate': endDate,
      'transactions': [],
    };
  }
}

  // Get real-time sales stream
  static Stream<Map<String, dynamic>> getSalesStream(DateTime startDate, DateTime endDate) {
    final startTimestamp = Timestamp.fromDate(startDate);
    final endTimestamp = Timestamp.fromDate(endDate);

    return transactionsCollection
        .where('date', isGreaterThanOrEqualTo: startTimestamp)
        .where('date', isLessThanOrEqualTo: endTimestamp)
        // .where('status', isEqualTo: 'Completed') // REMOVED
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      return await _calculateAnalyticsFromTransactions(transactions, startDate, endDate);
    });
  }

  // Get today's sales analytics
  static Future<Map<String, dynamic>> getTodayAnalytics() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return await getSalesAnalytics(startOfDay, endOfDay);
  }

  // Get weekly sales analytics
  static Future<Map<String, dynamic>> getWeeklyAnalytics() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0);
    final endOfWeekDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return await getSalesAnalytics(startOfWeekDate, endOfWeekDate);
  }

  // Get monthly sales analytics
  static Future<Map<String, dynamic>> getMonthlyAnalytics() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1, 0, 0, 0);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return await getSalesAnalytics(startOfMonth, endOfMonth);
  }

  // Get year-to-date analytics
  static Future<Map<String, dynamic>> getYearToDateAnalytics() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1, 0, 0, 0);
    
    return await getSalesAnalytics(startOfYear, now);
  }

  // Get comparison data (current vs previous period)
  static Future<Map<String, dynamic>> getPeriodComparison(
      DateTime currentStart, DateTime currentEnd,
      DateTime previousStart, DateTime previousEnd) async {
    try {
      final currentAnalytics = await getSalesAnalytics(currentStart, currentEnd);
      final previousAnalytics = await getSalesAnalytics(previousStart, previousEnd);

      final currentSales = currentAnalytics['totalSales'] as double;
      final previousSales = previousAnalytics['totalSales'] as double;
      final changeAmount = currentSales - previousSales;
      final changePercentage = previousSales > 0 ? (changeAmount / previousSales * 100) : 100;

      return {
        'current': currentAnalytics,
        'previous': previousAnalytics,
        'comparison': {
          'salesChange': changeAmount,
          'salesChangePercentage': changePercentage,
          'transactionChange': (currentAnalytics['totalTransactions'] as int) - 
                               (previousAnalytics['totalTransactions'] as int),
          'averageSaleChange': (currentAnalytics['averageSale'] as double) - 
                               (previousAnalytics['averageSale'] as double),
          'isSalesIncrease': changeAmount >= 0,
        },
      };
    } catch (e) {
      print('Error getting period comparison: $e');
      return {
        'current': {},
        'previous': {},
        'comparison': {
          'salesChange': 0,
          'salesChangePercentage': 0,
          'transactionChange': 0,
          'averageSaleChange': 0,
          'isSalesIncrease': true,
        },
      };
    }
  }

  // Get product performance analytics
  static Future<Map<String, dynamic>> getProductPerformance(
      DateTime startDate, DateTime endDate) async {
    try {
      final analytics = await getSalesAnalytics(startDate, endDate);
      final topProducts = analytics['topProducts'] as List<dynamic>;

      // Calculate product performance metrics
      final productMetrics = topProducts.map((product) {
        final sales = product['totalSales'] as double;
        final quantity = product['totalQuantity'] as int;
        final unitPrice = product['unitPrice'] as double;

        return {
          ...product,
          'averageQuantityPerTransaction': quantity / (analytics['totalTransactions'] as int),
          'contributionPercentage': sales / (analytics['totalSales'] as double) * 100,
          'estimatedProfit': sales * 0.3, // Assuming 30% profit margin
        };
      }).toList();

      return {
        'products': productMetrics,
        'totalProductsAnalyzed': topProducts.length,
        'topPerformingProduct': topProducts.isNotEmpty ? topProducts.first : null,
        'slowMovingProducts': topProducts.length > 5 
            ? topProducts.sublist(5).take(5).toList() 
            : [],
      };
    } catch (e) {
      print('Error getting product performance: $e');
      return {
        'products': [],
        'totalProductsAnalyzed': 0,
        'topPerformingProduct': null,
        'slowMovingProducts': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getSalesAnalyticsWithLimit(
      DateTime startDate, DateTime endDate, {int limit = 100}) async {
    try {
      final analytics = await getSalesAnalytics(startDate, endDate);
      return analytics;
    } catch (e) {
      print('Error getting sales analytics with limit: $e');
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

  // Get category performance analytics - UPDATED
  static Future<Map<String, dynamic>> getCategoryPerformance(
      DateTime startDate, DateTime endDate) async {
    try {
      final analytics = await getSalesAnalytics(startDate, endDate);
      final topCategories = analytics['topCategories'] as List<dynamic>;

      print('Raw top categories: $topCategories');

      // Fetch all categories from database
      final categoriesSnapshot = await categoriesCollection
          .where('type', isEqualTo: 'product')
          .get();

      print('Fetched ${categoriesSnapshot.docs.length} categories from DB');

      // Create category map
      final Map<String, ProductCategory> categoryMap = {};
      for (var doc in categoriesSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name'] as String? ?? '';
          final category = ProductCategory.fromFirestore(doc);
          
          // Map both uppercase and lowercase versions for better matching
          if (name.isNotEmpty) {
            categoryMap[name.toLowerCase()] = category;
            categoryMap[name] = category;
          }
        } catch (e) {
          print('Error parsing category document: $e');
        }
      }

      // Add category details and colors
      final enhancedCategories = topCategories.map((category) {
        final categoryName = category['name'] as String;
        print('Processing category: $categoryName');
        
        // Try to find category (case-insensitive)
        ProductCategory? categoryData;
        if (categoryMap.containsKey(categoryName)) {
          categoryData = categoryMap[categoryName];
        } else if (categoryName.isNotEmpty) {
          categoryData = categoryMap[categoryName.toLowerCase()];
        }
        
        return {
          ...category,
          'color': categoryData?.color ?? '#2196F3',
          'icon': categoryData?.icon ?? '',
          'description': categoryData?.description ?? '',
        };
      }).toList();

      print('Enhanced categories: $enhancedCategories');

      return {
        'categories': enhancedCategories,
        'dominantCategory': topCategories.isNotEmpty ? topCategories.first : null,
        'categoryDiversity': topCategories.length,
      };
    } catch (e) {
      print('Error getting category performance: $e');
      print('Stack trace: ${e.toString()}');
      return {
        'categories': [],
        'dominantCategory': null,
        'categoryDiversity': 0,
      };
    }
  }

  // Get hourly performance analytics
  static Future<Map<String, dynamic>> getHourlyPerformance(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final analytics = await getSalesAnalytics(startOfDay, endOfDay);
      final hourlyData = analytics['hourlyData'] as List<dynamic>;

      // Find peak hours
      double maxSales = 0;
      int peakHourIndex = -1;
      final peakHours = <int>[];

      for (int i = 0; i < hourlyData.length; i++) {
        final sales = hourlyData[i]['sales'] as double;
        if (sales > maxSales) {
          maxSales = sales;
          peakHourIndex = i;
        }
        if (sales > maxSales * 0.7) { // 70% of peak or higher
          peakHours.add(i);
        }
      }

      // Calculate hourly averages
      final totalHourlySales = hourlyData.fold<double>(0, (sum, hour) => sum + (hour['sales'] as double));
      final averageHourlySales = totalHourlySales / 24;

      return {
        'hourlyData': hourlyData,
        'peakHour': peakHourIndex,
        'peakHours': peakHours,
        'totalHourlySales': totalHourlySales,
        'averageHourlySales': averageHourlySales,
        'peakToAverageRatio': maxSales / averageHourlySales,
        'busyPeriods': _identifyBusyPeriods(hourlyData),
      };
    } catch (e) {
      print('Error getting hourly performance: $e');
      return {
        'hourlyData': [],
        'peakHour': -1,
        'peakHours': [],
        'totalHourlySales': 0,
        'averageHourlySales': 0,
        'peakToAverageRatio': 0,
        'busyPeriods': [],
      };
    }
  }

  // Helper method to calculate analytics from transactions
  static Future<Map<String, dynamic>> _calculateAnalyticsFromTransactions(
      List<TransactionModel> transactions, DateTime startDate, DateTime endDate) async {
    double totalSales = 0.0;
    int totalTransactions = transactions.length;
    Map<String, double> categorySales = {};
    Map<DateTime, double> dailySales = {};
    
    // Fetch categories once
    final categoriesSnapshot = await categoriesCollection.get();
    final categoryMap = <String, ProductCategory>{};
    for (var doc in categoriesSnapshot.docs) {
      final category = ProductCategory.fromFirestore(doc);
      categoryMap[category.id] = category;
    }
    
    // Fetch products once
    final productIds = <String>{};
    for (final transaction in transactions) {
      for (final item in transaction.items) {
        productIds.add(item.productId);
      }
    }
    
    final productsMap = <String, Map<String, dynamic>>{};
    for (final productId in productIds) {
      try {
        final productDoc = await productsCollection.doc(productId).get();
        if (productDoc.exists) {
          productsMap[productId] = productDoc.data() as Map<String, dynamic>;
        }
      } catch (e) {
        // Skip error, continue with next item
      }
    }

    for (final transaction in transactions) {
      totalSales += transaction.totalAmount;
      
      // Daily sales tracking
      final date = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      dailySales[date] = (dailySales[date] ?? 0) + transaction.totalAmount;

      // Category sales tracking
      for (final item in transaction.items) {
        try {
          final productData = productsMap[item.productId];
          if (productData != null) {
            // Get categoryId from product
            final categoryId = productData['categoryId'] as String? ?? '';
            String categoryName = 'Uncategorized';
            
            // Use categoryId to get category name from categoryMap
            if (categoryId.isNotEmpty && categoryMap.containsKey(categoryId)) {
              final category = categoryMap[categoryId];
              categoryName = category?.name ?? 'Uncategorized';
            } else {
              // Fallback to category field
              categoryName = productData['category'] as String? ?? 'Uncategorized';
            }
            
            categorySales[categoryName] = (categorySales[categoryName] ?? 0) + item.total;
          }
        } catch (e) {
          print('Error in _calculateAnalyticsFromTransactions: $e');
        }
      }
    }

    return {
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'averageSale': totalTransactions > 0 ? totalSales / totalTransactions : 0,
      'categorySales': categorySales,
      'dailySales': dailySales,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  // Helper method to identify busy periods
  static List<Map<String, dynamic>> _identifyBusyPeriods(List<dynamic> hourlyData) {
    final busyPeriods = <Map<String, dynamic>>[];
    int currentStart = -1;
    double currentTotal = 0;

    for (int i = 0; i < hourlyData.length; i++) {
      final sales = hourlyData[i]['sales'] as double;
      
      if (sales > 0) {
        if (currentStart == -1) {
          currentStart = i;
        }
        currentTotal += sales;
      } else if (currentStart != -1) {
        // End of busy period
        busyPeriods.add({
          'startHour': currentStart,
          'endHour': i - 1,
          'totalSales': currentTotal,
          'duration': i - currentStart,
        });
        currentStart = -1;
        currentTotal = 0;
      }
    }

    // Handle last busy period
    if (currentStart != -1) {
      busyPeriods.add({
        'startHour': currentStart,
        'endHour': 23,
        'totalSales': currentTotal,
        'duration': 24 - currentStart,
      });
    }

    return busyPeriods;
  }

  // Get sales forecast based on historical data
  static Future<Map<String, dynamic>> getSalesForecast(int daysAhead) async {
    try {
      final now = DateTime.now();
      final historicalStart = now.subtract(Duration(days: 30)); // Last 30 days
      final historicalEnd = now;

      final historicalData = await getSalesAnalytics(historicalStart, historicalEnd);
      final dailyData = historicalData['dailyData'] as List<dynamic>;

      if (dailyData.isEmpty) {
        return {
          'forecast': [],
          'confidence': 0,
          'basedOnDays': 0,
          'message': 'Insufficient historical data',
        };
      }

      // Simple moving average forecast
      final recentSales = dailyData.take(7).map((d) => d['sales'] as double).toList();
      final averageDailySales = recentSales.reduce((a, b) => a + b) / recentSales.length;

      final forecast = List.generate(daysAhead, (index) {
        final forecastDate = now.add(Duration(days: index + 1));
        return {
          'date': forecastDate,
          'forecastSales': averageDailySales,
          'lowEstimate': averageDailySales * 0.8,
          'highEstimate': averageDailySales * 1.2,
          'confidence': 0.7, // 70% confidence
        };
      });

      return {
        'forecast': forecast,
        'confidence': 0.7,
        'basedOnDays': dailyData.length,
        'averageDailySales': averageDailySales,
        'trend': _calculateTrend(dailyData),
      };
    } catch (e) {
      print('Error getting sales forecast: $e');
      return {
        'forecast': [],
        'confidence': 0,
        'basedOnDays': 0,
        'message': 'Error generating forecast',
      };
    }
  }

  // Helper method to calculate trend
  static String _calculateTrend(List<dynamic> dailyData) {
    if (dailyData.length < 2) return 'stable';
    
    final recentData = dailyData.take(5).toList();
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < recentData.length; i++) {
      sumX += i.toDouble();
      sumY += recentData[i]['sales'] as double;
      sumXY += i * (recentData[i]['sales'] as double);
      sumX2 += i * i;
    }
    
    final n = recentData.length.toDouble();
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    
    if (slope > 0.1) return 'upward';
    if (slope < -0.1) return 'downward';
    return 'stable';
  }
}