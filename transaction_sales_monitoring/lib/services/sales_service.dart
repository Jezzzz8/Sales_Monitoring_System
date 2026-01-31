
class SalesService {
  static Future<Map<String, dynamic>> getSalesSummary(DateTime startDate, DateTime endDate) async {
    
    // Simulate data
    return {
      'totalSales': 85000.0,
      'totalTransactions': 25,
      'averageSale': 3400.0,
      'dailyBreakdown': {
        'Monday': 12000.0,
        'Tuesday': 8000.0,
        'Wednesday': 10000.0,
        'Thursday': 15000.0,
        'Friday': 20000.0,
        'Saturday': 18000.0,
        'Sunday': 12000.0,
      },
      'topProducts': [
        {'name': 'Whole Lechon (21-23kg)', 'sales': 45000.0, 'quantity': 6},
        {'name': 'Lechon Belly (5kg)', 'sales': 18000.0, 'quantity': 8},
        {'name': 'Pork BBQ (10 sticks)', 'sales': 8000.0, 'quantity': 20},
      ],
    };
  }

  static Future<List<Map<String, dynamic>>> getSalesTrend(DateTime startDate, DateTime endDate) async {
    
    final List<Map<String, dynamic>> trend = [];
    DateTime current = startDate;
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      trend.add({
        'date': DateTime(current.year, current.month, current.day),
        'sales': 1000 + (DateTime.now().difference(current).inDays * 500).toDouble(),
        'transactions': 2 + (DateTime.now().difference(current).inDays % 5),
      });
      current = current.add(const Duration(days: 1));
    }
    
    return trend;
  }

  static Future<Map<String, double>> getCategorySales(DateTime startDate, DateTime endDate) async {
    
    return {
      'Whole Lechon': 45000.0,
      'Lechon Belly': 18000.0,
      'Appetizers': 8000.0,
      'Pork BBQ': 3000.0,
    };
  }
}