import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../widgets/transaction_card.dart';
import '../utils/responsive.dart';

class TransactionMonitoring extends StatefulWidget {
  const TransactionMonitoring({super.key});

  @override
  State<TransactionMonitoring> createState() => _TransactionMonitoringState();
}

class _TransactionMonitoringState extends State<TransactionMonitoring> {
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
    // Add more sample data for better stats
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

  // Updated stats to include more comprehensive data
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

  int get _totalTransactions {
    return _transactions.length;
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
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    return Scaffold(
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
                  // Header with Stats
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 150,
                    ),
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: Responsive.getCardPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TRANSACTION MONITORING',
                              style: TextStyle(
                                fontSize: Responsive.getTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track and manage all sales transactions',
                              style: TextStyle(
                                fontSize: Responsive.getBodyFontSize(context),
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: isMobile ? 2 : 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isMobile ? 1.5 : 1.8,
                              children: [
                                _buildStatCard(
                                  "Today's Sales",
                                  "₱${_todaySales.toStringAsFixed(2)}",
                                  Icons.attach_money,
                                  Colors.green,
                                  context,
                                ),
                                _buildStatCard(
                                  "Today's Transactions",
                                  "$_todayTransactions",
                                  Icons.receipt,
                                  Colors.blue,
                                  context,
                                ),
                                _buildStatCard(
                                  "Weekly Sales",
                                  "₱${_weeklySales.toStringAsFixed(2)}",
                                  Icons.trending_up,
                                  Colors.orange,
                                  context,
                                ),
                                _buildStatCard(
                                  "Pending",
                                  "$_pendingTransactions",
                                  Icons.pending,
                                  Colors.red,
                                  context,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filters
                  Container(
                    constraints: BoxConstraints(
                      minHeight: isMobile ? 300 : 150,
                    ),
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: Responsive.getCardPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'FILTERS',
                              style: TextStyle(
                                fontSize: Responsive.getSubtitleFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            if (isMobile)
                              Column(
                                children: [
                                  TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search by customer or transaction #',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                setState(() {
                                                  _searchController.clear();
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                    onChanged: (value) => setState(() {}),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.calendar_today, size: 20, color: Colors.deepOrange),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.arrow_drop_down, size: 20),
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
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedStatus,
                                    decoration: const InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: ['All', 'Completed', 'Pending', 'Cancelled']
                                        .map((status) => DropdownMenuItem(
                                              value: status,
                                              child: Text(status),
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
                                    decoration: const InputDecoration(
                                      labelText: 'Payment Method',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: ['All', 'Cash', 'GCash', 'Bank Transfer', 'Credit Card']
                                        .map((method) => DropdownMenuItem(
                                              value: method,
                                              child: Text(method),
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
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search by customer name or transaction number...',
                                        prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear),
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 20, color: Colors.deepOrange),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.arrow_drop_down, size: 20),
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedStatus,
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ['All', 'Completed', 'Pending', 'Cancelled']
                                          .map((status) => DropdownMenuItem(
                                                value: status,
                                                child: Text(status),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedStatus = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedPaymentMethod,
                                      decoration: const InputDecoration(
                                        labelText: 'Payment Method',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ['All', 'Cash', 'GCash', 'Bank Transfer', 'Credit Card']
                                          .map((method) => DropdownMenuItem(
                                                value: method,
                                                child: Text(method),
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

                  // Transactions List
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200,
                    ),
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: Responsive.getCardPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TRANSACTIONS',
                                  style: TextStyle(
                                    fontSize: Responsive.getTitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Total: ${_filteredTransactions.length} transactions',
                                  style: TextStyle(
                                    fontSize: Responsive.getBodyFontSize(context),
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _filteredTransactions.isEmpty
                                ? Container(
                                    constraints: BoxConstraints(
                                      minHeight: 150,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.receipt_long,
                                            size: 60,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No transactions found',
                                            style: TextStyle(
                                              fontSize: Responsive.getBodyFontSize(context),
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Try adjusting your filters or date',
                                            style: TextStyle(
                                              fontSize: Responsive.getBodyFontSize(context),
                                              color: Colors.grey,
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
                                      return TransactionCard(
                                        transaction: transaction,
                                        onTap: () => _showTransactionDetails(transaction),
                                        onPrintReceipt: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Receipt ${transaction.transactionNumber} sent to printer'),
                                              backgroundColor: Colors.blue,
                                            ),
                                          );
                                        },
                                        onMarkComplete: transaction.status == 'Pending' ? () {
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
                                        } : null,
                                        showActions: !isMobile,
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

  // UPDATED _buildStatCard method to match dashboard style
  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: Responsive.getFontSize(context, mobile: 20, tablet: 24, desktop: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text(
              transaction.transactionNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', transaction.customerName),
              if (transaction.customerPhone.isNotEmpty)
                _buildDetailRow('Phone', transaction.customerPhone),
              _buildDetailRow('Date', '${transaction.formattedDate} ${transaction.formattedTime}'),
              _buildDetailRow('Payment Method', transaction.paymentMethod),
              _buildDetailRow('Status', transaction.status),
              _buildDetailRow('Total Amount', '₱${transaction.totalAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Amount Paid', '₱${transaction.amountPaid.toStringAsFixed(2)}'),
              _buildDetailRow('Change', '₱${transaction.change.toStringAsFixed(2)}'),
              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildDetailRow('Notes', transaction.notes!),
              const SizedBox(height: 16),
              const Text(
                'Items Purchased:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 8),
              ...transaction.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.productName} x${item.quantity}'),
                    ),
                    Text('₱${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Receipt ${transaction.transactionNumber} sent to printer'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
            child: const Text('PRINT RECEIPT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}