// lib/screens/inventory_monitoring.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import '../utils/settings_mixin.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../services/transaction_service.dart';

class TransactionMonitoring extends StatefulWidget {
  const TransactionMonitoring({super.key});

  @override
  State<TransactionMonitoring> createState() => _TransactionMonitoringState();
}

class _TransactionMonitoringState extends State<TransactionMonitoring> with SettingsMixin {
  // Settings integration
  bool _isLoadingSettings = true;
  
  // Firebase data
  Stream<List<TransactionModel>>? _transactionsStream;
  List<TransactionModel> _transactions = [];
  bool _isLoadingTransactions = true;
  bool _isInitialLoad = true;
  
  // Filter states
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'All';
  String _selectedPaymentMethod = 'All';
  final TextEditingController _searchController = TextEditingController();

  // Sales statistics
  Map<String, dynamic> _salesStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTransactions();
    _loadSalesStatistics();
    
    // Initial data load with delay to show skeleton
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
    } catch (e) {
      print('Error loading settings in transactions: $e');
    }
    setState(() => _isLoadingSettings = false);
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      _transactionsStream = TransactionService.getTransactionsStream();
      // Listen to the stream and update local list
      _transactionsStream?.listen((transactions) {
        if (mounted) {
          print('Received ${transactions.length} transactions from Firebase');
          if (transactions.isNotEmpty) {
            print('First transaction: ${transactions.first.transactionNumber}');
            print('Customer: ${transactions.first.customerName}');
            print('Total: ${transactions.first.totalAmount}');
            print('Items: ${transactions.first.items.length}');
          }
          
          setState(() {
            _transactions = transactions;
            _isLoadingTransactions = false;
          });
        }
      }, onError: (error) {
        print('Error in transactions stream: $error');
        setState(() => _isLoadingTransactions = false);
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() => _isLoadingTransactions = false);
    }
  }

  Future<void> _loadSalesStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      _salesStats = await TransactionService.getDailySummary(now);
      setState(() => _isLoadingStats = false);
    } catch (e) {
      print('Error loading sales statistics: $e');
      setState(() {
        _salesStats = {
          'totalSales': 0.0,
          'totalTransactions': 0,
          'averageSale': 0.0,
          'topProducts': [],
          'paymentMethods': {},
        };
        _isLoadingStats = false;
      });
    }
  }

  // Calculate statistics from local data
  double get _todaySales {
    if (_isLoadingStats) return 0.0;
    return _salesStats['totalSales'] as double? ?? 0.0;
  }

  int get _todayTransactions {
    if (_isLoadingStats) return 0;
    return _salesStats['totalTransactions'] as int? ?? 0;
  }

  double get _weeklySales {
    // Calculate weekly sales from transactions
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _transactions
        .where((t) => t.transactionDate.isAfter(weekAgo))
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  // ignore: unused_element
  int get _weeklyTransactions {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _transactions
        .where((t) => t.transactionDate.isAfter(weekAgo))
        .length;
  }

  int get _pendingTransactions {
    return _transactions
        .where((t) => t.status == 'Pending')
        .length;
  }

  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((transaction) {
      final matchesDate = transaction.transactionDate.day == _selectedDate.day &&
                         transaction.transactionDate.month == _selectedDate.month &&
                         transaction.transactionDate.year == _selectedDate.year;
      final matchesStatus = _selectedStatus == 'All' || transaction.status == _selectedStatus;
      final matchesPaymentMethod = _selectedPaymentMethod == 'All' || transaction.paymentMethod == _selectedPaymentMethod;
      final matchesSearch = _searchController.text.isEmpty ||
          transaction.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          transaction.transactionNumber.toLowerCase().contains(_searchController.text.toLowerCase());
      
      return matchesDate && matchesStatus && matchesPaymentMethod && matchesSearch;
    }).toList();
  }

  Future<void> _markAsComplete(TransactionModel transaction) async {
    try {
      final result = await TransactionService.updateTransactionStatus(
        transaction.id,
        'Completed',
        'Marked as complete via Transaction Monitoring',
      );
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction ${transaction.transactionNumber} marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings || _isInitialLoad) {
      return _buildSkeletonScreen(context);
    }
    
    final primaryColor = getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors based on dark mode
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: Responsive.getScreenPadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Stats Card
                  if (_isLoadingStats || _isLoadingTransactions)
                    _buildSkeletonStatsCard(isMobile, isDarkMode, cardColor, context)
                  else
                    _buildTransactionStatsCard(
                      primaryColor,
                      isDarkMode,
                      cardColor,
                      textColor,
                      context,
                    ),

                  const SizedBox(height: 16),

                  // Filters Card
                  Container(
                    constraints: BoxConstraints(
                      minHeight: isMobile ? 200 : 150,
                    ),
                    child: Card(
                      elevation: isDarkMode ? 2 : 3,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: Responsive.getCardPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.filter_list,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'FILTER TRANSACTIONS',
                                    style: TextStyle(
                                      fontSize: Responsive.getTitleFontSize(context),
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (isMobile)
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                      border: Border.all(
                                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Search by customer or transaction #',
                                        hintStyle: TextStyle(color: mutedTextColor),
                                        prefixIcon: Icon(Icons.search, color: primaryColor),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 20, color: primaryColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.arrow_drop_down, size: 20, color: primaryColor),
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: _selectedDate,
                                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                              lastDate: DateTime.now(),
                                            );
                                            if (picked != null) {
                                              setState(() {
                                                _selectedDate = picked;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      labelText: 'Status',
                                      labelStyle: TextStyle(color: mutedTextColor),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: primaryColor),
                                      ),
                                      prefixIcon: Icon(Icons.stairs, color: primaryColor),
                                    ),
                                    items: ['All', 'Completed', 'Pending', 'Cancelled', 'Refunded']
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status, style: TextStyle(color: textColor)),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedStatus = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _selectedPaymentMethod,
                                    dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      labelText: 'Payment Method',
                                      labelStyle: TextStyle(color: mutedTextColor),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: primaryColor),
                                      ),
                                      prefixIcon: Icon(Icons.payment, color: primaryColor),
                                    ),
                                    items: ['All', 'Cash', 'GCash', 'Bank Transfer', 'Credit Card', 'PayMaya']
                                        .map((method) => DropdownMenuItem(
                                              value: method,
                                              child: Text(method, style: TextStyle(color: textColor)),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentMethod = value!;
                                      });
                                    },
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                                        border: Border.all(
                                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          hintText: 'Search by customer name or transaction number...',
                                          hintStyle: TextStyle(color: mutedTextColor),
                                          prefixIcon: Icon(Icons.search, color: primaryColor),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                        onChanged: (value) => setState(() {}),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 20, color: primaryColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.arrow_drop_down, size: 20, color: primaryColor),
                                            onPressed: () async {
                                              final picked = await showDatePicker(
                                                context: context,
                                                initialDate: _selectedDate,
                                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                                lastDate: DateTime.now(),
                                              );
                                              if (picked != null) {
                                                setState(() {
                                                  _selectedDate = picked;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        labelText: 'Status',
                                        labelStyle: TextStyle(color: mutedTextColor),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: primaryColor),
                                        ),
                                        prefixIcon: Icon(Icons.stairs, color: primaryColor),
                                      ),
                                      items: ['All', 'Completed', 'Pending', 'Cancelled', 'Refunded']
                                          .map((status) => DropdownMenuItem(
                                                value: status,
                                                child: Text(
                                                  status,
                                                  style: TextStyle(color: textColor),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedStatus = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedPaymentMethod,
                                      isExpanded: true,
                                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        labelText: 'Payment Method',
                                        labelStyle: TextStyle(color: mutedTextColor),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: primaryColor),
                                        ),
                                        prefixIcon: Icon(Icons.payment, color: primaryColor),
                                      ),
                                      items: ['All', 'Cash', 'GCash', 'Bank Transfer', 'Credit Card', 'PayMaya']
                                          .map((method) => DropdownMenuItem(
                                                value: method,
                                                child: Text(
                                                  method,
                                                  style: TextStyle(color: textColor),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPaymentMethod = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transactions List Card
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 200,
                    ),
                    child: Card(
                      elevation: isDarkMode ? 2 : 3,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: Responsive.getCardPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.receipt,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'TRANSACTION HISTORY',
                                      style: TextStyle(
                                        fontSize: Responsive.getTitleFontSize(context),
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    'Total: ${_filteredTransactions.length}',
                                    style: TextStyle(
                                      fontSize: Responsive.getBodyFontSize(context),
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            if (_isLoadingTransactions)
                              _buildSkeletonTransactions(isDarkMode, mutedTextColor, context)
                            else if (_filteredTransactions.isEmpty)
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 150,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long,
                                        size: 60,
                                        color: mutedTextColor,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No transactions found',
                                        style: TextStyle(
                                          fontSize: Responsive.getBodyFontSize(context),
                                          color: mutedTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try adjusting your filters or date',
                                        style: TextStyle(
                                          fontSize: Responsive.getBodyFontSize(context),
                                          color: mutedTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredTransactions.length,
                                itemBuilder: (context, index) {
                                  final transaction = _filteredTransactions[index];
                                  return _buildTransactionCard(
                                    transaction, 
                                    primaryColor, 
                                    context, 
                                    isMobile,
                                    isDarkMode: isDarkMode,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedTextColor: mutedTextColor,
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonScreen(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor();
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: Responsive.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton Stats Card
            _buildSkeletonStatsCard(isMobile, isDarkMode, 
              isDarkMode ? Colors.grey.shade800 : Colors.white, 
              context
            ),

            const SizedBox(height: 16),

            // Skeleton Filters Card
            Container(
              constraints: BoxConstraints(
                minHeight: isMobile ? 200 : 150,
              ),
              child: Card(
                elevation: isDarkMode ? 2 : 3,
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: Responsive.getCardPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 150,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (isMobile)
                        Column(
                          children: [
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                            SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Skeleton Transactions List
            Container(
              constraints: const BoxConstraints(
                minHeight: 200,
              ),
              child: Card(
                elevation: isDarkMode ? 2 : 3,
                color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: Responsive.getCardPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 200,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 80,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Skeleton transaction cards
                      for (int i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonStatsCard(bool isMobile, bool isDarkMode, Color cardColor, BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 150,
      ),
      child: Card(
        elevation: isDarkMode ? 2 : 3,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Padding(
          padding: Responsive.getCardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 200,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Skeleton subtitle
              Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Skeleton stats grid
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Responsive.buildResponsiveCardGrid(
                    context: context,
                    title: '',
                    titleColor: Colors.transparent,
                    centerTitle: true,
                    cards: [
                      _buildSkeletonStatCard(isDarkMode, context),
                      _buildSkeletonStatCard(isDarkMode, context),
                      _buildSkeletonStatCard(isDarkMode, context),
                      _buildSkeletonStatCard(isDarkMode, context),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonStatCard(bool isDarkMode, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16) * 0.8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 80,
            height: 16,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonTransactions(bool isDarkMode, Color mutedTextColor, BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 120,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionStatsCard(
    Color primaryColor,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    BuildContext context,
  ) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      constraints: const BoxConstraints(
        minHeight: 150,
      ),
      child: Card(
        elevation: isDarkMode ? 2 : 3,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Padding(
          padding: Responsive.getCardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'TRANSACTION MONITORING',
                      style: TextStyle(
                        fontSize: Responsive.getTitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Track and manage all sales transactions',
                style: TextStyle(
                  fontSize: Responsive.getBodyFontSize(context),
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Centered Stats Grid
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'TRANSACTION STATS',
                      style: TextStyle(
                        fontSize: Responsive.getSubtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Responsive.buildResponsiveCardGrid(
                    context: context,
                    title: '',
                    titleColor: primaryColor,
                    centerTitle: true,
                    cards: [
                      _buildStatCard(
                        "Today's Sales",
                        "₱${_todaySales.toStringAsFixed(2)}",
                        Icons.attach_money,
                        Colors.green,
                        context,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        "Today's Transactions",
                        "$_todayTransactions",
                        Icons.receipt,
                        Colors.blue,
                        context,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        "Weekly Sales",
                        "₱${_weeklySales.toStringAsFixed(2)}",
                        Icons.trending_up,
                        Colors.orange,
                        context,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        "Pending",
                        "$_pendingTransactions",
                        Icons.pending,
                        Colors.red,
                        context,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, 
      {bool isDarkMode = false}) {
    return Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16) * 0.8),
      decoration: BoxDecoration(
        color: isDarkMode ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: Responsive.getIconSize(context, multiplier: 1.2)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14) * 0.9,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18) * 0.9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionCard(TransactionModel transaction, Color primaryColor, BuildContext context, bool isMobile, {
    bool isDarkMode = false,
    Color? cardColor,
    Color? textColor,
    Color? mutedTextColor,
  }) {
    final innerCardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    
    return Card(
      elevation: isDarkMode ? 1 : 2,
      margin: EdgeInsets.only(bottom: Responsive.getPaddingSize(context)),
      color: innerCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: Responsive.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Use displayTransactionNumber instead of transactionNumber
                        transaction.displayTransactionNumber,
                        style: TextStyle(
                          fontSize: Responsive.getSubtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: mutedTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${transaction.formattedTime}',
                            style: TextStyle(
                              fontSize: 10,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(transaction.status, isDarkMode: isDarkMode),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: Responsive.getIconSize(context, multiplier: 0.8),
                  color: mutedTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.customerName,
                        style: TextStyle(
                          fontSize: Responsive.getBodyFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (transaction.customerPhone.isNotEmpty && transaction.customerPhone != '-')
                        Text(
                          transaction.customerPhone,
                          style: TextStyle(
                            fontSize: 11,
                            color: mutedTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: Responsive.getIconSize(context, multiplier: 0.7),
                  color: mutedTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  transaction.formattedDate,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                    color: mutedTextColor,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.payment,
                  size: Responsive.getIconSize(context, multiplier: 0.7),
                  color: mutedTextColor,
                ),
                const SizedBox(width: 8),
                Text(
                  transaction.paymentMethod,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Transaction Items Summary
            if (transaction.items.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items (${transaction.items.length}):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: mutedTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...transaction.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(color: mutedTextColor),
                          ),
                          Expanded(
                            child: Text(
                              '${item.productName} x${item.quantity}',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (transaction.items.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${transaction.items.length - 2} more items',
                          style: TextStyle(
                            fontSize: 10,
                            color: mutedTextColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                        color: mutedTextColor,
                      ),
                    ),
                    Text(
                      '₱${transaction.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: Responsive.getSubtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                
                if (!isMobile) ...[
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.receipt, size: 20, color: primaryColor),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Receipt ${transaction.transactionNumber} sent to printer'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        tooltip: 'Print Receipt',
                      ),
                      if (transaction.status == 'Pending')
                        IconButton(
                          icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                          onPressed: () => _markAsComplete(transaction),
                          tooltip: 'Mark as Complete',
                        ),
                      if (transaction.status == 'Completed')
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20, color: Colors.orange),
                          onPressed: () {
                            // TODO: Implement refund functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refund functionality coming soon'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          tooltip: 'Refund Transaction',
                        ),
                    ],
                  ),
                ],
              ],
            ),
            
            // Action Buttons for Mobile
            if (isMobile) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Receipt ${transaction.transactionNumber} sent to printer'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: Icon(Icons.receipt, size: 16, color: primaryColor),
                      label: Text(
                        'Print',
                        style: TextStyle(color: primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (transaction.status == 'Pending')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsComplete(transaction),
                        icon: Icon(Icons.check_circle, size: 16, color: Colors.white),
                        label: Text('Complete', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (transaction.status == 'Completed')
                    const SizedBox(width: 8),
                  if (transaction.status == 'Completed')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement refund functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Refund functionality coming soon'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: Icon(Icons.refresh, size: 16, color: Colors.orange),
                        label: const Text(
                          'Refund',
                          style: TextStyle(color: Colors.orange),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, {bool isDarkMode = false}) {
    Color chipColor;
    Color textColor;
    IconData? icon;
    
    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = isDarkMode ? Colors.green.shade900 : Colors.green.shade100;
        textColor = isDarkMode ? Colors.green.shade200 : Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'pending':
        chipColor = isDarkMode ? Colors.orange.shade900 : Colors.orange.shade100;
        textColor = isDarkMode ? Colors.orange.shade200 : Colors.orange.shade800;
        icon = Icons.pending;
        break;
      case 'cancelled':
        chipColor = isDarkMode ? Colors.red.shade900 : Colors.red.shade100;
        textColor = isDarkMode ? Colors.red.shade200 : Colors.red.shade800;
        icon = Icons.cancel;
        break;
      case 'refunded':
        chipColor = isDarkMode ? Colors.purple.shade900 : Colors.purple.shade100;
        textColor = isDarkMode ? Colors.purple.shade200 : Colors.purple.shade800;
        icon = Icons.refresh;
        break;
      default:
        chipColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
        textColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800;
        icon = Icons.info;
    }
    
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}