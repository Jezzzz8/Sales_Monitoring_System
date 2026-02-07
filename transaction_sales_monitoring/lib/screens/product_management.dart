// lib/screens/product_management.dart - UPDATED VERSION
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../utils/responsive.dart';
import '../screens/category_management.dart';
import '../utils/settings_mixin.dart';
import '../services/image_upload_service.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> with SettingsMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showInactive = false;
  bool _showFilters = false;
  bool _loadingCategories = false;
  XFile? _selectedImage;
  String? _image;
  bool _isUploadingImage = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if settings are still loading
    if (isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Theme colors based on dark mode
    final primaryColor = getPrimaryColor();
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final padding = Responsive.getScreenPadding(context);

    return Scaffold(
      backgroundColor: backgroundColor,
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
                  // Main Stats Grid
                  StreamBuilder<List<Product>>(
                    stream: ProductService.getProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryColor));
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading products: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      
                      final products = snapshot.data ?? [];
                      final activeProducts = products.where((p) => p.isActive).length;
                      final lowStockProducts = products.where((p) => p.needsReorder).length;
                      
                      return StreamBuilder<List<ProductCategory>>(
                        stream: CategoryService.getCategoriesByTypeStream('product'),
                        builder: (context, categorySnapshot) {
                          final categories = categorySnapshot.data ?? [];
                          
                          return Responsive.buildResponsiveCardGrid(
                            context: context,
                            title: 'PRODUCT OVERVIEW',
                            titleColor: primaryColor,
                            centerTitle: true,
                            cards: [
                              _buildStatCard(
                                'Total Products',
                                '${products.length}',
                                Icons.restaurant_menu,
                                Colors.blue,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'All menu items',
                              ),
                              _buildStatCard(
                                'Active Products',
                                '$activeProducts',
                                Icons.check_circle,
                                Colors.green,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'Available for sale',
                              ),
                              _buildStatCard(
                                'Categories',
                                '${categories.length}',
                                Icons.category,
                                Colors.orange,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'Menu categories',
                              ),
                              _buildStatCard(
                                'Low Stock',
                                '$lowStockProducts',
                                Icons.warning,
                                Colors.red,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'Need reorder',
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filter Options Card
                  _buildFilterCard(context, primaryColor, isDarkMode, textColor, mutedTextColor, cardColor, isMobile),
                  
                  const SizedBox(height: 16),
                  
                  // Sort and Add Product Row
                  _buildActionRow(context, primaryColor, textColor, cardColor, isDarkMode, isMobile),
                  
                  const SizedBox(height: 16),
                  
                  // Product Grid
                  _buildProductGrid(context, primaryColor, isDarkMode, cardColor, textColor, mutedTextColor),
                  
                  const SizedBox(height: 16),
                  
                  // Category Overview Card
                  _buildCategoryOverview(context, primaryColor, cardColor, textColor, mutedTextColor, isMobile),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, Color primaryColor, bool isDarkMode, 
    Color textColor, Color mutedTextColor, Color cardColor, bool isMobile) {
    return Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FILTER OPTIONS',
                    style: TextStyle(
                      fontSize: Responsive.getSubtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (_showInactive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Inactive Visible',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products by name or description...',
                  hintStyle: TextStyle(color: mutedTextColor),
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
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
                style: TextStyle(color: textColor),
                onChanged: (value) => setState(() {}),
              ),
              if ((!isMobile || _showFilters))
                Column(
                  children: [
                    const SizedBox(height: 12),
                    if (!isMobile)
                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<List<ProductCategory>>(
                              stream: CategoryService.getCategoriesByTypeStream('product'),
                              builder: (context, snapshot) {
                                final categories = snapshot.data ?? [];
                                
                                return DropdownButtonFormField<String>(
                                  value: _selectedCategory,
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
                                  items: ['All', ...categories.map((c) => c.id)]
                                      .map((category) => DropdownMenuItem(
                                            value: category,
                                            child: Text(
                                              category == 'All' 
                                                ? 'All Categories' 
                                                : categories.firstWhere((c) => c.id == category, orElse: () => ProductCategory(
                                                    id: 'unknown',
                                                    name: 'Unknown',
                                                    type: 'product',
                                                    createdAt: DateTime.now(),
                                                  )).name, 
                                              style: TextStyle(color: textColor)
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: _showInactive 
                                  ? Border.all(color: Colors.orange, width: 1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _showInactive,
                                  onChanged: (value) {
                                    setState(() {
                                      _showInactive = value ?? false;
                                    });
                                  },
                                  activeColor: Colors.orange,
                                ),
                                Text(
                                  'Show Inactive',
                                  style: TextStyle(
                                    color: _showInactive ? Colors.orange : textColor,
                                    fontWeight: _showInactive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          StreamBuilder<List<ProductCategory>>(
                            stream: CategoryService.getCategoriesByTypeStream('product'),
                            builder: (context, snapshot) {
                              final categories = snapshot.data ?? [];
                              
                              // FIX: Check if selected category exists in categories
                              String currentSelectedCategory = _selectedCategory;
                              if (_selectedCategory != 'All' && 
                                  !categories.any((c) => c.id == _selectedCategory)) {
                                currentSelectedCategory = 'All';
                              }
                              
                              return DropdownButtonFormField<String>(
                                value: currentSelectedCategory, // Use validated category
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
                                items: [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All Categories', style: TextStyle(color: textColor)),
                                  ),
                                  ...categories.map((category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(category.name, style: TextStyle(color: textColor)),
                                      )).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value!;
                                  });
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: _showInactive 
                                  ? Border.all(color: Colors.orange, width: 1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _showInactive,
                                  onChanged: (value) {
                                    setState(() {
                                      _showInactive = value ?? false;
                                    });
                                  },
                                  activeColor: Colors.orange,
                                ),
                                Text(
                                  'Show Inactive',
                                  style: TextStyle(
                                    color: _showInactive ? Colors.orange : textColor,
                                    fontWeight: _showInactive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              if (isMobile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      child: Text(
                        _showFilters ? 'Hide Filters' : 'Show Filters',
                        style: TextStyle(color: primaryColor),
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

  Widget _buildActionRow(BuildContext context, Color primaryColor, Color textColor, 
      Color cardColor, bool isDarkMode, bool isMobile) {
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
        padding: EdgeInsets.all(Responsive.getCardPadding(context).top),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.restaurant_menu, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRODUCTS',
                    style: TextStyle(
                      fontSize: Responsive.getSubtitleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Responsive.getOrientationFlexLayout(
              context,
              children: [
                ElevatedButton.icon(
                  onPressed: _openCategoryManagement,
                  icon: Icon(Icons.category, 
                      size: Responsive.getIconSize(context, multiplier: 0.8)),
                  label: Text(
                    'MANAGE CATEGORIES',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                      vertical: Responsive.getButtonHeight(context) * 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addProduct,
                  icon: Icon(Icons.add, 
                      size: Responsive.getIconSize(context, multiplier: 0.8)),
                  label: Text(
                    'ADD PRODUCT',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                      vertical: Responsive.getButtonHeight(context) * 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, Color primaryColor, bool isDarkMode, 
    Color cardColor, Color textColor, Color mutedTextColor) {
  
    return StreamBuilder<List<Product>>(
      stream: ProductService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading products: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        
        final allProducts = snapshot.data ?? [];
        
        // Debug: Print current filter state
        print('Filter State: ShowInactive = $_showInactive, Total Products = ${allProducts.length}');
        print('Active Products: ${allProducts.where((p) => p.isActive).length}');
        print('Inactive Products: ${allProducts.where((p) => !p.isActive).length}');
        
        // Filter products
        final filteredProducts = allProducts.where((product) {
          final matchesCategory = _selectedCategory == 'All' || product.categoryId == _selectedCategory;
          final matchesActive = _showInactive || product.isActive; // When _showInactive is true, show all; when false, show only active
          final matchesSearch = _searchController.text.isEmpty ||
              product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              product.description.toLowerCase().contains(_searchController.text.toLowerCase());
          
          final shouldShow = matchesCategory && matchesActive && matchesSearch;
          
          // Debug individual product
          if (product.name.toLowerCase().contains('test')) {
            print('Product "${product.name}": isActive=${product.isActive}, matchesActive=$matchesActive, shouldShow=$shouldShow');
          }
          
          return shouldShow;
        }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
        
        // Debug filtered results
        print('Filtered Products: ${filteredProducts.length}');
        print('Filtered Active: ${filteredProducts.where((p) => p.isActive).length}');
        print('Filtered Inactive: ${filteredProducts.where((p) => !p.isActive).length}');
        
        if (filteredProducts.isEmpty) {
          return Container(
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
                padding: EdgeInsets.all(Responsive.getCardPadding(context).top * 2),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        size: Responsive.getIconSize(context, multiplier: 3),
                        color: mutedTextColor,
                      ),
                      SizedBox(height: Responsive.getSpacing(context).height),
                      Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: Responsive.getBodyFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _showInactive 
                            ? 'Try adjusting your search or category filters'
                            : 'Try adjusting your filters or add a new product',
                        style: TextStyle(
                          fontSize: Responsive.getBodyFontSize(context) * 0.9,
                          color: mutedTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!_showInactive && allProducts.any((p) => !p.isActive))
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showInactive = true;
                              });
                            },
                            icon: Icon(Icons.visibility, size: 18),
                            label: Text('Show Inactive Products'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        
        return Column(
          children: [
            // Filter status indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${filteredProducts.length} product${filteredProducts.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: mutedTextColor,
                    ),
                  ),
                  if (_showInactive)
                    Chip(
                      label: Text('Showing Inactive'),
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      labelStyle: TextStyle(color: Colors.orange),
                      avatar: Icon(Icons.visibility, size: 16, color: Colors.orange),
                    ),
                ],
              ),
            ),
            
            // Products grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getGridColumnCount(context),
                crossAxisSpacing: Responsive.getPaddingSize(context),
                mainAxisSpacing: Responsive.getPaddingSize(context),
                childAspectRatio: _getCardAspectRatio(context),
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) => _buildProductCard(
                filteredProducts[index], 
                context, 
                isDarkMode: isDarkMode
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryOverview(BuildContext context, Color primaryColor, Color cardColor, 
      Color textColor, Color mutedTextColor, bool isMobile) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
      child: Card(
        elevation: Theme.of(context).brightness == Brightness.dark ? 2 : 3,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                    child: Icon(Icons.category, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CATEGORY OVERVIEW',
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
              SizedBox(height: Responsive.getSpacing(context).height),
              
              StreamBuilder<List<ProductCategory>>(
                stream: CategoryService.getCategoriesByTypeStream('product'),
                builder: (context, categorySnapshot) {
                  if (categorySnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: primaryColor));
                  }
                  
                  final categories = categorySnapshot.data ?? [];
                  
                  return StreamBuilder<List<Product>>(
                    stream: ProductService.getProducts(),
                    builder: (context, productSnapshot) {
                      final products = productSnapshot.data ?? [];
                      
                      if (categories.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              Icon(Icons.category_outlined, size: 48, color: mutedTextColor),
                              const SizedBox(height: 8),
                              Text(
                                'No categories found',
                                style: TextStyle(color: mutedTextColor),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _openCategoryManagement,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Categories'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return isMobile
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final itemsCount = products.where((item) => item.categoryId == category.id && item.isActive).length;
                                return _buildCategorySummaryMobile(category, itemsCount, context, isDarkMode: Theme.of(context).brightness == Brightness.dark);
                              },
                            )
                          : DataTable(
                              headingRowHeight: Responsive.getDataTableRowHeight(context),
                              dataRowHeight: Responsive.getDataTableRowHeight(context),
                              headingTextStyle: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                              columns: const [
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Products')),
                                DataColumn(label: Text('Average Price')),
                                DataColumn(label: Text('Total Stock')),
                              ],
                              rows: categories.map((category) {
                                final categoryProducts = products
                                    .where((p) => p.categoryId == category.id && p.isActive);
                                final avgPrice = categoryProducts.isEmpty
                                    ? 0
                                    : categoryProducts.fold(0.0, (sum, p) => sum + p.price) /
                                        categoryProducts.length;
                                final totalStock = categoryProducts.fold(
                                    0, (sum, p) => sum + p.stock);
                                
                                return DataRow(cells: [
                                  DataCell(
                                    Text(
                                      category.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('${categoryProducts.length}', style: TextStyle(color: textColor))),
                                  DataCell(
                                    Text(
                                      '₱${avgPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('$totalStock', style: TextStyle(color: textColor))),
                                ]);
                              }).toList(),
                            );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========== HELPER METHODS ===========

  double _getCardAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 0.65;
    if (screenWidth < 960) return 0.7;
    if (screenWidth < 1280) return 0.75;
    return 0.8;
  }

  int _getGridColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 2;
    if (screenWidth < 960) return 3;
    if (screenWidth < 1280) return 4;
    return 5;
  }

  Widget _buildProductCard(Product product, BuildContext context, {bool isDarkMode = false}) {
    final primaryColor = getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    final cardHeight = isMobile ? 180 : (isTablet ? 200 : 180);
    final iconSize = isMobile ? 32.0 : (isTablet ? 36.0 : 32.0);
    final titleFontSize = isMobile ? 11.0 : (isTablet ? 13.0 : 12.0);
    final priceFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 14.0);
    final cardPadding = isMobile ? 6.0 : 8.0;
    
    return SizedBox(
      height: cardHeight.toDouble(),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showProductDetails(product),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDarkMode ? Colors.grey.shade800 : Colors.white,
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container - UPDATED
                Container(
                  width: double.infinity,
                  height: cardHeight * 0.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [Colors.grey.shade700, Colors.grey.shade800]
                          : [primaryColor.withOpacity(0.05), primaryColor.withOpacity(0.1)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Show actual image if available, otherwise show icon
                      if (product.image != null && product.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.image!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFallbackIcon(product, iconSize, primaryColor, isDarkMode);
                            },
                          ),
                        )
                      else
                        _buildFallbackIcon(product, iconSize, primaryColor, isDarkMode),
                      
                      if (product.needsReorder)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning, size: 12, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(
                                  '${product.stock}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (!product.isActive)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'INACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Product Name
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Price
                Text(
                  '₱${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: priceFontSize,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Category and Stock
                StreamBuilder<List<ProductCategory>>(
                  stream: CategoryService.getCategoriesByTypeStream('product'),
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? [];
                    final category = categories.firstWhere(
                      (c) => c.id == product.categoryId,
                      orElse: () => ProductCategory(
                        id: 'unknown',
                        name: 'Unknown',
                        type: 'product',
                        createdAt: DateTime.now(),
                      ),
                    );
                    
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.category, size: 10, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory,
                              size: 10,
                              color: product.needsReorder ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${product.stock}',
                              style: TextStyle(
                                fontSize: 9,
                                color: product.needsReorder ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _editProduct(product),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          side: const BorderSide(color: Colors.blue, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _toggleProductStatus(product),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          side: BorderSide(
                            color: product.isActive ? Colors.orange : Colors.green,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          product.isActive ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.isActive ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildFallbackIcon(Product product, double iconSize, Color primaryColor, bool isDarkMode) {
    return StreamBuilder<List<ProductCategory>>(
      stream: CategoryService.getCategoriesByTypeStream('product'),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final category = categories.firstWhere(
          (c) => c.id == product.categoryId,
          orElse: () => ProductCategory(
            id: 'unknown',
            name: 'Unknown',
            type: 'product',
            createdAt: DateTime.now(),
          ),
        );
        
        return Center(
          child: Icon(
            _getProductIcon(category.name),
            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
            size: iconSize,
          ),
        );
      },
    );
  }

  Widget _buildProductDetailsFallbackIcon(Product product, Color primaryColor, bool isDarkMode) {
    return StreamBuilder<List<ProductCategory>>(
      stream: CategoryService.getCategoriesByTypeStream('product'),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final category = categories.firstWhere(
          (c) => c.id == product.categoryId,
          orElse: () => ProductCategory(
            id: 'unknown',
            name: 'Unknown',
            type: 'product',
            createdAt: DateTime.now(),
          ),
        );
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getProductIcon(category.name),
                color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'No Image Available',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageUploadSection(
    BuildContext context,
    String? currentimage,
    Function(XFile?) onImageSelected,
    Function(String) onUrlChanged,
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'PRODUCT IMAGE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        
        // Current image preview
        if (currentimage != null && currentimage.isNotEmpty)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentimage,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Image URL input
        TextField(
          onChanged: onUrlChanged,
          decoration: InputDecoration(
            labelText: 'Image URL',
            labelStyle: TextStyle(color: mutedTextColor),
            hintText: 'https://example.com/image.jpg',
            hintStyle: TextStyle(color: mutedTextColor.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
            prefixIcon: Icon(Icons.link, color: primaryColor),
          ),
          style: TextStyle(color: textColor),
        ),
        
        const SizedBox(height: 8),
        Text(
          'OR',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: mutedTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        
        // Upload buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final XFile? image = await ImageUploadService.pickImageFromGallery();
                  if (image != null) {
                    onImageSelected(image);
                  }
                },
                icon: Icon(Icons.photo_library, size: 18),
                label: Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final XFile? image = await ImageUploadService.takePicture();
                  if (image != null) {
                    onImageSelected(image);
                  }
                },
                icon: Icon(Icons.camera_alt, size: 18),
                label: Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        
        // Selected image preview
        if (_selectedImage != null)
          Column(
            children: [
              SizedBox(height: 12),
              Text(
                'Selected Image:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor),
                ),
                child: FutureBuilder<Uint8List?>(
                  future: File(_selectedImage!.path).readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasData) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    return Center(
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  IconData _getProductIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'whole lechon':
        return Icons.celebration;
      case 'lechon belly':
        return Icons.restaurant_menu;
      case 'drinks':
        return Icons.local_drink;
      case 'appetizers':
        return Icons.fastfood;
      case 'desserts':
        return Icons.cake;
      case 'pastas':
        return Icons.restaurant;
      default:
        return Icons.fastfood;
    }
  }

  Widget _buildCategorySummaryMobile(ProductCategory category, int itemsCount, BuildContext context, {bool isDarkMode = false}) {
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return StreamBuilder<List<Product>>(
      stream: ProductService.getProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final categoryProducts = products.where((p) => p.categoryId == category.id && p.isActive);
        final avgPrice = categoryProducts.isEmpty
            ? 0
            : categoryProducts.fold(0.0, (sum, p) => sum + p.price) /
                categoryProducts.length;
        final totalStock = categoryProducts.fold(0, (sum, p) => sum + p.stock);
        
        return Card(
          margin: EdgeInsets.only(bottom: Responsive.getPaddingSize(context)),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
          child: Padding(
            padding: Responsive.getCardPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getSubtitleFontSize(context),
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Products',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                              color: mutedTextColor,
                            ),
                          ),
                          Text(
                            '$itemsCount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Avg Price',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                              color: mutedTextColor,
                            ),
                          ),
                          Text(
                            '₱${avgPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Total Stock',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                              color: mutedTextColor,
                            ),
                          ),
                          Text(
                            '$totalStock',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, 
    {bool isDarkMode = false, String? subtitle}) {
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
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  // =========== DIALOG METHODS ===========

  Future<void> _showProductDetails(Product product) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.restaurant_menu, color: primaryColor),
            const SizedBox(width: 12),
            Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image/Icon
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                child: product.image != null && product.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: primaryColor,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildProductDetailsFallbackIcon(product, primaryColor, isDarkMode);
                          },
                        ),
                      )
                    : _buildProductDetailsFallbackIcon(product, primaryColor, isDarkMode),
              ),
              const SizedBox(height: 16),
              
              // Basic Info
              Text(
                'PRODUCT INFORMATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              // Details Grid
              StreamBuilder<List<ProductCategory>>(
                stream: CategoryService.getCategoriesByTypeStream('product'),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  final category = categories.firstWhere(
                    (c) => c.id == product.categoryId,
                    orElse: () => ProductCategory(
                      id: 'unknown',
                      name: 'Unknown',
                      type: 'product',
                      createdAt: DateTime.now(),
                    ),
                  );
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 8,
                    children: [
                      _buildDetailItem('Category', category.name, Icons.category),
                      _buildDetailItem('Price', '₱${product.price.toStringAsFixed(2)}', Icons.attach_money),
                      _buildDetailItem('Cost', '₱${product.cost.toStringAsFixed(2)}', Icons.price_change),
                      _buildDetailItem('Stock', '${product.stock}', Icons.inventory),
                      _buildDetailItem('Reorder Level', '${product.reorderLevel}', Icons.warning),
                      _buildDetailItem('Unit', product.unit, Icons.scale),
                      _buildDetailItem('Status', product.isActive ? 'Active' : 'Inactive', 
                          product.isActive ? Icons.check_circle : Icons.remove_circle,
                          color: product.isActive ? Colors.green : Colors.red),
                      _buildDetailItem('Margin', '₱${product.margin.toStringAsFixed(2)}', Icons.trending_up),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              if (product.description.isNotEmpty) ...[
                Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.description,
                    style: TextStyle(color: textColor),
                  ),
                ),
              ],
              
              // Ingredients
              if (product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'INGREDIENTS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: product.ingredients!.map((ingredient) {
                    return Chip(
                      label: Text(ingredient),
                      backgroundColor: primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: primaryColor),
                    );
                  }).toList(),
                ),
              ],
              
              // Created/Updated info
              const SizedBox(height: 16),
              Text(
                'METADATA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created:',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedTextColor,
                          ),
                        ),
                        Text(
                          '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (product.updatedAt != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Updated:',
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedTextColor,
                            ),
                          ),
                          Text(
                            '${product.updatedAt!.day}/${product.updatedAt!.month}/${product.updatedAt!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text('Edit Product'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value, IconData icon, {Color? color}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ]
      )
    );
  }

  Future<void> _addProduct() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController costController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    final TextEditingController reorderController = TextEditingController(text: '0');
    final TextEditingController unitController = TextEditingController(text: 'pcs');
    final TextEditingController ingredientsController = TextEditingController();
    final TextEditingController imageController = TextEditingController();
    
    String selectedCategory = '';
    bool isActive = true;
    XFile? selectedImage;
    String image = '';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.add_circle, color: primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Add New Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: Responsive.isMobile(context) ? double.infinity : 500,
                child: StreamBuilder<List<ProductCategory>>(
                  stream: CategoryService.getCategoriesByTypeStream('product'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final categories = snapshot.data ?? [];
                    
                    if (categories.isEmpty) {
                      return Column(
                        children: [
                          const Text(
                            'No product categories found. Please create categories first.',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _openCategoryManagement();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Manage Categories'),
                          ),
                        ],
                      );
                    }
                    
                    // Set default category if not set
                    if (selectedCategory.isEmpty && categories.isNotEmpty) {
                      selectedCategory = categories.first.id;
                    }
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Upload Section
                        _buildImageUploadSection(
                          context,
                          null,
                          (image) => setState(() => selectedImage = image),
                          (url) => setState(() => image = url),
                          isDarkMode,
                          primaryColor,
                          textColor,
                          mutedTextColor,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Product Name
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.restaurant_menu, color: primaryColor),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 12),
                        
                        // Category
                        StreamBuilder<List<ProductCategory>>(
                          stream: CategoryService.getCategoriesByTypeStream('product'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final categories = snapshot.data ?? [];
                            
                            if (categories.isEmpty) {
                              return Column(
                                children: [
                                  const Text(
                                    'No product categories found. Please create categories first.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _openCategoryManagement();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text('Manage Categories'),
                                  ),
                                ],
                              );
                            }
                            
                            // FIX: Set default category to first if not set
                            String currentCategory = selectedCategory;
                            if (currentCategory.isEmpty && categories.isNotEmpty) {
                              currentCategory = categories.first.id;
                            }
                            
                            return DropdownButtonFormField<String>(
                              value: currentCategory.isNotEmpty ? currentCategory : null,
                              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: 'Category *',
                                labelStyle: TextStyle(color: mutedTextColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                prefixIcon: Icon(Icons.category, color: primaryColor),
                              ),
                              items: categories
                                  .map((category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(
                                          category.name,
                                          style: TextStyle(color: textColor),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value!;
                                });
                              },
                            );
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Price and Cost Row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: priceController,
                                decoration: InputDecoration(
                                  labelText: 'Selling Price *',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.attach_money, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: costController,
                                decoration: InputDecoration(
                                  labelText: 'Cost Price *',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.price_change, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Stock and Reorder Level Row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stockController,
                                decoration: InputDecoration(
                                  labelText: 'Initial Stock *',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.inventory, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: reorderController,
                                decoration: InputDecoration(
                                  labelText: 'Reorder Level',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.warning, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Unit
                        TextField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: 'Unit (e.g., pcs, kg, box) *',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.scale, color: primaryColor),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Description
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.description, color: primaryColor),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Ingredients
                        TextField(
                          controller: ingredientsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Ingredients (comma separated)',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.restaurant, color: primaryColor),
                            helperText: 'Separate with commas: flour,sugar,eggs',
                            helperStyle: TextStyle(color: mutedTextColor, fontSize: 11),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Active Status
                        Row(
                          children: [
                            Checkbox(
                              value: isActive,
                              onChanged: (value) {
                                setState(() {
                                  isActive = value!;
                                });
                              },
                            ),
                            Text(
                              'Active Product',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_validateProductForm(
                    nameController.text,
                    priceController.text,
                    costController.text,
                    stockController.text,
                    selectedCategory,
                  )) {
                    try {
                      // Generate product ID
                      final productId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
                      
                      // Upload image if selected
                      String? finalimage;
                      if (selectedImage != null) {
                        setState(() => _isUploadingImage = true);
                        final imageBytes = await File(selectedImage!.path).readAsBytes();
                        final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        finalimage = await ImageUploadService.uploadImage(
                          productId,
                          imageBytes,
                          fileName,
                        );
                        setState(() => _isUploadingImage = false);
                      } else if (image.isNotEmpty && ImageUploadService.isValidimage(image)) {
                        finalimage = image;
                      }
                      
                      final newProduct = Product(
                        id: productId,
                        name: nameController.text.trim(),
                        categoryId: selectedCategory,
                        description: descriptionController.text.trim(),
                        price: double.parse(priceController.text),
                        cost: double.parse(costController.text),
                        stock: int.parse(stockController.text),
                        reorderLevel: int.parse(reorderController.text),
                        unit: unitController.text.trim(),
                        image: finalimage,
                        ingredients: ingredientsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        isActive: isActive,
                        createdAt: DateTime.now(),
                      );
                      
                      await ProductService.createProduct(newProduct);
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Product "${newProduct.name}" added successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error adding product: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: _isUploadingImage
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Add Product'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editProduct(Product product) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController descriptionController = TextEditingController(text: product.description);
    final TextEditingController priceController = TextEditingController(text: product.price.toString());
    final TextEditingController costController = TextEditingController(text: product.cost.toString());
    final TextEditingController stockController = TextEditingController(text: product.stock.toString());
    final TextEditingController reorderController = TextEditingController(text: product.reorderLevel.toString());
    final TextEditingController unitController = TextEditingController(text: product.unit);
    final TextEditingController ingredientsController = TextEditingController(
      text: product.ingredients?.join(', ') ?? ''
    );
    final TextEditingController imageController = TextEditingController(text: product.image ?? '');
    
    String selectedCategory = product.categoryId;
    bool isActive = product.isActive;
    XFile? selectedImage;
    String image = product.image ?? '';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.edit, color: primaryColor), // Changed icon to edit
                const SizedBox(width: 12),
                Text(
                  'Edit Product',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: Responsive.isMobile(context) ? double.infinity : 500,
                child: StreamBuilder<List<ProductCategory>>(
                  stream: CategoryService.getCategoriesByTypeStream('product'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final categories = snapshot.data ?? [];
                    
                    if (categories.isEmpty) {
                      return Column(
                        children: [
                          const Text(
                            'No product categories found. Please create categories first.',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _openCategoryManagement();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Manage Categories'),
                          ),
                        ],
                      );
                    }
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Upload Section - Show current image
                        _buildImageUploadSection(
                          context,
                          product.image, // Pass current image URL
                          (newImage) => setState(() => selectedImage = newImage),
                          (url) => setState(() => image = url),
                          isDarkMode,
                          primaryColor,
                          textColor,
                          mutedTextColor,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Product Name
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.restaurant_menu, color: primaryColor),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 12),
                        
                        // Category
                        StreamBuilder<List<ProductCategory>>(
                          stream: CategoryService.getCategoriesByTypeStream('product'),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            
                            final categories = snapshot.data ?? [];
                            
                            if (categories.isEmpty) {
                              return Column(
                                children: [
                                  const Text(
                                    'No product categories found.',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _openCategoryManagement();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                    ),
                                    child: const Text('Manage Categories'),
                                  ),
                                ],
                              );
                            }
                            
                            // FIX: Check if selectedCategory exists in categories, if not use first category
                            String currentCategory = selectedCategory;
                            final categoryExists = categories.any((c) => c.id == selectedCategory);
                            if (!categoryExists && categories.isNotEmpty) {
                              currentCategory = categories.first.id;
                            }
                            
                            return DropdownButtonFormField<String>(
                              value: currentCategory, // Use the validated category
                              dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: 'Category *',
                                labelStyle: TextStyle(color: mutedTextColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                prefixIcon: Icon(Icons.category, color: primaryColor),
                              ),
                              items: categories
                                  .map((category) => DropdownMenuItem(
                                        value: category.id,
                                        child: Text(
                                          category.name,
                                          style: TextStyle(color: textColor),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value!;
                                });
                              },
                            );
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Price and Cost Row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: priceController,
                                decoration: InputDecoration(
                                  labelText: 'Selling Price *',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.attach_money, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: costController,
                                decoration: InputDecoration(
                                  labelText: 'Cost Price *',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.price_change, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Stock and Reorder Level Row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stockController,
                                decoration: InputDecoration(
                                  labelText: 'Current Stock *',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.inventory, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: reorderController,
                                decoration: InputDecoration(
                                  labelText: 'Reorder Level',
                                  labelStyle: TextStyle(color: mutedTextColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: primaryColor),
                                  ),
                                  prefixIcon: Icon(Icons.warning, color: primaryColor),
                                ),
                                style: TextStyle(color: textColor),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Unit
                        TextField(
                          controller: unitController,
                          decoration: InputDecoration(
                            labelText: 'Unit (e.g., pcs, kg, box) *',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.scale, color: primaryColor),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Description
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.description, color: primaryColor),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Ingredients
                        TextField(
                          controller: ingredientsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Ingredients (comma separated)',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            prefixIcon: Icon(Icons.restaurant, color: primaryColor),
                            helperText: 'Separate with commas: flour,sugar,eggs',
                            helperStyle: TextStyle(color: mutedTextColor, fontSize: 11),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Active Status
                        Row(
                          children: [
                            Checkbox(
                              value: isActive,
                              onChanged: (value) {
                                setState(() {
                                  isActive = value!;
                                });
                              },
                            ),
                            Text(
                              'Active Product',
                              style: TextStyle(color: textColor),
                            ),
                          ],
                        ),
                        
                        // Product Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product Information:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                                style: TextStyle(color: mutedTextColor, fontSize: 12),
                              ),
                              if (product.updatedAt != null)
                                Text(
                                  'Last Updated: ${product.updatedAt!.day}/${product.updatedAt!.month}/${product.updatedAt!.year}',
                                  style: TextStyle(color: mutedTextColor, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_validateProductForm(
                    nameController.text,
                    priceController.text,
                    costController.text,
                    stockController.text,
                    selectedCategory,
                  )) {
                    try {
                      // Upload image if selected
                      String? finalImage;
                      if (selectedImage != null) {
                        setState(() => _isUploadingImage = true);
                        final imageBytes = await File(selectedImage!.path).readAsBytes();
                        final fileName = '${product.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        finalImage = await ImageUploadService.uploadImage(
                          product.id, // Use existing product ID
                          imageBytes,
                          fileName,
                        );
                        setState(() => _isUploadingImage = false);
                      } else if (image.isNotEmpty && ImageUploadService.isValidimage(image)) {
                        finalImage = image;
                      } else if (product.image != null && product.image!.isNotEmpty) {
                        // Keep existing image if no new image is provided
                        finalImage = product.image;
                      }
                      
                      // Use product.copyWith to update the existing product
                      final updatedProduct = product.copyWith(
                        name: nameController.text.trim(),
                        categoryId: selectedCategory,
                        description: descriptionController.text.trim(),
                        price: double.parse(priceController.text),
                        cost: double.parse(costController.text),
                        stock: int.parse(stockController.text),
                        reorderLevel: int.parse(reorderController.text),
                        unit: unitController.text.trim(),
                        image: finalImage, // Use the correct field name
                        ingredients: ingredientsController.text
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList(),
                        isActive: isActive,
                        updatedAt: DateTime.now(),
                      );
                      
                      // CORRECT: Use updateProduct instead of createProduct
                      await ProductService.updateProduct(updatedProduct);
                      
                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Product "${updatedProduct.name}" updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating product: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: _isUploadingImage
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Update Product'), // Changed button text
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleProductStatus(Product product) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              product.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
              color: product.isActive ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 12),
            Text(
              product.isActive ? 'Deactivate Product' : 'Activate Product',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        content: Text(
          product.isActive
              ? 'Are you sure you want to deactivate "${product.name}"? This product will no longer be available for sale.'
              : 'Are you sure you want to activate "${product.name}"? This product will become available for sale.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: product.isActive ? Colors.orange : Colors.green,
            ),
            child: Text(product.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        final updatedProduct = product.copyWith(
          isActive: !product.isActive,
          updatedAt: DateTime.now(),
        );
        
        await ProductService.updateProduct(updatedProduct);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product.isActive
                  ? 'Product "${product.name}" deactivated'
                  : 'Product "${product.name}" activated',
            ),
            backgroundColor: product.isActive ? Colors.orange : Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // =========== VALIDATION METHODS ===========

  bool _validateProductForm(
    String name,
    String price,
    String cost,
    String stock,
    String category,
  ) {
    if (name.isEmpty) {
      _showErrorSnackbar('Please enter a product name');
      return false;
    }
    
    if (category.isEmpty) {
      _showErrorSnackbar('Please select a category');
      return false;
    }
    
    if (price.isEmpty || double.tryParse(price) == null || double.parse(price) <= 0) {
      _showErrorSnackbar('Please enter a valid selling price');
      return false;
    }
    
    if (cost.isEmpty || double.tryParse(cost) == null || double.parse(cost) <= 0) {
      _showErrorSnackbar('Please enter a valid cost price');
      return false;
    }
    
    if (stock.isEmpty || int.tryParse(stock) == null) {
      _showErrorSnackbar('Please enter a valid stock quantity');
      return false;
    }
    
    return true;
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // =========== NAVIGATION METHODS ===========

  void _openCategoryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagement(categoryType: 'product'),
      ),
    );
  }
}