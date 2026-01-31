import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

class SalesMonitoring extends StatefulWidget {
  const SalesMonitoring({super.key});

  @override
  State<SalesMonitoring> createState() => _SalesMonitoringState();
}

class _SalesMonitoringState extends State<SalesMonitoring> {
  // Settings integration
  AppSettings? _settings;
  bool _isLoadingSettings = true;
  
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      _settings = await SettingsService.loadSettings();
    } catch (e) {
      print('Error loading settings in sales: $e');
      _settings = AppSettings();
    }
    setState(() => _isLoadingSettings = false);
  }

  Color _getPrimaryColor() {
    return _settings?.primaryColorValue ?? Colors.deepOrange;
  }

  // Simple data structures
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
        .map((entry) => ({
              'date': entry.key,
              'sales': entry.value,
              'label': '${entry.key.day}/${entry.key.month}',
            }))
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

  double get _totalRevenue {
    return _sampleTransactions.fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  double get _averageDailySales {
    return _totalRevenue / (_dailySalesData.isNotEmpty ? _dailySalesData.length : 1);
  }

  double get _highestSale {
    return _sampleTransactions.map((t) => t.totalAmount).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final primaryColor = _getPrimaryColor();
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
                  // Quick Stats Grid
                  Responsive.buildResponsiveCardGrid(
                    context: context,
                    title: 'SALES OVERVIEW',
                    titleColor: primaryColor,
                    centerTitle: true,
                    cards: [
                      _buildStatCard(
                        'Total Revenue',
                        '₱${_totalRevenue.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                        context,
                      ),
                      _buildStatCard(
                        'Avg Daily Sales',
                        '₱${_averageDailySales.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.blue,
                        context,
                      ),
                      _buildStatCard(
                        'Highest Sale',
                        '₱${_highestSale.toStringAsFixed(2)}',
                        Icons.arrow_upward,
                        Colors.orange,
                        context,
                      ),
                      _buildStatCard(
                        'Transactions',
                        '${_sampleTransactions.length}',
                        Icons.receipt,
                        Colors.purple,
                        context,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filters Card
                  Container(
                    constraints: BoxConstraints(
                      minHeight: isMobile ? 200 : 150,
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
                              'FILTER OPTIONS',
                              style: TextStyle(
                                fontSize: Responsive.getSubtitleFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            isMobile
                                ? Column(
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _selectedView,
                                        decoration: InputDecoration(
                                          labelText: 'Time Period',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
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
                                        value: _selectedCategory,
                                        decoration: InputDecoration(
                                          labelText: 'Category',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.category, color: primaryColor),
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
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedView,
                                          decoration: InputDecoration(
                                            labelText: 'Time Period',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
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
                                          value: _selectedCategory,
                                          decoration: InputDecoration(
                                            labelText: 'Category Filter',
                                            border: OutlineInputBorder(),
                                            prefixIcon: Icon(Icons.category, color: primaryColor),
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
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sales Trend Chart
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
                                fontSize: Responsive.getTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: isMobile ? 250 : 300,
                              child: _buildSalesChart(primaryColor, isMobile),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Performance
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
                                fontSize: Responsive.getTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: isMobile ? 350 : 250,
                              child: isMobile
                                  ? SingleChildScrollView(
                                      child: Column(
                                        children: _categorySalesData
                                            .map((data) => _buildCategoryCard(data, true))
                                            .toList(),
                                      ),
                                    )
                                  : GridView.count(
                                      crossAxisCount: isTablet ? 2 : 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      children: _categorySalesData
                                          .map((data) => _buildCategoryCard(data, false))
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Peak Hours Card
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
                            'PEAK HOURS',
                            style: TextStyle(
                              fontSize: Responsive.getTitleFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          isMobile
                              ? Column(
                                  children: [
                                    _buildTimeSlotCard('8AM-11AM', 5, 15000.0, 3000.0),
                                    _buildTimeSlotCard('11AM-2PM', 8, 24000.0, 3000.0),
                                    _buildTimeSlotCard('2PM-5PM', 6, 12000.0, 2000.0),
                                    _buildTimeSlotCard('5PM-8PM', 4, 8000.0, 2000.0),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _buildTimeSlotCard('8AM-11AM', 5, 15000.0, 3000.0)),
                                    Expanded(child: _buildTimeSlotCard('11AM-2PM', 8, 24000.0, 3000.0)),
                                    Expanded(child: _buildTimeSlotCard('2PM-5PM', 6, 12000.0, 2000.0)),
                                    Expanded(child: _buildTimeSlotCard('5PM-8PM', 4, 8000.0, 2000.0)),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ),

                  const SizedBox(height: 16),

                  // Business Insights Card
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
                                Icon(Icons.lightbulb, color: primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'BUSINESS INSIGHTS',
                                  style: TextStyle(
                                    fontSize: Responsive.getTitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: Responsive.getIconSize(context, multiplier: 1.5)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(Color primaryColor, bool isMobile) {
    final displayedData = _dailySalesData.take(isMobile ? 5 : 7).toList();
    
    return ListView.builder(
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
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
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
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> data, bool isMobile) {
    final category = data['category'] as String;
    final sales = data['sales'] as double;
    final color = data['color'] as Color;
    final percentage = (sales / 76000) * 100;
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isMobile) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: EdgeInsets.all(screenWidth < 600 ? 16 : 12),
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
                      fontSize: screenWidth < 600 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₱${sales.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: screenWidth < 600 ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${percentage.toStringAsFixed(1)}% of total sales',
                style: TextStyle(
                  fontSize: screenWidth < 600 ? 13 : 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: screenWidth < 600 ? 10 : 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(screenWidth < 1024 ? 20 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: screenWidth < 1024 ? 70 : 60,
                height: screenWidth < 1024 ? 70 : 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    '${(sales / 1000).toStringAsFixed(0)}K',
                    style: TextStyle(
                      fontSize: screenWidth < 1024 ? 16 : 14,
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
                  fontSize: screenWidth < 1024 ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₱${sales.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: screenWidth < 1024 ? 13 : 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTimeSlotCard(String slot, int transactions, double sales, double average) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot,
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
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '$transactions',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Sales:',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '₱${sales.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Avg: ₱${average.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, size: 20, color: Colors.blue),
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