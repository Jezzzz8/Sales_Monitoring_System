import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';

class SalesMonitoring extends StatefulWidget {
  const SalesMonitoring({super.key});

  @override
  State<SalesMonitoring> createState() => _SalesMonitoringState();
}

class _SalesMonitoringState extends State<SalesMonitoring> {
  DateTime _selectedDate = DateTime.now();
  String _selectedView = 'Daily';
  String _selectedCategory = 'All';
  
  // Sample sales data
  final List<TransactionModel> _sampleTransactions = [
    for (int i = 0; i < 30; i++)
      TransactionModel(
        id: '$i',
        transactionNumber: 'TRX-$i',
        transactionDate: DateTime.now().subtract(Duration(days: i)),
        customerName: 'Customer $i',
        customerPhone: '0917000000$i',
        paymentMethod: i % 3 == 0 ? 'Cash' : 'GCash',
        totalAmount: 1000 + (i * 500) % 8000,
        amountPaid: 1000 + (i * 500) % 8000,
        change: 0,
        status: 'Completed',
        items: [
          TransactionItem(
            productId: '1',
            productName: 'Product $i',
            quantity: 1 + (i % 3),
            unitPrice: (1000 + (i * 500) % 8000) / (1 + (i % 3)),
            total: 1000 + (i * 500) % 8000,
          ),
        ],
        notes: '',
        createdAt: DateTime.now().subtract(Duration(days: i)),
      ),
  ];

