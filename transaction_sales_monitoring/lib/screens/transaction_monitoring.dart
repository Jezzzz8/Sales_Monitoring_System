// lib/screens/transaction_monitoring.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/settings_mixin.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../services/transaction_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/top_loading_indicator.dart';
import '../widgets/transaction_card.dart';

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
  bool _showTopLoading = false;
  
  // Filter states
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'All';
  String _selectedPaymentMethod = 'All';
  String _selectedTimeFilter = 'Daily'; // Daily, Weekly, Monthly
  final TextEditingController _searchController = TextEditingController();

  // Sales statistics
  Map<String, dynamic> _salesStats = {};
  bool _isLoadingStats = true;

  // Expanded state for transaction cards - FIXED: Using ValueNotifier for reactivity
  final ValueNotifier<Map<String, bool>> _expandedState = ValueNotifier<Map<String, bool>>({});
  
  // Scroll controller for back to top button
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  // Collapse all state - FIXED: Using ValueNotifier
  final ValueNotifier<bool> _allCollapsed = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTransactions();
    _loadSalesStatistics();
    
    // Set up scroll listener for back to top button
    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showBackToTopButton) {
        setState(() {
          _showBackToTopButton = true;
        });
      } else if (_scrollController.offset <= 400 && _showBackToTopButton) {
        setState(() {
          _showBackToTopButton = false;
        });
      }
    });
    
    // Initial data load with delay to show skeleton
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _searchController.dispose();
    _scrollController.dispose();
    _expandedState.dispose();
    _allCollapsed.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      // Load any necessary settings
    } catch (e) {
    }
    setState(() => _isLoadingSettings = false);
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
      _showTopLoading = true;
    });
    
    try {
      _transactionsStream = TransactionService.getTransactionsStream();
      
      // Listen to the stream and update local list
      _transactionsStream?.listen((transactions) {
        if (mounted) {
          // Filter out error transactions
          final validTransactions = transactions.where((transaction) => 
            !transaction.transactionNumber.startsWith('#ERROR-') && 
            !transaction.customerName.contains('Error Loading')
          ).toList();
          
          
          setState(() {
            _transactions = validTransactions;
            _isLoadingTransactions = false;
            _showTopLoading = false;
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _isLoadingTransactions = false;
            _showTopLoading = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingTransactions = false;
        _showTopLoading = false;
      });
    }
  }

  Future<void> _loadSalesStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      _salesStats = await TransactionService.getDailySummary(DateTime.now());
      setState(() => _isLoadingStats = false);
    } catch (e) {
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

  // Calculate statistics from local data with time filter
  double get _filteredSales {
    if (_isLoadingStats) return 0.0;
    
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedTimeFilter) {
      case 'Weekly':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      default: // Daily
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }
    
    return _filteredTransactions
        .where((t) => t.transactionDate.isAfter(startDate))
        .fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  int get _filteredTransactionsCount {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedTimeFilter) {
      case 'Weekly':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Monthly':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      default: // Daily
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }
    
    return _filteredTransactions
        .where((t) => t.transactionDate.isAfter(startDate))
        .length;
  }

  int get _pendingTransactionsCount {
    return _filteredTransactions
        .where((t) => t.status == 'Partial')
        .length;
  }

  List<TransactionModel> get _filteredTransactions {
    return _transactions.where((transaction) {
      // Apply time filter
      final now = DateTime.now();
      bool matchesTimeFilter = false;
      
      switch (_selectedTimeFilter) {
        case 'Weekly':
          final weekAgo = now.subtract(const Duration(days: 7));
          matchesTimeFilter = transaction.transactionDate.isAfter(weekAgo);
          break;
        case 'Monthly':
          final monthAgo = DateTime(now.year, now.month - 1, now.day);
          matchesTimeFilter = transaction.transactionDate.isAfter(monthAgo);
          break;
        default: // Daily
          matchesTimeFilter = transaction.transactionDate.day == _selectedDate.day &&
                             transaction.transactionDate.month == _selectedDate.month &&
                             transaction.transactionDate.year == _selectedDate.year;
          break;
      }
      
      final matchesStatus = _selectedStatus == 'All' || transaction.status == _selectedStatus;
      final matchesPaymentMethod = _selectedPaymentMethod == 'All' || transaction.paymentMethod == _selectedPaymentMethod;
      final matchesSearch = _searchController.text.isEmpty ||
          transaction.customerName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          transaction.transactionNumber.toLowerCase().contains(_searchController.text.toLowerCase());
      
      return matchesTimeFilter && matchesStatus && matchesPaymentMethod && matchesSearch;
    }).toList();
  }

  // NEW FUNCTION: Toggle collapse all - FIXED VERSION
  void _toggleCollapseAll() {
    // Toggle the state
    _allCollapsed.value = !_allCollapsed.value;
    
    // Create a new map with all transactions collapsed/expanded
    final newState = <String, bool>{};
    for (var transaction in _filteredTransactions) {
      newState[transaction.id] = _allCollapsed.value;
    }
    
    // Update the expanded state notifier
    _expandedState.value = newState;
  }

  // Back to top function
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  // Function to handle partial payment updates - FIXED VERSION
  Future<void> _handlePartialPayment(TransactionModel transaction, double amount) async {
    LoadingOverlay.show(context, message: 'Processing payment...');
    
    try {
      final result = await TransactionService.updateTransactionPayment(
        transaction.id,
        amount,
        'Payment update via Transaction Monitoring',
      );
      
      LoadingOverlay.hide();
      
      if (result['success'] == true) {
        // IMMEDIATE STATE UPDATE: Update the local transaction
        setState(() {
          // Find and update the transaction in the local list
          final index = _transactions.indexWhere((t) => t.id == transaction.id);
          if (index != -1) {
            // Create updated transaction with new values
            final updatedTransaction = _transactions[index].copyWith(
              amountPaid: (result['newAmountPaid'] as double?) ?? (transaction.amountPaid + amount),
              cashReceived: transaction.cashReceived + amount,
              status: (result['newStatus'] as String?) ?? 
                      (transaction.amountPaid + amount >= transaction.totalAmount ? 'Completed' : 'Partial'),
            );
            _transactions[index] = updatedTransaction;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of ₱${amount.toStringAsFixed(2)} recorded successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      LoadingOverlay.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _markAsComplete(TransactionModel transaction) async {
    LoadingOverlay.show(context, message: 'Updating order...');
    try {
      final result = await TransactionService.updateTransactionStatus(
        transaction.id,
        'Completed',
        'Marked as complete via Transaction Monitoring',
      );
      
      LoadingOverlay.hide();
      
      if (result['success'] == true) {
        // IMMEDIATE STATE UPDATE
        setState(() {
          final index = _transactions.indexWhere((t) => t.id == transaction.id);
          if (index != -1) {
            _transactions[index] = _transactions[index].copyWith(status: 'Completed');
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction ${transaction.transactionNumber} marked as completed'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      LoadingOverlay.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelOrder(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      LoadingOverlay.show(context, message: 'Cancelling order...');
      try {
        final result = await TransactionService.updateTransactionStatus(
          transaction.id,
          'Cancelled',
          'Order cancelled by admin',
        );
        
        LoadingOverlay.hide();
        
        if (result['success'] == true) {
          // IMMEDIATE STATE UPDATE
          setState(() {
            final index = _transactions.indexWhere((t) => t.id == transaction.id);
            if (index != -1) {
              _transactions[index] = _transactions[index].copyWith(status: 'Cancelled');
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${transaction.transactionNumber} has been cancelled'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['error']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        LoadingOverlay.hide();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _generateReceiptPDF(TransactionModel transaction) async {
    LoadingOverlay.show(context, message: 'Generating receipt...');
    
    try {
      // Create PDF document
      final pdf = pw.Document();
      
      // Add content to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Transaction Info
                pw.Text(
                  'Transaction #: ${transaction.transactionNumber}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Date: ${transaction.formattedDate} ${transaction.formattedTime}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Status: ${transaction.status}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                
                // Customer Info
                pw.Text(
                  'Customer: ${transaction.customerName}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                if (transaction.customerPhone.isNotEmpty && transaction.customerPhone != '-')
                  pw.Text(
                    'Phone: ${transaction.customerPhone}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                pw.SizedBox(height: 20),
                
                // Items Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                        pw.Padding(
                          child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                        pw.Padding(
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                        pw.Padding(
                          child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                      ],
                    ),
                    ...transaction.items.map((item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          child: pw.Text(item.productName),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                        pw.Padding(
                          child: pw.Text(item.quantity.toString()),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                        pw.Padding(
                          child: pw.Text('₱${item.unitPrice.toStringAsFixed(2)}'),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                        pw.Padding(
                          child: pw.Text('₱${item.total.toStringAsFixed(2)}'),
                          padding: const pw.EdgeInsets.all(8),
                        ),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 20),
                
                // Summary
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount:',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '₱${transaction.totalAmount.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Amount Paid:'),
                    pw.Text('₱${transaction.amountPaid.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cash Received:'),
                    pw.Text('₱${transaction.cashReceived.toStringAsFixed(2)}'),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Change:'),
                    pw.Text('₱${transaction.change.toStringAsFixed(2)}'),
                  ],
                ),
                if (transaction.status == 'Partial')
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Remaining Balance:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '₱${(transaction.totalAmount - transaction.amountPaid).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                pw.SizedBox(height: 10),
                
                // Payment Method
                pw.Text(
                  'Payment Method: ${transaction.paymentMethod}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                
                // Footer
                pw.SizedBox(height: 30),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF to device
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/receipt_${transaction.transactionNumber.replaceAll('#', '')}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      LoadingOverlay.hide();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt saved as PDF: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      LoadingOverlay.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors based on dark mode
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          body: Stack(
            children: [
              // Main content with scroll
              SingleChildScrollView(
                controller: _scrollController,
                padding: Responsive.getScreenPadding(context),
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
                        minHeight: isMobile ? 250 : 180,
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
                              
                              // Time Filter (Daily/Weekly/Monthly)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: ['Daily', 'Weekly', 'Monthly'].map((filter) {
                                    final isSelected = _selectedTimeFilter == filter;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedTimeFilter = filter;
                                          if (filter == 'Daily') {
                                            _selectedDate = DateTime.now();
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                            ? primaryColor 
                                            : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected 
                                              ? primaryColor 
                                              : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Text(
                                          filter,
                                          style: TextStyle(
                                            color: isSelected 
                                              ? Colors.white 
                                              : textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
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
                                    
                                    if (_selectedTimeFilter == 'Daily')
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
                                      items: ['All', 'Completed', 'Partial', 'Cancelled']
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
                                    
                                    if (_selectedTimeFilter == 'Daily')
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
                                    
                                    if (_selectedTimeFilter == 'Daily')
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
                                        items: ['All', 'Completed', 'Partial', 'Cancelled']
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
                                  // Total transactions indicator with collapse button
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _allCollapsed,
                                    builder: (context, allCollapsed, child) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Total: ${_filteredTransactions.length}',
                                              style: TextStyle(
                                                fontSize: Responsive.getBodyFontSize(context),
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Collapse All Button
                                            GestureDetector(
                                              onTap: _toggleCollapseAll,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: allCollapsed ? primaryColor.withOpacity(0.2) : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  allCollapsed ? Icons.expand_more : Icons.expand_less,
                                                  size: 16,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
                                          'Try adjusting your filters or time range',
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
                                ValueListenableBuilder<Map<String, bool>>(
                                  valueListenable: _expandedState,
                                  builder: (context, expandedState, child) {
                                    return Column(
                                      children: _filteredTransactions.map((transaction) {
                                        final isExpanded = expandedState[transaction.id] ?? false;
                                        return TransactionCard(
                                          key: ValueKey(transaction.id),
                                          transaction: transaction,
                                          onPrintReceipt: () => _generateReceiptPDF(transaction),
                                          onMarkComplete: () => _markAsComplete(transaction),
                                          onCancelOrder: () => _cancelOrder(transaction),
                                          onPartialPayment: (amount) => _handlePartialPayment(transaction, amount),
                                          showActions: true,
                                          isExpanded: isExpanded,
                                          onExpansionChanged: (expanded) {
                                            // Update the expanded state in the notifier
                                            final newState = Map<String, bool>.from(expandedState);
                                            newState[transaction.id] = expanded;
                                            _expandedState.value = newState;
                                          },
                                          primaryColor: primaryColor,
                                        );
                                      }).toList(),
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

              // Back to Top Button
              if (_showBackToTopButton)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _scrollToTop,
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    child: const Icon(Icons.arrow_upward),
                  ),
                ),
            ],
          ),
        ),
        // ADD TOP LOADING INDICATOR (like Facebook) - SIMILAR TO POS TRANSACTION
        if (_isLoadingStats || _isLoadingTransactions)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopLoadingIndicator(),
          ),
      ],
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
      )
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
              // Header with icon (removed refresh button)
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
                  // Removed: IconButton for manual refresh
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
                      '${_selectedTimeFilter.toUpperCase()} STATS',
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
                        "$_selectedTimeFilter Sales",
                        "₱${_filteredSales.toStringAsFixed(2)}",
                        Icons.attach_money,
                        Colors.green,
                        context,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        "$_selectedTimeFilter Transactions",
                        "$_filteredTransactionsCount",
                        Icons.receipt,
                        Colors.blue,
                        context,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        "Partial Orders",
                        "$_pendingTransactionsCount",
                        Icons.pending,
                        Colors.orange,
                        context,
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        "Avg. Sale",
                        "₱${_filteredTransactionsCount > 0 ? (_filteredSales / _filteredTransactionsCount).toStringAsFixed(2) : '0.00'}",
                        Icons.trending_up,
                        Colors.purple,
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
}