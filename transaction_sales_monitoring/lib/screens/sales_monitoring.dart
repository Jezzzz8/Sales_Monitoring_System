// ignore_for_file: unused_import

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:transaction_sales_monitoring/utils/settings_mixin.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

class SalesMonitoring extends StatefulWidget {
  const SalesMonitoring({super.key});

  @override
  State<SalesMonitoring> createState() => _SalesMonitoringState();
}

class _SalesMonitoringState extends State<SalesMonitoring> with SettingsMixin {
  // ignore: unused_field
  final DateTime _selectedDate = DateTime.now();
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
      {'category': 'Whole Lechon', 'sales': 45000.0, 'color': Colors.deepOrange, 'percentage': 59.2},
      {'category': 'Lechon Belly', 'sales': 18000.0, 'color': Colors.orange, 'percentage': 23.7},
      {'category': 'Appetizers', 'sales': 8000.0, 'color': Colors.green, 'percentage': 10.5},
      {'category': 'Pork BBQ', 'sales': 3000.0, 'color': Colors.blue, 'percentage': 3.9},
      {'category': 'Others', 'sales': 2000.0, 'color': Colors.purple, 'percentage': 2.7},
    ];
  }

  double get _taxRate {
    return settings?.taxRate ?? 12.0; // Default 12%
  }

  double get _netSales {
    return _sampleTransactions.fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  double get _totalTax {
    return _netSales * (_taxRate / 100);
  }

  double get _totalRevenue {
    return _netSales + _totalTax;
  }

  double get _averageDailySales {
    return _totalRevenue / (_dailySalesData.isNotEmpty ? _dailySalesData.length : 1);
  }

  double get _highestSale {
    return _sampleTransactions.map((t) => t.totalAmount * (1 + _taxRate/100)).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final primaryColor = getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
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
                  // Quick Stats Grid - UPDATED to show tax breakdown
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
                        subtitle: 'Net: ₱${_netSales.toStringAsFixed(2)}\nTax: ₱${_totalTax.toStringAsFixed(2)}',
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        'Avg Daily Sales',
                        '₱${_averageDailySales.toStringAsFixed(2)}',
                        Icons.trending_up,
                        Colors.blue,
                        context,
                        subtitle: 'Incl. $_taxRate% tax',
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        'Highest Sale',
                        '₱${_highestSale.toStringAsFixed(2)}',
                        Icons.arrow_upward,
                        Colors.orange,
                        context,
                        subtitle: 'Incl. $_taxRate% tax',
                        isDarkMode: isDarkMode,
                      ),
                      _buildStatCard(
                        'Transactions',
                        '${_sampleTransactions.length}',
                        Icons.receipt,
                        Colors.purple,
                        context,
                        subtitle: 'Avg: ₱${(_totalRevenue/_sampleTransactions.length).toStringAsFixed(2)}',
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filters Card with theme - MOVED TO TOP
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
                                        initialValue: _selectedView,
                                        dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: 'Time Period',
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
                                          prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                                        ),
                                        items: ['Daily', 'Weekly', 'Monthly']
                                            .map((view) => DropdownMenuItem(
                                                  value: view,
                                                  child: Text(view, style: TextStyle(color: textColor)),
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
                                        dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: 'Category',
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
                                          prefixIcon: Icon(Icons.category, color: primaryColor),
                                        ),
                                        items: ['All', 'Whole Lechon', 'Lechon Belly', 'Appetizers']
                                            .map((category) => DropdownMenuItem(
                                                  value: category,
                                                  child: Text(category, style: TextStyle(color: textColor)),
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
                                          initialValue: _selectedView,
                                          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: 'Time Period',
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
                                            prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                                          ),
                                          items: ['Daily', 'Weekly', 'Monthly']
                                              .map((view) => DropdownMenuItem(
                                                    value: view,
                                                    child: Text(view, style: TextStyle(color: textColor)),
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
                                          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: 'Category Filter',
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
                                            prefixIcon: Icon(Icons.category, color: primaryColor),
                                          ),
                                          items: ['All', 'Whole Lechon', 'Lechon Belly', 'Appetizers']
                                              .map((category) => DropdownMenuItem(
                                                    value: category,
                                                    child: Text(category, style: TextStyle(color: textColor)),
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

                  // Sales Trend Chart and Category Performance in Desktop/Tablet Mode - MOVED TO TOP
                  if (!isMobile)
                    Container(
                      constraints: const BoxConstraints(
                        minHeight: 350,
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
                              // Combined Title for Desktop/Tablet
                              Text(
                                'SALES ANALYSIS',
                                style: TextStyle(
                                  fontSize: Responsive.getTitleFontSize(context),
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Side by side layout for desktop/tablet
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Sales Trend Chart
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SALES TREND',
                                              style: TextStyle(
                                                fontSize: Responsive.getSubtitleFontSize(context),
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              height: 250,
                                              child: _buildSalesChart(primaryColor, false, isDarkMode: isDarkMode),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16), // Reduced spacing
                                      
                                      // Pie Chart for Category Performance
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'CATEGORY DISTRIBUTION',
                                              style: TextStyle(
                                                fontSize: Responsive.getSubtitleFontSize(context),
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              height: 250,
                                              child: _buildResponsivePieChart(availableWidth * 0.4, isDarkMode: isDarkMode),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Mobile layout - Sales Trend only (Category Performance will be below)
                  if (isMobile)
                    Column(
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 300,
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SALES TREND',
                                    style: TextStyle(
                                      fontSize: Responsive.getTitleFontSize(context),
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: isMobile ? 250 : 300,
                                    child: Center(
                                      child: _buildSalesChart(primaryColor, isMobile, isDarkMode: isDarkMode),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Performance - Pie Chart for Mobile (placed below Sales Trend)
                        Container(
                          constraints: const BoxConstraints(
                            minHeight: 350,
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'CATEGORY DISTRIBUTION',
                                    style: TextStyle(
                                      fontSize: Responsive.getTitleFontSize(context),
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: SizedBox(
                                      height: 250,
                                      width: 250,
                                      child: _buildResponsivePieChart(250, isDarkMode: isDarkMode),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._categorySalesData.map((data) => 
                                    Center(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: screenWidth * 0.8,
                                        ),
                                        child: _buildCategoryLegendItem(data, isDarkMode: isDarkMode),
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

                  const SizedBox(height: 16),

                  // ENHANCED: Tax Breakdown Card with theme and responsive design - NOW SMALLER FOR DESKTOP
                  _buildTaxBreakdownCard(
                    primaryColor,
                    isMobile,
                    isTablet,
                    isDesktop,
                    isDarkMode,
                    cardColor,
                    textColor,
                    mutedTextColor,
                    context,
                  ),

                  const SizedBox(height: 16),

                  // Peak Hours Card with theme
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 220,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.getCardPadding(context).horizontal,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                    Icons.access_time,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'PEAK HOURS ANALYSIS',
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
                            const SizedBox(height: 16),
                            if (isMobile)
                              Column(
                                children: [
                                  _buildEnhancedTimeSlotCard('8AM-11AM', 5, 15000.0, 3000.0, 1, context, 
                                    isDarkMode: isDarkMode,
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedTextColor: mutedTextColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildEnhancedTimeSlotCard('11AM-2PM', 8, 24000.0, 3000.0, 2, context, 
                                    isDarkMode: isDarkMode,
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedTextColor: mutedTextColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildEnhancedTimeSlotCard('2PM-5PM', 6, 12000.0, 2000.0, 3, context, 
                                    isDarkMode: isDarkMode,
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedTextColor: mutedTextColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildEnhancedTimeSlotCard('5PM-8PM', 4, 8000.0, 2000.0, 4, context, 
                                    isDarkMode: isDarkMode,
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedTextColor: mutedTextColor,
                                  ),
                                ],
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final cardWidth = (availableWidth - 48) / 4;
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          width: cardWidth,
                                          child: _buildEnhancedTimeSlotCard('8AM-11AM', 5, 15000.0, 3000.0, 1, context, 
                                            isDarkMode: isDarkMode,
                                            primaryColor: primaryColor,
                                            cardColor: cardColor,
                                            textColor: textColor,
                                            mutedTextColor: mutedTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: SizedBox(
                                          width: cardWidth,
                                          child: _buildEnhancedTimeSlotCard('11AM-2PM', 8, 24000.0, 3000.0, 2, context, 
                                            isDarkMode: isDarkMode,
                                            primaryColor: primaryColor,
                                            cardColor: cardColor,
                                            textColor: textColor,
                                            mutedTextColor: mutedTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: SizedBox(
                                          width: cardWidth,
                                          child: _buildEnhancedTimeSlotCard('2PM-5PM', 6, 12000.0, 2000.0, 3, context, 
                                            isDarkMode: isDarkMode,
                                            primaryColor: primaryColor,
                                            cardColor: cardColor,
                                            textColor: textColor,
                                            mutedTextColor: mutedTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: SizedBox(
                                          width: cardWidth,
                                          child: _buildEnhancedTimeSlotCard('5PM-8PM', 4, 8000.0, 2000.0, 4, context, 
                                            isDarkMode: isDarkMode,
                                            primaryColor: primaryColor,
                                            cardColor: cardColor,
                                            textColor: textColor,
                                            mutedTextColor: mutedTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Business Insights Card with theme
                  Container(
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.lightbulb, 
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'BUSINESS INSIGHTS',
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
                            _buildInsightItem(
                              'Peak sales occur between 11AM-2PM',
                              'Consider preparing more inventory during these hours',
                              context,
                              isDarkMode: isDarkMode,
                              primaryColor: primaryColor,
                              textColor: textColor,
                              mutedTextColor: mutedTextColor,
                            ),
                            _buildInsightItem(
                              'Whole Lechon accounts for 60% of revenue',
                              'Focus on promoting this high-margin product',
                              context,
                              isDarkMode: isDarkMode,
                              primaryColor: primaryColor,
                              textColor: textColor,
                              mutedTextColor: mutedTextColor,
                            ),
                            _buildInsightItem(
                              'Average transaction value: ₱3,000',
                              'Create bundles to increase average sale',
                              context,
                              isDarkMode: isDarkMode,
                              primaryColor: primaryColor,
                              textColor: textColor,
                              mutedTextColor: mutedTextColor,
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

  // ENHANCED: Tax Breakdown Card with consistent theme - UPDATED FOR SMALLER DESKTOP CARDS
  Widget _buildTaxBreakdownCard(
    Color primaryColor,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
    BuildContext context,
  ) {
    return Card(
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
        padding: EdgeInsets.all(isDesktop ? 16 : Responsive.getCardPadding(context).horizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with consistent styling
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TAX BREAKDOWN',
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
            
            // Tax calculation formula for desktop/tablet
            if (!isMobile)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate,
                      color: primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Formula: Net Sales × $_taxRate% = Tax Amount',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Tax breakdown rows - Responsive layout with consistent theme
            if (isMobile)
              Column(
                children: [
                  _buildEnhancedTaxRow(
                    'Net Sales',
                    _netSales,
                    primaryColor,
                    Icons.money_off,
                    isDarkMode,
                    isMobile,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                  ),
                  _buildDivider(isDarkMode),
                  _buildEnhancedTaxRow(
                    'Tax Rate',
                    _taxRate,
                    primaryColor,
                    Icons.percent,
                    isDarkMode,
                    isMobile,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isPercent: true,
                  ),
                  _buildDivider(isDarkMode),
                  _buildEnhancedTaxRow(
                    'Tax Amount',
                    _totalTax,
                    primaryColor,
                    Icons.request_quote,
                    isDarkMode,
                    isMobile,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                  ),
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          primaryColor.withOpacity(isDarkMode ? 0.5 : 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  _buildEnhancedTaxRow(
                    'Total Revenue',
                    _totalRevenue,
                    primaryColor,
                    Icons.attach_money,
                    isDarkMode,
                    isMobile,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isTotal: true,
                  ),
                ],
              )
            else if (isTablet)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _buildDesktopTaxCard(
                    'Net Sales',
                    _netSales,
                    'Before tax',
                    primaryColor,
                    Icons.money_off,
                    isDarkMode,
                    context,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isDesktop: isDesktop,
                  ),
                  _buildDesktopTaxCard(
                    'Tax Rate',
                    _taxRate,
                    'Applied rate',
                    primaryColor,
                    Icons.percent,
                    isDarkMode,
                    context,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isPercent: true,
                    isDesktop: isDesktop,
                  ),
                  _buildDesktopTaxCard(
                    'Tax Amount',
                    _totalTax,
                    'Calculated tax',
                    primaryColor,
                    Icons.request_quote,
                    isDarkMode,
                    context,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isDesktop: isDesktop,
                  ),
                  _buildDesktopTaxCard(
                    'Total Revenue',
                    _totalRevenue,
                    'Net + Tax',
                    primaryColor,
                    Icons.attach_money,
                    isDarkMode,
                    context,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    isTotal: true,
                    isDesktop: isDesktop,
                  ),
                ],
              )
            else
              // DESKTOP LAYOUT - 4 cards in a row with smaller size
              Row(
                children: [
                  Expanded(
                    child: _buildDesktopTaxCard(
                      'Net Sales',
                      _netSales,
                      'Before tax',
                      primaryColor,
                      Icons.money_off,
                      isDarkMode,
                      context,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                      isDesktop: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDesktopTaxCard(
                      'Tax Rate',
                      _taxRate,
                      'Applied rate',
                      primaryColor,
                      Icons.percent,
                      isDarkMode,
                      context,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                      isPercent: true,
                      isDesktop: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDesktopTaxCard(
                      'Tax Amount',
                      _totalTax,
                      'Calculated tax',
                      primaryColor,
                      Icons.request_quote,
                      isDarkMode,
                      context,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                      isDesktop: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDesktopTaxCard(
                      'Total Revenue',
                      _totalRevenue,
                      'Net + Tax',
                      primaryColor,
                      Icons.attach_money,
                      isDarkMode,
                      context,
                      textColor: textColor,
                      mutedTextColor: mutedTextColor,
                      isTotal: true,
                      isDesktop: true,
                    ),
                  ),
                ],
              ),
            
            // Percentage breakdown for desktop/tablet
            if (!isMobile)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Sales:',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(100 - (_totalTax / _totalRevenue * 100)).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tax:',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_totalTax / _totalRevenue * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method for mobile tax rows
  Widget _buildEnhancedTaxRow(
    String label,
    double value,
    Color primaryColor,
    IconData icon,
    bool isDarkMode,
    bool isMobile, {
    bool isPercent = false,
    bool isTotal = false,
    Color? textColor,
    Color? mutedTextColor,
  }) {
    final rowColor = isTotal ? primaryColor : (isPercent ? Colors.orange : Colors.blue);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: isMobile ? 18 : 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: mutedTextColor ?? Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPercent ? '${value.toStringAsFixed(1)}%' : '₱${value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTotal ? (isMobile ? 16 : 18) : (isMobile ? 14 : 16),
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (isTotal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                'FINAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper method for desktop tax cards - UPDATED TO BE SMALLER FOR DESKTOP
  Widget _buildDesktopTaxCard(
    String label,
    double value,
    String description,
    Color primaryColor,
    IconData icon,
    bool isDarkMode,
    BuildContext context, {
    bool isPercent = false,
    bool isTotal = false,
    bool isDesktop = false,
    Color? textColor,
    Color? mutedTextColor,
  }) {
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    
    // Smaller padding for desktop
    final padding = isDesktop ? const EdgeInsets.all(10) : const EdgeInsets.all(12);
    final iconSize = isDesktop ? 20.0 : 24.0;
    final titleSize = isDesktop ? 
      Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13) :
      Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14);
    final valueSize = isDesktop ? 
      Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16) :
      Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18);
    final descSize = isDesktop ? 
      Responsive.getFontSize(context, mobile: 9, tablet: 10, desktop: 11) :
      Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTotal ? primaryColor.withOpacity(0.5) : borderColor,
          width: isTotal ? 2 : 1,
        ),
        boxShadow: isTotal
            ? [
                BoxShadow(
                  color: primaryColor.withOpacity(isDarkMode ? 0.3 : 0.1),
                  blurRadius: isDesktop ? 6 : 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
                  blurRadius: isDesktop ? 3 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 6 : 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: iconSize,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: titleSize,
                color: mutedTextColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isPercent ? '${value.toStringAsFixed(1)}%' : '₱${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w700,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: descSize,
                color: mutedTextColor ?? Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, 
      {String? subtitle, bool isDarkMode = false}) {
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 8, tablet: 9, desktop: 10) * 0.9,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesChart(Color primaryColor, bool isMobile, {bool isDarkMode = false}) {
    final displayedData = _dailySalesData.take(isMobile ? 5 : 7).toList();
    final double chartWidth = (isMobile ? 48 : 56) * displayedData.length + 
                      (isMobile ? 6 : 8) * 2 * (displayedData.length - 1);
    
    return SizedBox(
      width: chartWidth,
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
            width: isMobile ? 48 : 56,
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode ? primaryColor.withOpacity(0.2) : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '₱${(sales / 1000).toStringAsFixed(0)}K',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 9, tablet: 10, desktop: 11) * 0.9,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: (sales / maxSales) * (isMobile ? 140 : 180),
                  width: isMobile ? 28 : 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isDarkMode
                          ? [
                              primaryColor.withOpacity(0.8),
                              primaryColor.withOpacity(0.5),
                            ]
                          : [
                              primaryColor.withOpacity(0.9),
                              primaryColor.withOpacity(0.6),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(isDarkMode ? 0.4 : 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (sales / 1000).toStringAsFixed(0),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: Responsive.getFontSize(context, mobile: 8, tablet: 9, desktop: 10) * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 9, tablet: 10, desktop: 11) * 0.9,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsivePieChart(double availableWidth, {bool isDarkMode = false}) {
    final totalSales = _categorySalesData.fold<double>(0, (sum, data) => sum + (data['sales'] as double));
    final chartSize = availableWidth.clamp(150.0, 250.0);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        
        if (isMobile) {
          return Column(
            children: [
              SizedBox(
                height: chartSize,
                width: chartSize,
                child: CustomPaint(
                  painter: _PieChartPainter(_categorySalesData, chartSize, isDarkMode: isDarkMode),
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: chartSize,
                  child: CustomPaint(
                    painter: _PieChartPainter(_categorySalesData, chartSize, isDarkMode: isDarkMode),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _categorySalesData.map((data) => _buildCategoryLegendItem(data, isDarkMode: isDarkMode)).toList(),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildCategoryLegendItem(Map<String, dynamic> data, {bool isDarkMode = false}) {
    final category = data['category'] as String;
    final sales = data['sales'] as double;
    final color = data['color'] as Color;
    final percentage = data['percentage'] as double;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${sales.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTimeSlotCard(String slot, int transactions, double sales, double average, int index, BuildContext context, {
    bool isDarkMode = false,
    Color? primaryColor,
    Color? cardColor,
    Color? textColor,
    Color? mutedTextColor,
  }) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    final slotColor = colors[(index - 1) % colors.length];
    
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.grey.shade800 
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode 
              ? Colors.grey.shade700 
              : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Time Slot with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor?.withOpacity(0.1) ?? slotColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: primaryColor ?? slotColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: primaryColor ?? slotColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Performance indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor?.withOpacity(0.05) ?? slotColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 12,
                              color: primaryColor ?? slotColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Transactions:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mutedTextColor ?? Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$transactions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primaryColor ?? slotColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.attach_money,
                              size: 12,
                              color: primaryColor ?? slotColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Sales:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mutedTextColor ?? Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₱${(sales / 1000).toStringAsFixed(0)}K',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primaryColor ?? slotColor,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Average with trend indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    index == 2 ? Icons.trending_up : 
                    index >= 3 ? Icons.trending_down : Icons.trending_flat,
                    size: 14,
                    color: index == 2 ? Colors.green : 
                          index >= 3 ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Avg: ₱${average.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: mutedTextColor ?? Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, BuildContext context, {
    bool isDarkMode = false,
    Color? primaryColor,
    Color? textColor,
    Color? mutedTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_right, 
              size: 16, 
              color: primaryColor ?? Colors.blue
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor?.withOpacity(0.05) ?? Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16) * 0.9,
                      fontWeight: FontWeight.bold,
                      color: primaryColor ?? Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14) * 0.9,
                    color: mutedTextColor ?? Colors.grey.shade600,
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

class _PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double size;
  final bool isDarkMode;
  
  _PieChartPainter(this.data, this.size, {this.isDarkMode = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.8;
    final total = data.fold<double>(0, (sum, item) => sum + (item['sales'] as double));
    
    double startAngle = -90 * (math.pi / 180);
    
    for (var i = 0; i < data.length; i++) {
      final item = data[i];
      final value = item['sales'] as double;
      final sweepAngle = (value / total) * 2 * math.pi;
      final color = item['color'] as Color;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      final separatorPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        ),
        separatorPaint,
      );
      
      startAngle += sweepAngle;
    }
    
    final centerPaint = Paint()
      ..color = isDarkMode ? Colors.grey.shade800 : Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.5, centerPaint);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₱${(total / 1000).toStringAsFixed(0)}K',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}