  // Simple data structures without charts
  List<Map<String, dynamic>> get _dailySalesData {
    final dailySales = <DateTime, double>{};
    
    for (final transaction in _sampleTransactions) {
      final date = DateTime(
        transaction.transactionDate.year,
        transaction.transactionDate.month,
        transaction.transactionDate.day,
      );
      
      dailySales[date] = (dailySales[date] ?? 0) + transaction.totalAmount;
    }
    
    return dailySales.entries
        .map((entry) => {
              'date': entry.key,
              'sales': entry.value,
              'label': '${entry.key.day}/${entry.key.month}',
            })
        .toList()
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  List<Map<String, dynamic>> get _categorySalesData {
    return [
      {'category': 'Whole Lechon', 'sales': 45000.0, 'color': Colors.deepOrange},
      {'category': 'Lechon Belly', 'sales': 18000.0, 'color': Colors.orange},
      {'category': 'Appetizers', 'sales': 8000.0, 'color': Colors.green},
      {'category': 'Pork BBQ', 'sales': 3000.0, 'color': Colors.blue},
      {'category': 'Others', 'sales': 2000.0, 'color': Colors.purple},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final padding = Responsive.getScreenPadding(context);
    
    final displayedData = _selectedView == 'Daily' 
        ? _dailySalesData.take(isMobile ? 5 : 7).toList()
        : _dailySalesData.take(isMobile ? 4 : 6).toList();

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 120,
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
                              'SALES MONITORING & ANALYTICS',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track sales performance, identify trends, and make data-driven decisions',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                      minHeight: isMobile ? 250 : 150,
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
                              'VIEW OPTIONS',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 12),
                            isMobile
                                ? Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedView,
                                        decoration: const InputDecoration(
                                          labelText: 'Time Period',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['Daily', 'Weekly', 'Monthly']
                                            .map((view) => DropdownMenuItem(
                                                  value: view,
                                                  child: Text(view),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedView = value!;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedCategory,
                                        decoration: const InputDecoration(
                                          labelText: 'Category Filter',
                                          border: OutlineInputBorder(),
                                        ),
                                        items: ['All', 'Whole Lechon', 'Lechon Belly', 'Appetizers']
                                            .map((category) => DropdownMenuItem(
                                                  value: category,
                                                  child: Text(category),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedCategory = value!;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      _buildDatePicker(context, isMobile),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedView,
                                          decoration: const InputDecoration(
                                            labelText: 'Time Period',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: ['Daily', 'Weekly', 'Monthly']
                                              .map((view) => DropdownMenuItem(
                                                    value: view,
                                                    child: Text(view),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedView = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedCategory,
                                          decoration: const InputDecoration(
                                            labelText: 'Category Filter',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: ['All', 'Whole Lechon', 'Lechon Belly', 'Appetizers']
                                              .map((category) => DropdownMenuItem(
                                                    value: category,
                                                    child: Text(category),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCategory = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildDatePicker(context, isMobile),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sales Chart (Simplified)
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 300,
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
                              'SALES TREND',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: isMobile ? 250 : 300,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: displayedData.length,
                                itemBuilder: (context, index) {
                                  final data = displayedData[index];
                                  final sales = data['sales'] as double;
                                  final label = data['label'] as String;
                                  final maxSales = displayedData
                                      .map((d) => d['sales'] as double)
                                      .reduce((a, b) => a > b ? a : b);
                                  
                                  return Container(
                                    width: isMobile ? 50 : 60,
                                    margin: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₱${(sales / 1000).toStringAsFixed(0)}K',
                                          style: TextStyle(
                                            fontSize: Responsive.getFontSize(context, mobile: 9, tablet: 10, desktop: 11),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          height: (sales / maxSales) * (isMobile ? 150 : 200),
                                          width: isMobile ? 30 : 40,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [Colors.deepOrange, Colors.orange],
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.deepOrange.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              (sales / 1000).toStringAsFixed(0),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: Responsive.getFontSize(context, mobile: 8, tablet: 9, desktop: 10),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: Responsive.getFontSize(context, mobile: 9, tablet: 10, desktop: 11),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: _buildLegendItem(Colors.deepOrange, 'Sales'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Sales (Simplified)
                  Container(
                    constraints: BoxConstraints(
                      minHeight: isMobile ? 350 : 250,
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
                              'CATEGORY PERFORMANCE',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: isMobile ? 350 : 250,
                              child: isMobile
                                  ? ListView.builder(
                                      scrollDirection: Axis.vertical,
                                      itemCount: _categorySalesData.length,
                                      itemBuilder: (context, index) {
                                        final data = _categorySalesData[index];
                                        final category = data['category'] as String;
                                        final sales = data['sales'] as double;
                                        final color = data['color'] as Color;
                                        final percentage = (sales / 76000) * 100;
                                        
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      category,
                                                      style: TextStyle(
                                                        fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      '₱${sales.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                        fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.deepOrange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '${percentage.toStringAsFixed(1)}% of total sales',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                LinearProgressIndicator(
                                                  value: percentage / 100,
                                                  backgroundColor: color.withOpacity(0.2),
                                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                                  minHeight: 8,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : GridView.count(
                                      crossAxisCount: isTablet ? 2 : 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      children: _categorySalesData.map((data) {
                                        final category = data['category'] as String;
                                        final sales = data['sales'] as double;
                                        final color = data['color'] as Color;
                                        
                                        return Card(
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: color.withOpacity(0.3), width: 2),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${(sales / 1000).toStringAsFixed(0)}K',
                                                      style: TextStyle(
                                                        fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                                        fontWeight: FontWeight.bold,
                                                        color: color,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  category,
                                                  style: TextStyle(
                                                    fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₱${sales.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Key Metrics
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
                              'KEY METRICS',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: isMobile ? 2 : 4,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isMobile ? 1.2 : 1.5,
                              children: [
                                _buildMetricCard(
                                  'Total Sales (30 days)',
                                  '₱${_sampleTransactions.fold(0.0, (sum, t) => sum + t.totalAmount).toStringAsFixed(2)}',
                                  Icons.attach_money,
                                  Colors.green,
                                  context,
                                ),
                                _buildMetricCard(
                                  'Average Daily Sales',
                                  '₱${(_sampleTransactions.fold(0.0, (sum, t) => sum + t.totalAmount) / 30).toStringAsFixed(2)}',
                                  Icons.trending_up,
                                  Colors.blue,
                                  context,
                                ),
                                _buildMetricCard(
                                  'Highest Sale',
                                  '₱${_sampleTransactions.map((t) => t.totalAmount).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
                                  Icons.arrow_upward,
                                  Colors.orange,
                                  context,
                                ),
                                _buildMetricCard(
                                  'Transactions Count',
                                  '${_sampleTransactions.length}',
                                  Icons.receipt,
                                  Colors.purple,
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

                  // Peak Hours Analysis
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
                            Text(
                              'PEAK HOURS ANALYSIS',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Identifies busiest times to optimize operations',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            isMobile
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: 4,
                                    itemBuilder: (context, index) {
                                      final slots = [
                                        {'slot': '8AM-11AM', 'transactions': 5, 'sales': 15000.0, 'average': 3000.0},
                                        {'slot': '11AM-2PM', 'transactions': 8, 'sales': 24000.0, 'average': 3000.0},
                                        {'slot': '2PM-5PM', 'transactions': 6, 'sales': 12000.0, 'average': 2000.0},
                                        {'slot': '5PM-8PM', 'transactions': 4, 'sales': 8000.0, 'average': 2000.0},
                                      ][index];
                                      
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                slots['slot'] as String,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Transactions:',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${slots['transactions']}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Total Sales:',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      Text(
                                                        '₱${(slots['sales'] as double).toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Average:',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      Text(
                                                        '₱${(slots['average'] as double).toStringAsFixed(0)}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : DataTable(
                                    columns: [
                                      const DataColumn(label: Text('Time Slot')),
                                      const DataColumn(label: Text('Transactions')),
                                      const DataColumn(label: Text('Total Sales')),
                                      const DataColumn(label: Text('Average Sale')),
                                    ],
                                    rows: [
                                      _buildTimeSlotRow('8AM-11AM', 5, 15000.0, 3000.0),
                                      _buildTimeSlotRow('11AM-2PM', 8, 24000.0, 3000.0),
                                      _buildTimeSlotRow('2PM-5PM', 6, 12000.0, 2000.0),
                                      _buildTimeSlotRow('5PM-8PM', 4, 8000.0, 2000.0),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Insights Card
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 150,
                    ),
                    child: Card(
                      elevation: 3,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: Responsive.getCardPadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  'BUSINESS INSIGHTS',
                                  style: TextStyle(
                                    fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInsightItem(
                              'Peak sales occur between 11AM-2PM',
                              'Consider preparing more inventory during these hours',
                              context,
                            ),
                            _buildInsightItem(
                              'Whole Lechon accounts for 60% of revenue',
                              'Focus on promoting this high-margin product',
                              context,
                            ),
                            _buildInsightItem(
                              'Average transaction value: ₱3,000',
                              'Create bundles to increase average sale',
                              context,
                            ),
                            _buildInsightItem(
                              'Slow days: Tuesday and Wednesday',
                              'Consider special promotions on these days',
                              context,
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

  Widget _buildDatePicker(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: isMobile ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          const Icon(Icons.calendar_today, size: 20, color: Colors.deepOrange),
          const SizedBox(width: 8),
          Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: Responsive.getFontSize(context, mobile: 20, tablet: 24, desktop: 28)),
              const Spacer(),
              if (title.contains('Trending'))
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '+12%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  DataRow _buildTimeSlotRow(String slot, int transactions, double sales, double average) {
    return DataRow(cells: [
      DataCell(Text(slot, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('$transactions', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      DataCell(Text('₱${sales.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text('₱${average.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildInsightItem(String title, String description, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_right, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}