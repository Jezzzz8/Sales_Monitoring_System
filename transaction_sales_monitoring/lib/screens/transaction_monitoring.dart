import 'package:flutter/material.dart';
import '../utils/settings_mixin.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

class TransactionMonitoring extends StatefulWidget {
  const TransactionMonitoring({super.key});

  @override
  State<TransactionMonitoring> createState() => _TransactionMonitoringState();
}

class _TransactionMonitoringState extends State<TransactionMonitoring> with SettingsMixin {
  // Settings integration
  // ignore: unused_field
  AppSettings? _settings;
  // ignore: unused_field
  bool _isLoadingSettings = true;
  
  final List<TransactionModel> _transactions = [
    TransactionModel(
      id: '1',
      transactionNumber: 'TRX-001',
      transactionDate: DateTime.now().subtract(const Duration(hours: 2)),
      customerName: 'Juan Dela Cruz',
      customerPhone: '09171234567',
      paymentMethod: 'Cash',
      totalAmount: 2700,
      amountPaid: 3000,
      change: 300,
      status: 'Completed',
      items: [
        TransactionItem(
          productId: '3',
          productName: 'Lechon Belly (3kls)',
          quantity: 1,
          unitPrice: 2700,
          total: 2700,
        ),
      ],
      notes: 'For pickup at 5 PM',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionModel(
      id: '2',
      transactionNumber: 'TRX-002',
      transactionDate: DateTime.now().subtract(const Duration(hours: 4)),
      customerName: 'Maria Santos',
      customerPhone: '09172345678',
      paymentMethod: 'GCash',
      totalAmount: 8000,
      amountPaid: 8000,
      change: 0,
      status: 'Completed',
      items: [
        TransactionItem(
          productId: '2',
          productName: 'Whole Lechon (21-23kls)',
          quantity: 1,
          unitPrice: 8000,
          total: 8000,
        ),
      ],
      notes: 'Birthday celebration',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    TransactionModel(
      id: '3',
      transactionNumber: 'TRX-003',
      transactionDate: DateTime.now().subtract(const Duration(days: 1)),
      customerName: 'Pedro Gomez',
      customerPhone: '09173456789',
      paymentMethod: 'Cash',
      totalAmount: 1400,
      amountPaid: 1500,
      change: 100,
      status: 'Completed',
      items: [
        TransactionItem(
          productId: '5',
          productName: 'Pork BBQ (10 sticks)',
          quantity: 1,
          unitPrice: 400,
          total: 400,
        ),
        TransactionItem(
          productId: '6',
          productName: 'Dinakdakan',
          quantity: 1,
          unitPrice: 1000,
          total: 1000,
        ),
      ],
      notes: 'Family gathering',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: '4',
      transactionNumber: 'TRX-004',
      transactionDate: DateTime.now().subtract(const Duration(days: 2)),
      customerName: 'Ana Reyes',
      customerPhone: '09174567890',
      paymentMethod: 'Bank Transfer',
      totalAmount: 4500,
      amountPaid: 4500,
      change: 0,
      status: 'Completed',
      items: [
        TransactionItem(
          productId: '4',
          productName: 'Lechon Belly (3kg)',
          quantity: 2,
          unitPrice: 1800,
          total: 3600,
        ),
        TransactionItem(
          productId: '7',
          productName: 'Pork BBQ (10 sticks)',
          quantity: 1,
          unitPrice: 400,
          total: 400,
        ),
      ],
      notes: 'Office party',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    TransactionModel(
      id: '5',
      transactionNumber: 'TRX-005',
      transactionDate: DateTime.now().subtract(const Duration(days: 3)),
      customerName: 'Carlos Lim',
      customerPhone: '09175678901',
      paymentMethod: 'GCash',
      totalAmount: 12000,
      amountPaid: 12000,
      change: 0,
      status: 'Pending',
      items: [
        TransactionItem(
          productId: '1',
          productName: 'Whole Lechon (18-20kg)',
          quantity: 2,
          unitPrice: 6000,
          total: 12000,
        ),
      ],
      notes: 'Wedding reception',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'All';
  String _selectedPaymentMethod = 'All';
  final TextEditingController _searchController = TextEditingController();


  // ignore: unused_element
  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      _settings = await SettingsService.loadSettings();
    } catch (e) {
      print('Error loading settings in transactions: $e');
      _settings = AppSettings();
    }
    setState(() => _isLoadingSettings = false);
  }

  double get _todaySales {
    return _transactions
        .where((t) => t.transactionDate.day == DateTime.now().day)
        .fold(0, (sum, t) => sum + t.totalAmount);
  }

  int get _todayTransactions {
    return _transactions
        .where((t) => t.transactionDate.day == DateTime.now().day)
        .length;
  }

  double get _weeklySales {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _transactions
        .where((t) => t.transactionDate.isAfter(weekAgo))
        .fold(0, (sum, t) => sum + t.totalAmount);
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
      final matchesDate = transaction.transactionDate.day == _selectedDate.day;
      final matchesStatus = _selectedStatus == 'All' || transaction.status == _selectedStatus;
      final matchesPaymentMethod = _selectedPaymentMethod == 'All' || transaction.paymentMethod == _selectedPaymentMethod;
      final matchesSearch = _searchController.text.isEmpty ||
          transaction.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          transaction.transactionNumber.contains(_searchController.text);
      
      return matchesDate && matchesStatus && matchesPaymentMethod && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
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
                  // ENHANCED: Transaction Stats Card with centered content
                  _buildTransactionStatsCard(
                    primaryColor,
                    isDarkMode,
                    cardColor,
                    textColor,
                    context,
                  ),

                  const SizedBox(height: 16),

                  // UPDATED: Filters Card with theme
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
                                    initialValue: _selectedStatus,
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
                                    items: ['All', 'Completed', 'Pending', 'Cancelled']
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
                                    initialValue: _selectedPaymentMethod,
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
                                    items: ['All', 'Cash', 'GCash', 'Bank Transfer', 'Credit Card']
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
                                      initialValue: _selectedStatus,
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
                                      items: ['All', 'Completed', 'Pending', 'Cancelled']
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
                                      initialValue: _selectedPaymentMethod,
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
                                      items: ['All', 'Cash', 'GCash', 'Bank Transfer', 'Credit Card']
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

                  // UPDATED: Transactions List Card with theme
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
                                      'RECENT TRANSACTIONS',
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
                            _filteredTransactions.isEmpty
                                ? Container(
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
                                : ListView.builder(
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
              
              // Centered Stats Grid - Updated to match SalesMonitoring style
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
                  child: Text(
                    transaction.transactionNumber,
                    style: TextStyle(
                      fontSize: Responsive.getSubtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
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
                  child: Text(
                    transaction.customerName,
                    style: TextStyle(
                      fontSize: Responsive.getBodyFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                        icon: const Icon(Icons.receipt, size: 20),
                        color: primaryColor,
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
                          icon: const Icon(Icons.check_circle, size: 20),
                          color: Colors.green,
                          onPressed: () {
                            setState(() {
                              final idx = _transactions.indexWhere((t) => t.id == transaction.id);
                              if (idx != -1) {
                                _transactions[idx] = TransactionModel(
                                  id: transaction.id,
                                  transactionNumber: transaction.transactionNumber,
                                  transactionDate: transaction.transactionDate,
                                  customerName: transaction.customerName,
                                  customerPhone: transaction.customerPhone,
                                  paymentMethod: transaction.paymentMethod,
                                  totalAmount: transaction.totalAmount,
                                  amountPaid: transaction.amountPaid,
                                  change: transaction.change,
                                  status: 'Completed',
                                  items: transaction.items,
                                  notes: transaction.notes,
                                  createdAt: transaction.createdAt,
                                );
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Transaction ${transaction.transactionNumber} marked as completed'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          tooltip: 'Mark as Complete',
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
                        onPressed: () {
                          setState(() {
                            final idx = _transactions.indexWhere((t) => t.id == transaction.id);
                            if (idx != -1) {
                              _transactions[idx] = TransactionModel(
                                id: transaction.id,
                                transactionNumber: transaction.transactionNumber,
                                transactionDate: transaction.transactionDate,
                                customerName: transaction.customerName,
                                customerPhone: transaction.customerPhone,
                                paymentMethod: transaction.paymentMethod,
                                totalAmount: transaction.totalAmount,
                                amountPaid: transaction.amountPaid,
                                change: transaction.change,
                                status: 'Completed',
                                items: transaction.items,
                                notes: transaction.notes,
                                createdAt: transaction.createdAt,
                              );
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Transaction ${transaction.transactionNumber} marked as completed'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                        label: const Text('Complete', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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