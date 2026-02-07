// lib/screens/sales_monitoring.dart - UPDATED FL_CHART 1.1.1 VERSION
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/settings_mixin.dart';
import '../models/transaction.dart';
import '../models/category_model.dart';
import '../models/product.dart';
import '../utils/responsive.dart';
import '../services/sales_service.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';

class SalesMonitoring extends StatefulWidget {
  const SalesMonitoring({super.key});

  @override
  State<SalesMonitoring> createState() => _SalesMonitoringState();
}

class _SalesMonitoringState extends State<SalesMonitoring> with SettingsMixin {
  Map<String, dynamic> _analyticsData = {};
  DateTime _selectedDate = DateTime.now();
  String _selectedView = 'Daily';
  String _selectedCategory = 'All';
  
  // Loading states
  bool _isLoadingAnalytics = true;
  bool _isLoadingCategories = true;
  bool _isInitialLoad = true;
  
  // Analytics data - with caching
  Map<String, dynamic> _cachedAnalytics = {};
  List<ProductCategory> _productCategories = [];
  List<Map<String, dynamic>> _categorySalesData = [];
  List<Map<String, dynamic>> _dailySalesData = [];
  List<Map<String, dynamic>> _hourlyData = [];
  
  // Performance optimization flags
  bool _shouldReloadAnalytics = true;
  String _lastSelectedView = 'Daily';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    // Initial data load with delay to show skeleton
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
        _loadAnalytics();
      }
    });
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      _productCategories = await CategoryService.getProductCategories();
      print('Loaded ${_productCategories.length} product categories');
    } catch (e) {
      print('Error loading categories: $e');
      _productCategories = [];
    }
    setState(() => _isLoadingCategories = false);
  }

  Future<void> _loadAnalytics() async {
    if (!_shouldReloadAnalytics && _lastSelectedView == _selectedView) {
      return;
    }

    setState(() => _isLoadingAnalytics = true);
    
    try {
      final now = DateTime.now();
      
      // Use cached data if available and same day
      final cacheKey = '${_selectedView}_${now.day}';
      
      Map<String, dynamic> analyticsData;
      
      if (_cachedAnalytics.containsKey(cacheKey) && !_shouldReloadAnalytics) {
        analyticsData = Map<String, dynamic>.from(_cachedAnalytics[cacheKey]!);
      } else {
        // Fetch fresh data
        switch (_selectedView) {
          case 'Daily':
            analyticsData = await SalesService.getTodayAnalytics();
            break;
          case 'Weekly':
            analyticsData = await _getWeeklyAnalyticsOptimized();
            break;
          case 'Monthly':
            analyticsData = await _getMonthlyAnalyticsOptimized();
            break;
          default:
            analyticsData = await SalesService.getTodayAnalytics();
        }
        
        // Ensure all nested structures are properly typed
        analyticsData = _sanitizeAnalyticsData(analyticsData);
        
        // Cache the data
        _cachedAnalytics[cacheKey] = analyticsData;
      }

      // Update state with analytics data
      setState(() {
        _analyticsData = analyticsData;
        
        // Process data using the analyticsData
        _processCategorySalesData();
        _processDailySalesData();
        _processHourlyData();

        print('Category Sales Data processed:');
        for (final category in _categorySalesData) {
          print('  - ${category['category']}: ₱${category['sales']} (${category['percentage']}%)');
        }
      });

      print('Analytics loaded: Total sales: ${_totalSales.toStringAsFixed(2)}');
      print('Categories found: ${_categorySalesData.length}');
      
      // Reset flags
      _shouldReloadAnalytics = false;
      _lastSelectedView = _selectedView;
      
    } catch (e, stackTrace) {
      print('Error loading analytics: $e');
      print('Stack trace: $stackTrace');
      
      // Create safe empty data
      final emptyAnalytics = {
        'totalSales': 0.0,
        'totalTransactions': 0,
        'averageSale': 0.0,
        'topCategories': <Map<String, dynamic>>[],
        'categorySales': <String, double>{},
        'dailyData': <Map<String, dynamic>>[],
        'hourlyData': <Map<String, dynamic>>[],
      };
      
      setState(() {
        _analyticsData = emptyAnalytics;
        _categorySalesData = [];
        _dailySalesData = [];
        _hourlyData = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingAnalytics = false);
      }
    }
  }

  // Helper method to sanitize analytics data
  Map<String, dynamic> _sanitizeAnalyticsData(Map<String, dynamic> data) {
    // Convert all nested lists to proper types
    final result = Map<String, dynamic>.from(data);
    
    // Sanitize topCategories
    if (result['topCategories'] is List) {
      result['topCategories'] = (result['topCategories'] as List).map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item);
        } else if (item is Map) {
          return Map<String, dynamic>.from(item.cast<String, dynamic>());
        }
        return <String, dynamic>{};
      }).toList();
    } else {
      result['topCategories'] = <Map<String, dynamic>>[];
    }
    
    // Sanitize categorySales
    if (result['categorySales'] is Map) {
      final categorySales = result['categorySales'] as Map;
      result['categorySales'] = Map<String, double>.from(
        categorySales.map((key, value) => MapEntry(
          key.toString(),
          (value is num ? value.toDouble() : 0.0),
        )),
      );
    } else {
      result['categorySales'] = <String, double>{};
    }
    
    // Sanitize dailyData
    if (result['dailyData'] is List) {
      result['dailyData'] = (result['dailyData'] as List).map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item);
        } else if (item is Map) {
          return Map<String, dynamic>.from(item.cast<String, dynamic>());
        }
        return <String, dynamic>{};
      }).toList();
    } else {
      result['dailyData'] = <Map<String, dynamic>>[];
    }
    
    // Sanitize hourlyData
    if (result['hourlyData'] is List) {
      result['hourlyData'] = (result['hourlyData'] as List).map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item);
        } else if (item is Map) {
          return Map<String, dynamic>.from(item.cast<String, dynamic>());
        }
        return <String, dynamic>{};
      }).toList();
    } else {
      result['hourlyData'] = <Map<String, dynamic>>[];
    }
    
    // Ensure numeric values
    result['totalSales'] = (result['totalSales'] is num ? (result['totalSales'] as num).toDouble() : 0.0);
    result['totalTransactions'] = (result['totalTransactions'] is num ? (result['totalTransactions'] as num).toInt() : 0);
    result['averageSale'] = (result['averageSale'] is num ? (result['averageSale'] as num).toDouble() : 0.0);
    
    return result;
  }

  // Optimized weekly analytics with summary data
  Future<Map<String, dynamic>> _getWeeklyAnalyticsOptimized() async {
    try {
      // Get summary first for quick display
      final summary = await TransactionService.getWeeklySummary();
      
      // Return sanitized summary immediately
      return _sanitizeAnalyticsData({
        'totalSales': summary['totalSales'] ?? 0.0,
        'totalTransactions': summary['totalTransactions'] ?? 0,
        'averageSale': summary['averageSale'] ?? 0.0,
        'topCategories': summary['topCategories'] ?? [],
        'categorySales': summary['categorySales'] ?? {},
        'dailyData': summary['dailyData'] ?? [],
        'hourlyData': summary['hourlyData'] ?? [],
      });
    } catch (e) {
      print('Error in optimized weekly analytics: $e');
      final analytics = await SalesService.getWeeklyAnalytics();
      return _sanitizeAnalyticsData(analytics);
    }
  }

  // Optimized monthly analytics
  Future<Map<String, dynamic>> _getMonthlyAnalyticsOptimized() async {
    try {
      // Get summary for quick display
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      // Fetch with limit for performance
      final analytics = await SalesService.getSalesAnalyticsWithLimit(
        startOfMonth,
        endOfMonth,
        limit: 100, // Limit transactions for performance
      );
      
      return _sanitizeAnalyticsData(analytics);
    } catch (e) {
      print('Error in optimized monthly analytics: $e');
      final analytics = await SalesService.getMonthlyAnalytics();
      return _sanitizeAnalyticsData(analytics);
    }
  }

  void _processCategorySalesData() {
    final rawCategories = _analyticsData['topCategories'] as List<dynamic>? ?? [];
    final categorySales = _analyticsData['categorySales'] as Map<String, dynamic>? ?? {};
    
    print('Raw category sales data: $categorySales');
    print('Product categories count: ${_productCategories.length}');
    
    // Create a list to hold all categories with sales
    final List<Map<String, dynamic>> allCategoriesWithSales = [];
    
    // First, add categories that have sales data from analytics
    for (final entry in categorySales.entries) {
      final categoryName = entry.key;
      final sales = (entry.value is num ? (entry.value as num).toDouble() : 0.0);
      
      if (sales > 0) {
        // Find the category in our product categories to get color and icon
        ProductCategory? matchingCategory;
        for (final cat in _productCategories) {
          if (cat.name.toLowerCase() == categoryName.toLowerCase()) {
            matchingCategory = cat;
            break;
          }
        }
        
        // Parse color from hex string
        Color color;
        try {
          if (matchingCategory != null && matchingCategory.color.isNotEmpty) {
            final hexColor = matchingCategory.color.replaceFirst('#', '');
            if (hexColor.length == 6) {
              color = Color(int.parse('0xFF$hexColor'));
            } else {
              color = _generateColorFromCategory(categoryName);
            }
          } else {
            color = _generateColorFromCategory(categoryName);
          }
        } catch (e) {
          color = _generateColorFromCategory(categoryName);
        }
        
        final totalSales = _totalSales;
        final percentage = totalSales > 0 ? (sales / totalSales * 100) : 0;
        
        allCategoriesWithSales.add({
          'category': categoryName,
          'sales': sales,
          'color': color,
          'percentage': percentage,
          'icon': matchingCategory?.icon ?? 'fas fa-box',
          'categoryId': matchingCategory?.id ?? '',
        });
      }
    }
    
    // If no categories from analytics, use product categories
    if (allCategoriesWithSales.isEmpty && _productCategories.isNotEmpty) {
      // Sort product categories by name to show them consistently
      final sortedCategories = List<ProductCategory>.from(_productCategories)
        ..sort((a, b) => a.name.compareTo(b.name));
      
      for (final category in sortedCategories) {
        Color color;
        try {
          final hexColor = category.color.replaceFirst('#', '');
          color = Color(int.parse('0xFF$hexColor'));
        } catch (e) {
          color = Colors.blue;
        }
        
        allCategoriesWithSales.add({
          'category': category.name,
          'sales': 0.0,
          'color': color,
          'percentage': 0.0,
          'icon': category.icon,
          'categoryId': category.id,
        });
      }
    }
    
    // Sort by sales (descending)
    allCategoriesWithSales.sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));
    
    // Limit to top categories and combine the rest as "Others"
    if (allCategoriesWithSales.length > 5) {
      final topCategories = allCategoriesWithSales.take(5).toList();
      final otherCategories = allCategoriesWithSales.sublist(5);
      
      double otherSales = 0.0;
      for (final cat in otherCategories) {
        otherSales += (cat['sales'] as double);
      }
      
      final otherPercentage = _totalSales > 0 ? (otherSales / _totalSales * 100) : 0;
      
      _categorySalesData = [
        ...topCategories,
        if (otherSales > 0)
          {
            'category': 'Others',
            'sales': otherSales,
            'color': Colors.grey,
            'percentage': otherPercentage,
            'icon': 'more_horiz',
            'categoryId': 'others',
          }
      ];
    } else {
      _categorySalesData = allCategoriesWithSales;
    }
    
    print('Processed ${_categorySalesData.length} categories for display');
  }

  void _processDailySalesData() {
    final rawDailyData = _analyticsData['dailyData'] as List<dynamic>? ?? [];

    
    _dailySalesData = rawDailyData.map((data) {
      final date = data['date'] as DateTime;
      final sales = data['sales'] as double;
      
      return {
        'date': date,
        'sales': sales,
        'label': '${date.day}/${date.month}',
        'formattedDate': '${_getDayName(date.weekday)} ${date.day}',
      };
    }).toList();
    
    // Sort by date
    _dailySalesData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  void _processHourlyData() {
    final rawHourlyData = _analyticsData['hourlyData'] as List<dynamic>? ?? [];
    
    _hourlyData = rawHourlyData.map((data) {
      final hour = data['hour'] as String;
      final sales = data['sales'] as double;
      
      return {
        'hour': hour,
        'sales': sales,
        'label': hour.replaceAll(':00', ''),
      };
    }).toList();
    
    // If no hourly data, create sample data for peak hours chart
    if (_hourlyData.isEmpty || _hourlyData.every((h) => (h['sales'] as double) == 0)) {
      _hourlyData = List.generate(12, (index) {
        final hour = index + 8; // 8AM to 8PM
        final sales = _getSampleHourlySales(hour);
        return {
          'hour': '$hour:00',
          'sales': sales,
          'label': hour <= 12 ? '${hour}AM' : '${hour - 12}PM',
        };
      });
    }
  }

  double _getSampleHourlySales(int hour) {
    final random = math.Random();
    
    // Peak at 11AM-2PM
    if (hour >= 11 && hour <= 14) {
      return 8000 + random.nextDouble() * 4000;
    } else if (hour >= 8 && hour <= 10) {
      return 3000 + random.nextDouble() * 2000;
    } else if (hour >= 15 && hour <= 17) {
      return 2000 + random.nextDouble() * 1500;
    } else {
      return 500 + random.nextDouble() * 1000;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Day';
    }
  }

  double get _totalSales {
    return (_analyticsData['totalSales'] as double?) ?? 0.0;
  }

  int get _totalTransactions {
    return (_analyticsData['totalTransactions'] as int?) ?? 0;
  }

  double get _averageSale {
    return (_analyticsData['averageSale'] as double?) ?? 0.0;
  }

  double get _taxRate {
    return settings?.taxRate ?? 12.0;
  }

  double get _netSales {
    return _totalSales;
  }

  double get _totalTax {
    return _netSales * (_taxRate / 100);
  }

  double get _totalRevenue {
    return _netSales + _totalTax;
  }

  double get _averageDailySales {
    if (_dailySalesData.isEmpty) return 0.0;
    final totalDays = _dailySalesData.length;
    return _totalRevenue / totalDays;
  }

  double get _highestSale {
    if (_dailySalesData.isEmpty) return 0.0;
    
    double maxSales = 0.0;
    for (final d in _dailySalesData) {
      final sales = d['sales'];
      double currentSales = 0.0;
      
      if (sales is double) {
        currentSales = sales;
      } else if (sales is num) {
        currentSales = sales.toDouble();
      } else if (sales is int) {
        currentSales = sales.toDouble();
      }
      
      if (currentSales > maxSales) {
        maxSales = currentSales;
      }
    }
    
    return maxSales * (1 + _taxRate / 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return _buildSkeletonScreen(context);
    }
    
    final primaryColor = getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors
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
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Grid
                  if (_isLoadingAnalytics)
                    _buildSkeletonStatsGrid(context, isMobile, isDarkMode, cardColor)
                  else
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
                          'Total Transactions',
                          '$_totalTransactions',
                          Icons.receipt,
                          Colors.orange,
                          context,
                          subtitle: 'Avg: ₱${_averageSale.toStringAsFixed(2)}',
                          isDarkMode: isDarkMode,
                        ),
                        _buildStatCard(
                          'Top Category',
                          _categorySalesData.isNotEmpty 
                              ? _categorySalesData.first['category'].toString().split(' ').first
                              : 'N/A',
                          Icons.category,
                          Colors.purple,
                          context,
                          subtitle: _categorySalesData.isNotEmpty
                              ? '${_categorySalesData.first['percentage'].toStringAsFixed(1)}% of sales'
                              : 'No data',
                          isDarkMode: isDarkMode,
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Filters Card
                  _buildFiltersCard(
                    primaryColor,
                    isMobile,
                    isDarkMode,
                    cardColor,
                    textColor,
                    mutedTextColor,
                    context,
                  ),

                  const SizedBox(height: 16),

                  // Sales Analysis Charts
                  if (_isLoadingAnalytics)
                    _buildSkeletonCharts(context, isMobile, isDarkMode, cardColor)
                  else if (!isMobile)
                    _buildDesktopCharts(primaryColor, isDarkMode, cardColor, textColor, context)
                  else
                    _buildMobileCharts(primaryColor, isMobile, isDarkMode, cardColor, textColor, context),

                  const SizedBox(height: 16),

                  // Peak Hours Line Graph
                  if (_isLoadingAnalytics)
                    _buildSkeletonPeakHoursGraph(context, isMobile, isDarkMode, cardColor)
                  else
                    _buildPeakHoursLineGraph(
                      primaryColor,
                      isMobile,
                      isDarkMode,
                      cardColor,
                      textColor,
                      mutedTextColor,
                      context,
                    ),

                  const SizedBox(height: 16),

                  // Tax Breakdown
                  if (_isLoadingAnalytics)
                    _buildSkeletonTaxBreakdown(context, isMobile, isTablet, isDesktop, isDarkMode, cardColor)
                  else
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

                  // Business Insights
                  if (_isLoadingAnalytics)
                    _buildSkeletonBusinessInsights(context, isDarkMode, cardColor)
                  else
                    _buildBusinessInsights(
                      primaryColor,
                      isDarkMode,
                      cardColor,
                      textColor,
                      mutedTextColor,
                      context,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onViewChanged(String value) {
    setState(() {
      _selectedView = value;
      _isLoadingAnalytics = true;
    });
    _loadAnalytics();
  }

  void _onCategoryChanged(String value) {
    setState(() {
      _selectedCategory = value;
    });
  }

  // ========== FL_CHART Chart Components ==========

  Widget _buildDesktopCharts(Color primaryColor, bool isDarkMode, Color cardColor, Color textColor, BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 400,
        maxHeight: Responsive.isDesktop(context) ? 450 : 400,
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
                  Icon(Icons.analytics, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'SALES ANALYSIS',
                    style: TextStyle(
                      fontSize: Responsive.getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 300,
                  maxHeight: Responsive.isDesktop(context) ? 350 : 300,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bar Chart
                    Expanded(
                      flex: 2,
                      child: _buildBarChart(primaryColor, isDarkMode, textColor, context),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Pie Chart
                    Expanded(
                      flex: 2,
                      child: _buildPieChart(primaryColor, isDarkMode, textColor, context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(Color primaryColor, bool isDarkMode, Color textColor, BuildContext context) {
    final displayedData = _dailySalesData.take(7).toList();
    
    if (displayedData.isEmpty) {
      return _buildEmptyChart('SALES TREND', 'No sales data available', Icons.bar_chart, primaryColor, isDarkMode, textColor);
    }
    
    // Calculate max sales for scaling
    double maxSales = 0.0;
    for (final d in displayedData) {
      final sales = d['sales'] as double;
      if (sales > maxSales) maxSales = sales;
    }
    if (maxSales == 0) maxSales = 1;
    
    // Prepare bar chart data
    final barGroups = displayedData.asMap().entries.map((entry) {
      final index = entry.key;
      final sales = entry.value['sales'] as double;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: sales,
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.8),
                primaryColor.withOpacity(0.4),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
    
    // Side titles for X-axis
    Widget getBottomTitles(double value, TitleMeta meta) {
      if (value.toInt() >= displayedData.length) return Container();
      
      final data = displayedData[value.toInt()];
      final label = data['label'] as String;
      
      return SideTitleWidget(
        fitInside : SideTitleFitInsideData.disable(), 
        space: 4, // Space between chart and text
        meta: meta,
        child: Text(
          label, // Replace with your logic to get the label
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
    }
    
    // Side titles for Y-axis
    Widget getLeftTitles(double value, TitleMeta meta) {
      final formattedValue = (value / 1000).toStringAsFixed(0);
      return SideTitleWidget(
        fitInside : SideTitleFitInsideData.disable(), 
        space: 4, // Space between chart and text
        meta: meta,
        child: Text(
          '₱${formattedValue}K',
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'SALES TREND',
              style: TextStyle(
                fontSize: Responsive.getSubtitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedView,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSales * 1.1, // Add 10% padding
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => isDarkMode ? Colors.grey.shade800 : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final sales = rod.toY;
                      final data = displayedData[group.x.toInt()];
                      final label = data['formattedDate'] as String;
                      return BarTooltipItem(
                        '$label\n₱${sales.toStringAsFixed(2)}',
                        TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getLeftTitles,
                      reservedSize: 40,
                      interval: maxSales / 4,
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: getBottomTitles,
                      reservedSize: 30,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxSales / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(Color primaryColor, bool isDarkMode, Color textColor, BuildContext context) {
    if (_categorySalesData.isEmpty) {
      return _buildEmptyChart('CATEGORY DISTRIBUTION', 'No category sales data', Icons.pie_chart, primaryColor, isDarkMode, textColor);
    }
    
    // Check if we have any sales data
    final hasSalesData = _categorySalesData.any((cat) => (cat['sales'] as double) > 0);
    
    if (!hasSalesData) {
      return _buildEmptyChart('CATEGORY DISTRIBUTION', 'No sales recorded for categories', Icons.pie_chart, primaryColor, isDarkMode, textColor);
    }
    
    // Prepare pie chart sections
    final List<PieChartSectionData> pieSections = [];
    
    for (final cat in _categorySalesData) {
      final category = cat['category'] as String;
      final sales = cat['sales'] as double;
      final color = cat['color'] as Color;
      final percentage = cat['percentage'] as double;
      
      // Only include sections with sales
      if (sales > 0) {
        pieSections.add(
          PieChartSectionData(
            color: color,
            value: sales,
            title: percentage >= 3 ? '${percentage.toStringAsFixed(0)}%' : '',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titlePositionPercentageOffset: 0.6,
          ),
        );
      }
    }
    
    if (pieSections.isEmpty) {
      pieSections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Data',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'CATEGORY DISTRIBUTION',
              style: TextStyle(
                fontSize: Responsive.getSubtitleFontSize(context),
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Spacer(),
            Tooltip(
              message: 'Shows revenue distribution across product categories',
              child: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: pieSections,
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                            startDegreeOffset: -90,
                            pieTouchData: PieTouchData(
                              enabled: true,
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                // Handle touch interactions
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total Revenue: ₱${_totalSales.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Legend
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'CATEGORY BREAKDOWN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _categorySalesData.length,
                          itemBuilder: (context, index) {
                            final data = _categorySalesData[index];
                            final category = data['category'] as String;
                            final color = data['color'] as Color;
                            final percentage = data['percentage'] as double;
                            final sales = data['sales'] as double;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white : Colors.black,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                          sales > 0 ? '₱${sales.toStringAsFixed(0)}' : 'No sales',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: sales > 0 ? Colors.grey.shade500 : Colors.grey.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _generateColorFromCategory(String categoryName) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade600,
      Colors.deepOrange.shade400,
    ];
    
    // Use hashcode to get a consistent color for each category
    final hash = categoryName.hashCode;
    final index = hash.abs() % colors.length;
    return colors[index];
  }

  Widget _buildPeakHoursLineGraph(
    Color primaryColor,
    bool isMobile,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
    BuildContext context,
  ) {
    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 300 : 350),
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
              Row(
                children: [
                  Icon(Icons.timeline, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'HOURLY SALES PERFORMANCE',
                    style: TextStyle(
                      fontSize: Responsive.getTitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Track sales patterns throughout the day',
                style: TextStyle(
                  fontSize: 12,
                  color: mutedTextColor,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                height: isMobile ? 250 : 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: _buildLineChart(primaryColor, isDarkMode, textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(Color primaryColor, bool isDarkMode, Color textColor) {
    if (_hourlyData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No hourly data available',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // Calculate max sales for scaling
    double maxSales = 0.0;
    for (final h in _hourlyData) {
      final sales = h['sales'] as double;
      if (sales > maxSales) maxSales = sales;
    }
    if (maxSales == 0) maxSales = 1;
    
    // Prepare line chart spots
    final spots = _hourlyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final sales = data['sales'] as double;
      return FlSpot(index.toDouble(), sales);
    }).toList();
    
    // Find peak hours
    final peakHours = _hourlyData
        .where((h) => (h['sales'] as double) > maxSales * 0.7)
        .map((h) => h['label'] as String)
        .toList();
    
    // Side titles for X-axis
    Widget getBottomTitles(double value, TitleMeta meta) {
      final index = value.toInt();
      if (index >= 0 && index < _hourlyData.length && index % 2 == 0) {
        final label = _hourlyData[index]['label'] as String;
        return SideTitleWidget(
          fitInside : SideTitleFitInsideData.disable(), 
          space: 4, // Space between chart and text
          meta: meta,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        );
      }
      return Container();
    }
    
    // Side titles for Y-axis
    Widget getLeftTitles(double value, TitleMeta meta) {
      final formattedValue = (value / 1000).toStringAsFixed(0);
      return SideTitleWidget(
        fitInside : SideTitleFitInsideData.disable(), 
        space: 4, // Space between chart and text
        meta: meta,
        child: Text(
          '₱${formattedValue}K',
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (group) => isDarkMode ? Colors.grey.shade800 : Colors.white,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < _hourlyData.length) {
                  final data = _hourlyData[index];
                  final label = data['label'] as String;
                  final sales = data['sales'] as double;
                  return LineTooltipItem(
                    '$label\n₱${sales.toStringAsFixed(2)}',
                    TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return LineTooltipItem('', const TextStyle());
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxSales / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: getLeftTitles,
              reservedSize: 40,
              interval: maxSales / 4,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: getBottomTitles,
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.3),
                  primaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: maxSales * 1.1, // Add 10% padding
      ),
    );
  }

  Widget _buildMobileCharts(Color primaryColor, bool isMobile, bool isDarkMode, Color cardColor, Color textColor, BuildContext context) {
    return Column(
      children: [
        // Bar Chart for Mobile
        Container(
          constraints: BoxConstraints(minHeight: isMobile ? 350 : 400),
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
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, color: primaryColor, size: isMobile ? 18 : 20),
                      const SizedBox(width: 8),
                      Text(
                        'SALES TREND',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : Responsive.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: isMobile ? 250 : 300,
                    child: _buildBarChart(primaryColor, isDarkMode, textColor, context),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pie Chart for Mobile
        Container(
          constraints: BoxConstraints(minHeight: isMobile ? 350 : 400),
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
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pie_chart, color: primaryColor, size: isMobile ? 18 : 20),
                      const SizedBox(width: 8),
                      Text(
                        'CATEGORY DISTRIBUTION',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : Responsive.getTitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: isMobile ? 300 : 350,
                    child: _buildPieChart(primaryColor, isDarkMode, textColor, context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String title, String message, IconData icon, Color primaryColor, bool isDarkMode, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: primaryColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900.withOpacity(0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
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

  // ========== Skeleton UI Components ==========

  Widget _buildSkeletonScreen(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: Responsive.getScreenPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonStatsGrid(context, isMobile, isDarkMode, cardColor),
            const SizedBox(height: 16),
            _buildSkeletonFilters(context, isMobile, isDarkMode, cardColor),
            const SizedBox(height: 16),
            _buildSkeletonCharts(context, isMobile, isDarkMode, cardColor),
            const SizedBox(height: 16),
            _buildSkeletonPeakHoursGraph(context, isMobile, isDarkMode, cardColor),
            const SizedBox(height: 16),
            _buildSkeletonTaxBreakdown(context, isMobile, false, false, isDarkMode, cardColor),
            const SizedBox(height: 16),
            _buildSkeletonBusinessInsights(context, isDarkMode, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonStatsGrid(BuildContext context, bool isMobile, bool isDarkMode, Color cardColor) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
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
            children: [
              Container(
                width: 200,
                height: 20,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.only(bottom: 16),
              ),
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

  Widget _buildSkeletonFilters(BuildContext context, bool isMobile, bool isDarkMode, Color cardColor) {
    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 200 : 150),
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
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              
              if (isMobile)
                Column(
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 56,
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
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 56,
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
    );
  }

  Widget _buildSkeletonCharts(BuildContext context, bool isMobile, bool isDarkMode, Color cardColor) {
    if (isMobile) {
      return Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 300),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 350),
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
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: List.generate(5, (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        constraints: const BoxConstraints(minHeight: 350),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 250,
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
      );
    }
  }

  Widget _buildSkeletonPeakHoursGraph(BuildContext context, bool isMobile, bool isDarkMode, Color cardColor) {
    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 300 : 350),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      shape: BoxShape.circle,
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
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 12,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: isMobile ? 250 : 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonTaxBreakdown(BuildContext context, bool isMobile, bool isTablet, bool isDesktop, bool isDarkMode, Color cardColor) {
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
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
          padding: EdgeInsets.all(isDesktop ? 16 : 12),
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
              const SizedBox(height: 16),
              
              if (isMobile)
                Column(
                  children: [
                    for (int i = 0; i < 4; i++) ...[
                      Container(
                        height: 80,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      if (i < 3) Container(
                        height: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ],
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
                    for (int i = 0; i < 4; i++)
                      Container(
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
                    for (int i = 0; i < 4; i++) ...[
                      Expanded(
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      if (i < 3) const SizedBox(width: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonBusinessInsights(BuildContext context, bool isDarkMode, Color cardColor) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
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
          padding: const EdgeInsets.all(12),
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
                    width: 200,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              for (int i = 0; i < 3; i++) ...[
                Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ========== Filter Card ==========

  Widget _buildFiltersCard(
    Color primaryColor,
    bool isMobile,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
    BuildContext context,
  ) {
    return Container(
      constraints: BoxConstraints(minHeight: isMobile ? 200 : 150),
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
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FILTER OPTIONS',
                style: TextStyle(
                  fontSize: isMobile ? 14 : Responsive.getSubtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              
              if (isMobile)
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedView,
                      onChanged: (value) => _onViewChanged(value!),
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
                    ),
                    const SizedBox(height: 12),
                    
                    if (!_isLoadingCategories)
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        onChanged: (value) => _onCategoryChanged(value!),
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
                        items: [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All Categories', style: TextStyle(color: textColor)),
                          ),
                          ..._productCategories.map((category) => DropdownMenuItem(
                                value: category.name,
                                child: Text(category.name, style: TextStyle(color: textColor)),
                              )),
                        ],
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedView,
                        onChanged: (value) => _onViewChanged(value!),
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    if (!_isLoadingCategories)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          onChanged: (value) => _onCategoryChanged(value!),
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
                          items: [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All Categories', style: TextStyle(color: textColor)),
                            ),
                            ..._productCategories.map((category) => DropdownMenuItem(
                                  value: category.name,
                                  child: Text(category.name, style: TextStyle(color: textColor)),
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== Tax Breakdown Card ==========

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
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
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
                      fontSize: isMobile ? 14 : Responsive.getTitleFontSize(context),
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
                          fontSize: isDesktop ? 13 : 12,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
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
                        fontSize: isDesktop ? 14 : 13,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(100 - (_totalTax / _totalRevenue * 100)).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 13,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Tax:',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 13,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_totalTax / _totalRevenue * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 13,
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

  // ========== Business Insights ==========

  Widget _buildBusinessInsights(
    Color primaryColor,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color mutedTextColor,
    BuildContext context,
  ) {
    // Generate insights based on data
    final insights = _generateBusinessInsights();
    
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
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
          padding: const EdgeInsets.all(12),
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
                        fontSize: 14,
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
              
              ...insights.map((insight) => 
                _buildInsightItem(
                  insight['title'] as String,
                  insight['description'] as String,
                  context,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textColor: textColor,
                  mutedTextColor: mutedTextColor,
                ),
              ).toList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateBusinessInsights() {
    final insights = <Map<String, dynamic>>[];
    
    if (_categorySalesData.isNotEmpty) {
      final topCategory = _categorySalesData.first;
      insights.add({
        'title': '${topCategory['category']} accounts for ${topCategory['percentage'].toStringAsFixed(1)}% of revenue',
        'description': 'Focus on promoting this high-margin product category',
      });
    }
    
    if (_totalTransactions > 0) {
      insights.add({
        'title': 'Average transaction value: ₱${_averageSale.toStringAsFixed(2)}',
        'description': 'Create bundles to increase average sale amount',
      });
    }
    
    if (_dailySalesData.length >= 7) {
      // Calculate weekly trend with proper type handling
      try {
        final recentSales = _dailySalesData.take(7).map<dynamic>((d) => d['sales']).toList();
        final weeklyGrowth = _calculateWeeklyGrowth(recentSales);
        
        if (weeklyGrowth > 0) {
          insights.add({
            'title': 'Sales trending upward this week',
            'description': 'Continue current marketing and sales strategies',
          });
        } else {
          insights.add({
            'title': 'Sales trending downward this week',
            'description': 'Consider promotions or marketing campaigns',
          });
        }
      } catch (e) {
        print('Error calculating weekly trend: $e');
      }
    }
    
    // Add peak hours insight
    if (_hourlyData.isNotEmpty) {
      try {
        final peakHour = _findPeakHour(_hourlyData);
        insights.add({
          'title': 'Peak sales hour: ${peakHour['label']}',
          'description': 'Schedule more staff during peak hours',
        });
      } catch (e) {
        print('Error finding peak hour: $e');
      }
    }
    
    return insights;
  }

  // Helper method to calculate weekly growth without reduce
  double _calculateWeeklyGrowth(List<dynamic> recentSales) {
    if (recentSales.isEmpty || recentSales.length < 2) return 0.0;
    
    double firstSale = 0.0;
    double lastSale = 0.0;
    
    // Safely extract values
    final first = recentSales.first;
    if (first is double) {
      firstSale = first;
    } else if (first is num) {
      firstSale = first.toDouble();
    } else if (first is int) {
      firstSale = first.toDouble();
    }
    
    final last = recentSales.last;
    if (last is double) {
      lastSale = last;
    } else if (last is num) {
      lastSale = last.toDouble();
    } else if (last is int) {
      lastSale = last.toDouble();
    }
    
    return lastSale - firstSale;
  }

  // Helper method to find peak hour without reduce
  Map<String, dynamic> _findPeakHour(List<Map<String, dynamic>> hourlyData) {
    if (hourlyData.isEmpty) {
      return {'label': 'N/A', 'sales': 0.0};
    }
    
    Map<String, dynamic> peakHour = hourlyData.first;
    double maxSales = 0.0;
    
    for (final hour in hourlyData) {
      final sales = hour['sales'];
      double currentSales = 0.0;
      
      if (sales is double) {
        currentSales = sales;
      } else if (sales is num) {
        currentSales = sales.toDouble();
      } else if (sales is int) {
        currentSales = sales.toDouble();
      }
      
      if (currentSales > maxSales) {
        maxSales = currentSales;
        peakHour = hour;
      }
    }
    
    return peakHour;
  }

  // ========== Helper Methods ==========

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
    
    final padding = isDesktop ? const EdgeInsets.all(10) : const EdgeInsets.all(12);
    final iconSize = isDesktop ? 20.0 : 24.0;
    final titleSize = isDesktop ? 11 : 12;
    final valueSize = isDesktop ? 14 : 16;
    final descSize = isDesktop ? 10 : 11;
    
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
                fontSize: titleSize.toDouble(),
                color: mutedTextColor ?? Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              isPercent ? '${value.toStringAsFixed(1)}%' : '₱${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: valueSize.toDouble(),
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w700,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: descSize.toDouble(),
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
              color: primaryColor ?? Colors.blue,
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor ?? Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
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