import '../models/transaction.dart';

class TransactionService {
  // In a real app, this would connect to a database
  // For now, we'll use a local list
  static final List<TransactionModel> _transactions = [];

  static Future<List<TransactionModel>> getTransactions() async {
    return List.from(_transactions);
  }

  static Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.add(transaction);
    _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
  }

  static Future<List<TransactionModel>> getTransactionsByDate(DateTime date) async {
    return _transactions
        .where((transaction) =>
            transaction.transactionDate.year == date.year &&
            transaction.transactionDate.month == date.month &&
            transaction.transactionDate.day == date.day)
        .toList();
  }

  static Future<Map<String, dynamic>> getDailySummary(DateTime date) async {
    final transactions = await getTransactionsByDate(date);
    
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
    };
  }

  static Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    final transactions = _transactions.where((t) =>
        t.transactionDate.year == year && t.transactionDate.month == month).toList();
    
    final dailySales = <int, double>{};
    for (final transaction in transactions) {
      final day = transaction.transactionDate.day;
      dailySales[day] = (dailySales[day] ?? 0) + transaction.totalAmount;
    }
    
    final totalSales = transactions.fold(0.0, (sum, t) => sum + t.totalAmount);
    final totalTransactions = transactions.length;
    
    return {
      'year': year,
      'month': month,
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'dailySales': dailySales,
    };
  }
}