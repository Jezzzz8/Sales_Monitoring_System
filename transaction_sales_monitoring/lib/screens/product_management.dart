// lib/screens/product_management.dart - UPDATED WITH INVENTORY DEPENDENCY FEATURES
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/category_service.dart' hide InventoryService;
import '../utils/responsive.dart';
import '../screens/category_management.dart';
import '../utils/settings_mixin.dart';
import '../services/image_upload_service.dart';
import '../models/inventory.dart';
import '../services/inventory_service.dart';
import '../models/product.dart';

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
  XFile? _selectedImage;
  bool _isUploadingImage = false;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  bool _isDialogOpen = false;
  
  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if settings are still loading
    if (isLoadingSettings) {
      return _buildSkeletonScreen(context);
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
      body: Stack(
        children: [
          LayoutBuilder(
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
                      if (_isInitialLoad)
                        _buildSkeletonStatsGrid(context, isDarkMode: isDarkMode)
                      else
                        StreamBuilder<List<Product>>(
                          stream: ProductService.getProducts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return _buildSkeletonStatsGrid(context, isDarkMode: isDarkMode);
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
                      if (_isInitialLoad)
                        _buildSkeletonCard(context, height: isMobile ? 200 : 150, isDarkMode: isDarkMode)
                      else
                        _buildFilterCard(context, primaryColor, isDarkMode, textColor, mutedTextColor, cardColor, isMobile),
                      
                      const SizedBox(height: 16),
                      
                      // Sort and Add Product Row
                      if (_isInitialLoad)
                        _buildSkeletonCard(context, height: 100, isDarkMode: isDarkMode)
                      else
                        _buildActionRow(context, primaryColor, textColor, cardColor, isDarkMode, isMobile),
                      
                      const SizedBox(height: 16),
                      
                      // Product Grid
                      if (_isInitialLoad)
                        _buildSkeletonProductGrid(context, isDarkMode: isDarkMode)
                      else
                        _buildProductGrid(context, primaryColor, isDarkMode, cardColor, textColor, mutedTextColor),
                      
                      const SizedBox(height: 16),
                      
                      // Category Overview Card
                      if (_isInitialLoad)
                        _buildSkeletonCard(context, height: 150, isDarkMode: isDarkMode)
                      else
                        _buildCategoryOverview(context, primaryColor, cardColor, textColor, mutedTextColor, isMobile),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
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
                      child: const Row(
                        children: [
                          Icon(Icons.visibility, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
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
                                initialValue: currentSelectedCategory, // Use validated category
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
                                      )),
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
                  onPressed: () => _addProduct(),
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
          return _buildSkeletonProductGrid(context, isDarkMode: isDarkMode);
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
        
        // Get categories to use for filtering
        return StreamBuilder<List<ProductCategory>>(
          stream: CategoryService.getCategoriesByTypeStream('product'),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonProductGrid(context, isDarkMode: isDarkMode);
            }
            
            final categories = categorySnapshot.data ?? [];
            
            // Filter products
            final filteredProducts = allProducts.where((product) {
              // Find the category by name
              final category = categories.firstWhere(
                (c) => c.name == product.category,
                orElse: () => ProductCategory(id: '', name: '', type: 'product', createdAt: DateTime.now()),
              );
              
              final matchesCategory = _selectedCategory == 'All' || category.id == _selectedCategory;
              final matchesActive = _showInactive || product.isActive;
              final matchesSearch = _searchController.text.isEmpty ||
                  product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                  product.description.toLowerCase().contains(_searchController.text.toLowerCase());
              
              return matchesCategory && matchesActive && matchesSearch;
            }).toList();
            filteredProducts.sort((a, b) => a.name.compareTo(b.name));
            
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
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('Show Inactive Products'),
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
                          label: const Text('Showing Inactive'),
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          labelStyle: const TextStyle(color: Colors.orange),
                          avatar: const Icon(Icons.visibility, size: 16, color: Colors.orange),
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
                    return _buildSkeletonTableContent(context, isDarkMode: Theme.of(context).brightness == Brightness.dark, rowCount: 3);
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
                                final itemsCount = products.where((item) => item.category == category.id && item.isActive).length;
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
                                  .where((p) => p.category == category.name && p.isActive);
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

  // =========== SKELETON LOADING WIDGETS ===========

  Widget _buildSkeletonScreen(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.getScreenPadding(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
        ),
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton Stats Grid
              _buildSkeletonStatsGrid(context, isDarkMode: isDarkMode),
              const SizedBox(height: 16),
              
              // Skeleton Filter Card
              _buildSkeletonCard(context, height: 150, isDarkMode: isDarkMode),
              const SizedBox(height: 16),
              
              // Skeleton Action Row
              _buildSkeletonCard(context, height: 100, isDarkMode: isDarkMode),
              const SizedBox(height: 16),
              
              // Skeleton Product Grid
              _buildSkeletonProductGrid(context, isDarkMode: isDarkMode),
              const SizedBox(height: 16),
              
              // Skeleton Category Card
              _buildSkeletonCard(context, height: 150, isDarkMode: isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonStatsGrid(BuildContext context, {bool isDarkMode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 200,
            height: 24,
            margin: const EdgeInsets.only(bottom: 16),
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: List.generate(4, (index) => 
            _buildSkeletonStatCard(context, isDarkMode: isDarkMode)
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonStatCard(BuildContext context, {bool isDarkMode = false}) {
    return Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16) * 0.8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Container(
              width: Responsive.getIconSize(context, multiplier: 1.2),
              height: Responsive.getIconSize(context, multiplier: 1.2),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 16,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 80,
            height: 10,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getProductionFeasibility(Product product) async {
    final canProduce = product.hasAllIngredients;
    final missingIngredients = <String>[];
    double totalCost = 0.0;
    
    if (product.ingredients != null) {
      for (final ingredient in product.ingredients!) {
        totalCost += ingredient.totalCost;
        
        final inventoryItem = await InventoryService.getInventoryItem(ingredient.inventoryId);
        if (inventoryItem == null || inventoryItem.currentStock < ingredient.quantity) {
          missingIngredients.add(ingredient.inventoryName);
        }
      }
    }
    
    return {
      'canProduce': canProduce,
      'missingIngredients': missingIngredients,
      'totalCost': totalCost,
    };
  }

  Widget _buildSkeletonCard(BuildContext context, {double height = 150, bool isDarkMode = false}) {
    return Container(
      constraints: BoxConstraints(minHeight: height),
      child: Card(
        elevation: isDarkMode ? 2 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
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
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(3, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildSkeletonProductGrid(BuildContext context, {bool isDarkMode = false}) {
    final columnCount = _getGridColumnCount(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: Responsive.getPaddingSize(context),
        mainAxisSpacing: Responsive.getPaddingSize(context),
        childAspectRatio: _getCardAspectRatio(context),
      ),
      itemCount: columnCount * 2, // Show 2 rows of skeleton cards
      itemBuilder: (context, index) => _buildSkeletonProductCard(context, isDarkMode: isDarkMode),
    );
  }

  Widget _buildSkeletonProductCard(BuildContext context, {bool isDarkMode = false}) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final cardHeight = isMobile ? 180 : (isTablet ? 200 : 180);
    
    return SizedBox(
      height: cardHeight.toDouble(),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton Image
              Container(
                width: double.infinity,
                height: cardHeight * 0.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 6),
              
              // Skeleton Title
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              
              // Skeleton Price
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              
              // Skeleton Category and Stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Skeleton Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
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

  Widget _buildSkeletonTableContent(BuildContext context, {bool isDarkMode = false, int rowCount = 5}) {
    return Column(
      children: [
        // Skeleton Table Header
        Row(
          children: List.generate(4, (index) => Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
        ),
        const SizedBox(height: 12),
        // Skeleton Rows
        ...List.generate(rowCount, (rowIndex) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: List.generate(4, (colIndex) => Expanded(
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            )),
          ),
        )),
      ],
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
    
    // Adjusted heights for better fit
    final cardHeight = isMobile ? 200 : (isTablet ? 220 : 200); // Increased height
    final iconSize = isMobile ? 32.0 : (isTablet ? 36.0 : 32.0);
    final titleFontSize = isMobile ? 11.0 : (isTablet ? 13.0 : 12.0);
    final priceFontSize = isMobile ? 13.0 : (isTablet ? 15.0 : 14.0); // Slightly smaller price
    final cardPadding = isMobile ? 6.0 : 8.0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: cardHeight.toDouble(), // Set height on container instead of SizedBox
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
            // Image Container - FIXED: Reduced height percentage
            GestureDetector(
              onTap: () => _showProductDetails(product),
              child: Container(
                width: double.infinity,
                height: cardHeight * 0.45, // Reduced from 0.5 to 0.45
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
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
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
                              const Icon(Icons.warning, size: 10, color: Colors.white),
                              const SizedBox(width: 2),
                              Text(
                                '${product.stock}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!product.isActive)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(6),
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
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // NEW: Add inventory dependency indicator
                    if (product.dependsOnInventory)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory, size: 10, color: Colors.white),
                              SizedBox(width: 2),
                              Text(
                                'Auto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 4 : 6), // Reduced spacing
            
            // Product Name - FIXED: Better spacing
            Flexible(
              child: GestureDetector(
                onTap: () => _showProductDetails(product),
                child: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.2, // Reduced line height
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 2 : 4), // Reduced spacing
            
            // Price
            GestureDetector(
              onTap: () => _showProductDetails(product),
              child: Text(
                '₱${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: priceFontSize,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 4 : 6), // Reduced spacing
            
            // Category and Stock - FIXED: More compact layout
            GestureDetector(
              onTap: () => _showProductDetails(product),
              child: StreamBuilder<List<ProductCategory>>(
                stream: CategoryService.getCategoriesByTypeStream('product'),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];
                  
                  // Find category by name instead of ID
                  final category = categories.firstWhere(
                    (c) => c.name == product.category, // Compare by name
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
                            Icon(Icons.category, size: 9, color: isDarkMode ? Colors.grey.shade400 : Colors.grey),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                            size: 9,
                            color: product.needsReorder ? Colors.red : Colors.green,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.dependsOnInventory 
                                ? 'Auto'  // Show "Auto" for inventory-dependent products
                                : '${product.stock}',
                            style: TextStyle(
                              fontSize: 8,
                              color: product.needsReorder ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontStyle: product.dependsOnInventory ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const Spacer(), // Pushes buttons to bottom
            
            // Action buttons - FIXED: Smaller buttons with less padding
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _editProduct(product),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 3 : 4),
                      side: const BorderSide(color: Colors.blue, width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 3 : 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _toggleProductStatus(product),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 3 : 4),
                      side: BorderSide(
                        color: product.isActive ? Colors.orange : Colors.green,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    child: Text(
                      product.isActive ? 'Deactivate' : 'Activate',
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
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
    );
  }

  Widget _buildFallbackIcon(Product product, double iconSize, Color primaryColor, bool isDarkMode) {
    return StreamBuilder<List<ProductCategory>>(
      stream: CategoryService.getCategoriesByTypeStream('product'),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final category = categories.firstWhere(
          (c) => c.id == product.category,
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
          (c) => c.id == product.category,
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
    String? currentImage,
    Function(XFile?) onImageSelected,
    Function(String) onUrlChanged,
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    Color mutedTextColor,
    TextEditingController? urlController, // ADD THIS PARAMETER
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
        if (currentImage != null && currentImage.isNotEmpty)
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
                currentImage,
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
        
        // Image URL input - FIXED: Use controller instead of onChanged
        TextField(
          controller: urlController, // USE CONTROLLER
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
          onChanged: onUrlChanged, // STILL CALL onChanged
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
                    // Clear URL field when picking local image
                    if (urlController != null) {
                      urlController.clear();
                    }
                  }
                },
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final XFile? image = await ImageUploadService.takePicture();
                  if (image != null) {
                    onImageSelected(image);
                    // Clear URL field when taking photo
                    if (urlController != null) {
                      urlController.clear();
                    }
                  }
                },
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Camera'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        
        // Selected image preview
        if (_selectedImage != null)
          Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Selected Image:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
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
                      return const Center(child: CircularProgressIndicator());
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
                    return const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                },
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Remove Selected Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        final categoryProducts = products.where((p) => p.category == category.id && p.isActive);
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
    // Prevent opening multiple dialogs
    if (_isDialogOpen) return;
    
    _isDialogOpen = true;
    
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final primaryColor = getPrimaryColor();
      final textColor = isDarkMode ? Colors.white : Colors.black87;
      final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
      final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
      final isMobile = Responsive.isMobile(context);
      
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile 
                  ? MediaQuery.of(context).size.width * 0.95
                  : MediaQuery.of(context).size.width * 0.7,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.restaurant_menu, color: primaryColor, size: isMobile ? 20 : 24),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 16 : 20,
                              color: textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: isMobile ? 20 : 24),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image/Icon
                          Container(
                            width: double.infinity,
                            height: isMobile ? 150 : 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                            ),
                            child: product.image != null && product.image!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      product.image!,
                                      fit: BoxFit.contain,
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
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Basic Info
                          Text(
                            'PRODUCT INFORMATION',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: isMobile ? 8 : 12),
                          
                          // Details Grid
                          StreamBuilder<List<ProductCategory>>(
                            stream: CategoryService.getCategoriesByTypeStream('product'),
                            builder: (context, snapshot) {
                              final categories = snapshot.data ?? [];
                              final category = categories.firstWhere(
                                (c) => c.name == product.category, // Compare by name
                                orElse: () => ProductCategory(
                                  id: 'unknown',
                                  name: 'Unknown',
                                  type: 'product',
                                  createdAt: DateTime.now(),
                                ),
                              );
                              
                              final gridCrossAxisCount = isMobile ? 1 : 2;
                              final gridChildAspectRatio = isMobile ? 3.5 : 3.0; // Use double literals
                              
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: gridCrossAxisCount,
                                childAspectRatio: gridChildAspectRatio, // Now this is a double
                                crossAxisSpacing: isMobile ? 8 : 12,
                                mainAxisSpacing: isMobile ? 8 : 12,
                                children: [
                                  _buildDetailItem('Category', category.name, Icons.category, isMobile),
                                  _buildDetailItem('Price', '₱${product.price.toStringAsFixed(2)}', Icons.attach_money, isMobile),
                                  _buildDetailItem('Cost', '₱${product.cost.toStringAsFixed(2)}', Icons.price_change, isMobile),
                                  _buildDetailItem(
                                    'Stock', 
                                    product.dependsOnInventory ? 'Auto (from inventory)' : '${product.stock}', 
                                    Icons.inventory, 
                                    isMobile,
                                    subtitle: product.dependsOnInventory ? 'Calculated from available ingredients' : null,
                                  ),
                                  _buildDetailItem('Reorder Level', product.dependsOnInventory ? 'N/A' : '${product.reorderLevel}', Icons.warning, isMobile),
                                  _buildDetailItem('Unit', product.unit, Icons.scale, isMobile),
                                  _buildDetailItem(
                                    'Inventory Type', 
                                    product.dependsOnInventory ? 'Inventory-Dependent' : 'Independent', 
                                    product.dependsOnInventory ? Icons.inventory : Icons.store, 
                                    isMobile,
                                    color: product.dependsOnInventory ? Colors.blue : Colors.orange,
                                  ),
                                  _buildDetailItem(
                                    'Status', 
                                    product.isActive ? 'Active' : 'Inactive', 
                                    product.isActive ? Icons.check_circle : Icons.remove_circle,
                                    isMobile,
                                    color: product.isActive ? Colors.green : Colors.red,
                                  ),
                                  _buildDetailItem('Margin', '₱${product.margin.toStringAsFixed(2)}', Icons.trending_up, isMobile),
                                ],
                              );
                            },
                          ),
                          
                          SizedBox(height: isMobile ? 12 : 16),
                          
                          // Description
                          if (product.description.isNotEmpty) ...[
                            Text(
                              'DESCRIPTION',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: isMobile ? 4 : 8),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isMobile ? 8 : 12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.description,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: isMobile ? 13 : 14,
                                ),
                              ),
                            ),
                          ],
                          
                          // Ingredients Section
                          if (product.dependsOnInventory && product.ingredients != null && product.ingredients!.isNotEmpty) ...[
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'INGREDIENTS & PRODUCTION',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(height: isMobile ? 4 : 8),
                            
                            // Production Feasibility
                            FutureBuilder<Map<String, dynamic>>(
                              future: _getProductionFeasibility(product),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator(color: primaryColor));
                                }
                                
                                final data = snapshot.data ?? {
                                  'canProduce': false,
                                  'missingIngredients': [],
                                  'totalCost': 0.0,
                                };
                                final canProduce = data['canProduce'] as bool;
                                final missingIngredients = data['missingIngredients'] as List<String>;
                                final totalCost = data['totalCost'] as double;
                                
                                return Column(
                                  children: [
                                    // Production Status
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: canProduce 
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: canProduce ? Colors.green : Colors.orange,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            canProduce ? Icons.check_circle : Icons.warning,
                                            size: 16,
                                            color: canProduce ? Colors.green : Colors.orange,
                                          ),
                                          SizedBox(width: isMobile ? 8 : 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  canProduce 
                                                      ? 'Ready for Production'
                                                      : 'Cannot Produce Now',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: canProduce ? Colors.green : Colors.orange,
                                                    fontSize: isMobile ? 14 : 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  canProduce
                                                      ? 'All ingredients are available in stock'
                                                      : 'Some ingredients are insufficient',
                                                  style: TextStyle(
                                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                                    fontSize: isMobile ? 12 : 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    SizedBox(height: isMobile ? 8 : 12),
                                    
                                    // Ingredients List
                                    ...product.ingredients!.map((ingredient) {
                                      return FutureBuilder<InventoryItem?>(
                                        future: InventoryService.getInventoryItem(ingredient.inventoryId),
                                        builder: (context, snapshot) {
                                          final inventoryItem = snapshot.data;
                                          final availableStock = inventoryItem?.currentStock ?? 0;
                                          final isSufficient = availableStock >= ingredient.quantity;
                                          
                                          return Card(
                                            margin: EdgeInsets.only(bottom: isMobile ? 4 : 6),
                                            elevation: 1,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          ingredient.inventoryName,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor,
                                                            fontSize: isMobile ? 13 : 14,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${ingredient.quantity} ${ingredient.unit} × ₱${ingredient.unitCost}/${ingredient.unit}',
                                                          style: TextStyle(
                                                            color: mutedTextColor,
                                                            fontSize: isMobile ? 11 : 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '₱${ingredient.totalCost.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: isSufficient
                                                              ? Colors.green.withOpacity(0.1)
                                                              : Colors.red.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(
                                                            color: isSufficient ? Colors.green : Colors.red,
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '${availableStock.toStringAsFixed(1)} ${ingredient.unit}',
                                                          style: TextStyle(
                                                            color: isSufficient ? Colors.green : Colors.red,
                                                            fontSize: isMobile ? 10 : 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
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
                                    }),
                                    
                                    // Total Cost
                                    Card(
                                      elevation: 2,
                                      color: primaryColor.withOpacity(0.05),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total Ingredient Cost:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            Text(
                                              '₱${totalCost.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                                fontSize: isMobile ? 16 : 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Missing Ingredients Warning
                                    if (!canProduce && missingIngredients.isNotEmpty) ...[
                                      SizedBox(height: isMobile ? 8 : 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.warning, color: Colors.red, size: 16),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Missing Ingredients:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ...missingIngredients.map((ingredient) => Padding(
                                              padding: const EdgeInsets.only(left: 8, bottom: 4),
                                              child: Text(
                                                '• $ingredient',
                                                style: const TextStyle(color: Colors.red),
                                              ),
                                            )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                          
                          // Created/Updated info
                          SizedBox(height: isMobile ? 12 : 16),
                          Text(
                            'METADATA',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: isMobile ? 4 : 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Created:',
                                      style: TextStyle(
                                        fontSize: isMobile ? 11 : 12,
                                        color: mutedTextColor,
                                      ),
                                    ),
                                    Text(
                                      '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 13,
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
                                          fontSize: isMobile ? 11 : 12,
                                          color: mutedTextColor,
                                        ),
                                      ),
                                      Text(
                                        '${product.updatedAt!.day}/${product.updatedAt!.month}/${product.updatedAt!.year}',
                                        style: TextStyle(
                                          fontSize: isMobile ? 12 : 13,
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
                          SizedBox(height: isMobile ? 12 : 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // Footer buttons
                  Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 8 : 12,
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: TextStyle(fontSize: isMobile ? 13 : 14),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _editProduct(product);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 8 : 12,
                              ),
                            ),
                            child: Text(
                              'Edit Product',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _isDialogOpen = false;
    }
  }
  
  Widget _buildDetailItem(String label, String value, IconData icon, bool isMobile, {Color? color, String? subtitle}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: isMobile ? 16 : 18,
                color: color ?? primaryColor,
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct() async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    
    try {
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
      final TextEditingController imageController = TextEditingController();
      
      String selectedCategory = '';
      bool isActive = true;
      XFile? selectedImage;
      String image = '';
      
      // UPDATED: Add inventory dependency control
      bool dependsOnInventory = false;
      
      // ADD: Ingredients management
      List<ProductIngredient> ingredients = [];
      double totalIngredientCost = 0.0;
      bool hasInsufficientIngredients = false;
      List<String> insufficientIngredients = [];
      
      // FIX: Initialize categories immediately
      List<ProductCategory> categories = [];
      bool isCategoriesLoading = true;
      
      // Load categories
      final categoriesList = await CategoryService.getCategoriesByTypeStream('product').first;
      categories = categoriesList;
      isCategoriesLoading = false;
      
      if (categories.isNotEmpty) {
        selectedCategory = categories.first.id;
      }
      
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            // Function to calculate total ingredient cost
            void calculateTotalCost() {
              totalIngredientCost = ingredients.fold(0.0, (sum, ing) => sum + ing.totalCost);
              if (costController.text.isEmpty || double.tryParse(costController.text) == null) {
                costController.text = totalIngredientCost.toStringAsFixed(2);
              }
              setState(() {});
            }
            
            // Function to check ingredient availability
            Future<void> checkIngredientAvailability() async {
              hasInsufficientIngredients = false;
              insufficientIngredients.clear();
              
              for (final ingredient in ingredients) {
                final inventoryItem = await InventoryService.getInventoryItem(ingredient.inventoryId);
                if (inventoryItem == null || inventoryItem.currentStock < ingredient.quantity) {
                  hasInsufficientIngredients = true;
                  insufficientIngredients.add(ingredient.inventoryName);
                }
              }
              setState(() {});
            }
            
            // Initial check
            WidgetsBinding.instance.addPostFrameCallback((_) {
              calculateTotalCost();
              checkIngredientAvailability();
            });
            
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
                  width: Responsive.isMobile(context) ? double.infinity : 600, // Increased width
                  child: StreamBuilder<List<ProductCategory>>(
                    stream: CategoryService.getCategoriesByTypeStream('product'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || isCategoriesLoading) {
                        return _buildDialogSkeleton(context, isDarkMode: isDarkMode);
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
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _openCategoryManagement();
                                });
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
                          // Basic Information Section
                          _buildSectionHeader('BASIC INFORMATION', primaryColor),
                          const SizedBox(height: 12),
                          
                          // Image Upload Section
                          _buildImageUploadSection(
                            context,
                            null,
                            (image) {
                              setState(() {
                                selectedImage = image;
                                imageController.clear();
                              });
                            },
                            (url) {
                              setState(() {
                                image = url;
                                selectedImage = null;
                              });
                            },
                            isDarkMode,
                            primaryColor,
                            textColor,
                            mutedTextColor,
                            imageController,
                          ),
                          
                          const SizedBox(height: 12),
                          
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
                                return _buildDropdownSkeleton(isDarkMode);
                              }
                              
                              final categories = snapshot.data ?? [];
                              
                              return DropdownButtonFormField<String>(
                                initialValue: selectedCategory.isNotEmpty ? selectedCategory : null,
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
                          
                          const SizedBox(height: 16),
                          
                          // UPDATED: Inventory Dependency Checkbox
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: dependsOnInventory,
                                      onChanged: (value) {
                                        setState(() {
                                          dependsOnInventory = value ?? false;
                                          if (!dependsOnInventory) {
                                            // Clear ingredients if not depending on inventory
                                            ingredients.clear();
                                            calculateTotalCost();
                                          }
                                          // Reset stock controller if changing dependency
                                          if (dependsOnInventory) {
                                            stockController.text = '0';
                                          }
                                        });
                                      },
                                      activeColor: primaryColor,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Depends on Inventory',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            dependsOnInventory 
                                                ? 'Product stock will be calculated from inventory'
                                                : 'Product stock can be managed independently',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: mutedTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                if (!dependsOnInventory)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 32),
                                    child: Text(
                                      'For products like salads or ready-to-eat items that don\'t require inventory tracking',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mutedTextColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                                  onChanged: (_) => setState(() {}),
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
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // UPDATED: Stock and Reorder Level Row with conditional enabling
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: stockController,
                                  decoration: InputDecoration(
                                    labelText: dependsOnInventory ? 'Initial Stock (Not Used)' : 'Initial Stock *',
                                    labelStyle: TextStyle(color: mutedTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: primaryColor),
                                    ),
                                    prefixIcon: Icon(Icons.inventory, color: primaryColor),
                                    enabled: !dependsOnInventory, // Disable for inventory-dependent
                                    hintText: dependsOnInventory ? 'Auto-calculated' : 'Enter stock quantity',
                                  ),
                                  style: TextStyle(color: textColor),
                                  keyboardType: TextInputType.number,
                                  enabled: !dependsOnInventory, // Disable for inventory-dependent
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: reorderController,
                                  decoration: InputDecoration(
                                    labelText: dependsOnInventory ? 'Reorder Level (Not Used)' : 'Reorder Level',
                                    labelStyle: TextStyle(color: mutedTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: primaryColor),
                                    ),
                                    prefixIcon: Icon(Icons.warning, color: primaryColor),
                                    enabled: !dependsOnInventory, // Disable for inventory-dependent
                                    hintText: dependsOnInventory ? 'N/A for inventory items' : 'Low stock alert',
                                  ),
                                  style: TextStyle(color: textColor),
                                  keyboardType: TextInputType.number,
                                  enabled: !dependsOnInventory, // Disable for inventory-dependent
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
                          
                          // UPDATED: Show ingredients section only for inventory-dependent products
                          if (dependsOnInventory) ...[
                            const SizedBox(height: 20),
                            
                            // INGREDIENTS SECTION
                            _buildSectionHeader('INGREDIENTS & PRODUCTION', primaryColor),
                            const SizedBox(height: 12),
                            
                            // Cost Breakdown
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Cost Breakdown:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        '₱${totalIngredientCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Ingredients Cost:',
                                        style: TextStyle(color: mutedTextColor),
                                      ),
                                      Text(
                                        '₱${totalIngredientCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Other Costs:',
                                        style: TextStyle(color: mutedTextColor),
                                      ),
                                      Text(
                                        '₱${(double.tryParse(costController.text) ?? 0) - totalIngredientCost > 0 ? ((double.tryParse(costController.text) ?? 0) - totalIngredientCost).toStringAsFixed(2) : '0.00'}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(color: mutedTextColor.withOpacity(0.3)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Product Cost:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        '₱${(double.tryParse(costController.text) ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (priceController.text.isNotEmpty && double.tryParse(priceController.text) != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Profit Margin:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            '${((double.parse(priceController.text) - (double.tryParse(costController.text) ?? 0)) / (double.tryParse(costController.text) ?? 1) * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Inventory Status Warning
                            if (hasInsufficientIngredients && ingredients.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Insufficient Inventory',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Some ingredients have insufficient stock:',
                                      style: TextStyle(color: textColor),
                                    ),
                                    const SizedBox(height: 4),
                                    ...insufficientIngredients.map((ingredient) => Padding(
                                      padding: const EdgeInsets.only(left: 8, top: 2),
                                      child: Text(
                                        '• $ingredient',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    )),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'You may need to restock these items before production.',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            // Ingredients List
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ingredients (${ingredients.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await _showAddIngredientDialog(
                                          context,
                                          setState,
                                          ingredients,
                                          calculateTotalCost,
                                          checkIngredientAvailability,
                                          isDarkMode,
                                          primaryColor,
                                          textColor,
                                          mutedTextColor,
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Ingredient'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                if (ingredients.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.restaurant,
                                          size: 40,
                                          color: mutedTextColor,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No ingredients added yet',
                                          style: TextStyle(color: mutedTextColor),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add ingredients to calculate production cost',
                                          style: TextStyle(
                                            color: mutedTextColor,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...ingredients.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final ingredient = entry.value;
                                    return _buildIngredientCard(
                                      context,
                                      ingredient,
                                      index,
                                      ingredients,
                                      setState,
                                      calculateTotalCost,
                                      checkIngredientAvailability,
                                      isDarkMode,
                                      primaryColor,
                                      textColor,
                                      mutedTextColor,
                                    );
                                  }),
                              ],
                            ),
                          ],
                          
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
                      dependsOnInventory,
                      ingredients,
                    )) {
                      try {
                        setState(() => _isLoading = true);
                        
                        // Generate product ID
                        final productId = 'prod_${DateTime.now().millisecondsSinceEpoch}';
                        
                        // Upload image if selected
                        String? finalImage;
                        if (selectedImage != null) {
                          setState(() => _isUploadingImage = true);
                          try {
                            final imageBytes = await File(selectedImage!.path).readAsBytes();
                            final fileName = '${productId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                            finalImage = await ImageUploadService.uploadImage(
                              productId,
                              imageBytes,
                              fileName,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error uploading image: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => _isUploadingImage = false);
                            return;
                          }
                          setState(() => _isUploadingImage = false);
                        } else if (image.isNotEmpty) {
                          if (ImageUploadService.isValidimage(image)) {
                            finalImage = image;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid image URL'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }
                        
                        // UPDATED: Create product with dependsOnInventory field
                        final newProduct = Product(
                          id: productId,
                          name: nameController.text.trim(),
                          category: selectedCategory,
                          description: descriptionController.text.trim(),
                          price: double.parse(priceController.text),
                          cost: double.parse(costController.text),
                          stock: int.parse(stockController.text),
                          reorderLevel: int.parse(reorderController.text),
                          unit: unitController.text.trim(),
                          image: finalImage,
                          ingredients: dependsOnInventory ? ingredients : null, // Only store ingredients for inventory-dependent products
                          dependsOnInventory: dependsOnInventory, // ADD THIS
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
                      } finally {
                        setState(() => _isLoading = false);
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
    } finally {
      _isDialogOpen = false;
    }
  }
  
  Widget _buildDialogSkeleton(BuildContext context, {bool isDarkMode = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skeleton for image section
        Container(
          width: double.infinity,
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Skeleton for name field
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Skeleton for category dropdown
        Container(
          width: double.infinity,
          height: 56,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        // Skeleton for price and cost row
        Row(
          children: [
            Expanded(
              child: Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        
        // Skeleton for buttons
        Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDropdownSkeleton(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.category, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
  
  Future<void> _showAddIngredientDialog(
    BuildContext context,
    StateSetter setState,
    List<ProductIngredient> ingredients,
    VoidCallback calculateTotalCost,
    VoidCallback checkIngredientAvailability,
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    Color mutedTextColor,
  ) async {
    final TextEditingController quantityController = TextEditingController();
    String? selectedInventoryId;
    String? selectedInventoryName;
    double selectedUnitCost = 0.0;
    String selectedUnit = '';
    double availableStock = 0.0;
    
    List<InventoryItem> inventoryItems = [];
    
    // Load inventory items
    try {
      final itemsSnapshot = await InventoryService.inventoryCollection
          .where('active', isEqualTo: true)
          .get();
      
      inventoryItems = itemsSnapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading inventory items: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading inventory items: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            title: Text('Add Ingredient', style: TextStyle(color: textColor)),
            backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inventoryItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_outlined, size: 40, color: mutedTextColor),
                          const SizedBox(height: 12),
                          Text(
                            'No active inventory items found',
                            style: TextStyle(color: mutedTextColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please add inventory items first',
                            style: TextStyle(color: mutedTextColor, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        // Inventory Item Dropdown - FIXED VERSION
                        DropdownButtonFormField<String>(
                          initialValue: selectedInventoryId,
                          decoration: InputDecoration(
                            labelText: 'Inventory Item *',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory, color: primaryColor),
                          ),
                          items: inventoryItems.map((item) {
                            return DropdownMenuItem<String>(
                              value: item.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: TextStyle(color: textColor)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${item.currentStock} ${item.unit} | ₱${item.unitCost}/${item.unit}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              final selectedItem = inventoryItems.firstWhere(
                                (item) => item.id == value,
                                orElse: () => inventoryItems.first,
                              );
                              
                              dialogSetState(() {
                                selectedInventoryId = selectedItem.id;
                                selectedInventoryName = selectedItem.name;
                                selectedUnitCost = selectedItem.unitCost;
                                selectedUnit = selectedItem.unit;
                                availableStock = selectedItem.currentStock;
                              });
                            }
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Quantity Input
                        TextFormField(
                          controller: quantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantity Required *',
                            labelStyle: TextStyle(color: mutedTextColor),
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale, color: primaryColor),
                            suffixText: selectedUnit.isNotEmpty ? selectedUnit : '',
                            helperText: selectedInventoryId != null
                                ? 'Available: $availableStock $selectedUnit'
                                : null,
                            helperStyle: TextStyle(
                              color: selectedInventoryId != null && availableStock <= 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            dialogSetState(() {});
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Summary
                        if (selectedInventoryId != null && quantityController.text.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Summary:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Item:', style: TextStyle(color: mutedTextColor)),
                                    Text(selectedInventoryName!, style: TextStyle(color: textColor)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Quantity:', style: TextStyle(color: mutedTextColor)),
                                    Text('${quantityController.text} $selectedUnit',
                                        style: TextStyle(color: textColor)),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Unit Cost:', style: TextStyle(color: mutedTextColor)),
                                    Text('₱$selectedUnitCost/$selectedUnit',
                                        style: TextStyle(color: textColor)),
                                  ],
                                ),
                                Divider(color: mutedTextColor.withOpacity(0.3)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Cost:', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                    Text(
                                      '₱${(selectedUnitCost * (double.tryParse(quantityController.text) ?? 0)).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Stock Availability Warning
                                if (availableStock < (double.tryParse(quantityController.text) ?? 0))
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning, color: Colors.red, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Insufficient stock! Available: $availableStock $selectedUnit',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedInventoryId != null && quantityController.text.isNotEmpty
                    ? () {
                        final quantity = double.tryParse(quantityController.text) ?? 0;
                        if (quantity > 0) {
                          final ingredient = ProductIngredient(
                            inventoryId: selectedInventoryId!,
                            inventoryName: selectedInventoryName!,
                            quantity: quantity,
                            unit: selectedUnit,
                            unitCost: selectedUnitCost,
                          );
                          
                          ingredients.add(ingredient);
                          calculateTotalCost();
                          checkIngredientAvailability();
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid quantity'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIngredientCard(
    BuildContext context,
    ProductIngredient ingredient,
    int index,
    List<ProductIngredient> ingredients,
    StateSetter setState,
    VoidCallback calculateTotalCost,
    VoidCallback checkIngredientAvailability,
    bool isDarkMode,
    Color primaryColor,
    Color textColor,
    Color mutedTextColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        ingredient.inventoryName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ingredient.quantity} ${ingredient.unit} × ₱${ingredient.unitCost}/${ingredient.unit}',
                        style: TextStyle(
                          color: mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${ingredient.totalCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () {
                        ingredients.removeAt(index);
                        calculateTotalCost();
                        checkIngredientAvailability();
                        setState(() {});
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Stock Status (will be updated in real-time)
            FutureBuilder<InventoryItem?>(
              future: InventoryService.getInventoryItem(ingredient.inventoryId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  );
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  final inventoryItem = snapshot.data!;
                  final availableStock = inventoryItem.currentStock;
                  final isSufficient = availableStock >= ingredient.quantity;
                  final missingQuantity = ingredient.quantity - availableStock;
                  
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSufficient
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSufficient
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSufficient ? Icons.check_circle : Icons.warning,
                          size: 16,
                          color: isSufficient ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isSufficient
                                ? 'In Stock: ${availableStock.toStringAsFixed(2)} ${ingredient.unit} available'
                                : 'Low Stock: ${availableStock.toStringAsFixed(2)}/${ingredient.quantity} ${ingredient.unit} (${missingQuantity.toStringAsFixed(2)} ${ingredient.unit} needed)',
                            style: TextStyle(
                              color: isSufficient ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Inventory item not found',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProduct(Product product) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    
    try {
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
      final TextEditingController imageController = TextEditingController(text: product.image ?? '');
      
      String selectedCategory = await _getCategoryIdFromProduct(product);
      bool isActive = product.isActive;
      XFile? selectedImage;
      String image = product.image ?? '';
      
      // UPDATED: Add inventory dependency control
      bool dependsOnInventory = product.dependsOnInventory;

      // ADD: Ingredients management
      List<ProductIngredient> ingredients = product.ingredients ?? [];
      double totalIngredientCost = ingredients.fold(0.0, (sum, ing) => sum + ing.totalCost);
      bool hasInsufficientIngredients = false;
      List<String> insufficientIngredients = [];
      
      // NEW: Add skeleton loading state for initial category load
      bool isCategoriesLoading = true;
      
      // Load categories initially
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final categories = await CategoryService.getCategoriesByTypeStream('product').first;
        if (categories.isNotEmpty && mounted) {
          setState(() {
            isCategoriesLoading = false;
          });
        }
      });
      
      // Initial ingredient availability check
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        hasInsufficientIngredients = false;
        insufficientIngredients.clear();
        
        for (final ingredient in ingredients) {
          final inventoryItem = await InventoryService.getInventoryItem(ingredient.inventoryId);
          if (inventoryItem == null || inventoryItem.currentStock < ingredient.quantity) {
            hasInsufficientIngredients = true;
            insufficientIngredients.add(ingredient.inventoryName);
          }
        }
        if (mounted) setState(() {});
      });

      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            // Function to calculate total ingredient cost
            void calculateTotalCost() {
              totalIngredientCost = ingredients.fold(0.0, (sum, ing) => sum + ing.totalCost);
              setState(() {});
            }
            
            // Function to check ingredient availability
            Future<void> checkIngredientAvailability() async {
              hasInsufficientIngredients = false;
              insufficientIngredients.clear();
              
              for (final ingredient in ingredients) {
                final inventoryItem = await InventoryService.getInventoryItem(ingredient.inventoryId);
                if (inventoryItem == null || inventoryItem.currentStock < ingredient.quantity) {
                  hasInsufficientIngredients = true;
                  insufficientIngredients.add(ingredient.inventoryName);
                }
              }
              setState(() {});
            }

            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: primaryColor),
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
                  width: Responsive.isMobile(context) ? double.infinity : 600,
                  child: StreamBuilder<List<ProductCategory>>(
                    stream: CategoryService.getCategoriesByTypeStream('product'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || isCategoriesLoading) {
                        return _buildDialogSkeleton(context, isDarkMode: isDarkMode);
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
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _openCategoryManagement();
                                });
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
                            product.image,
                            (newImage) {
                              setState(() {
                                selectedImage = newImage;
                                // Clear image URL when selecting local image
                                imageController.clear();
                              });
                            },
                            (url) {
                              setState(() {
                                image = url;
                                // Clear local image when entering URL
                                selectedImage = null;
                              });
                            },
                            isDarkMode,
                            primaryColor,
                            textColor,
                            mutedTextColor,
                            imageController,
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
                                return _buildDropdownSkeleton(isDarkMode);
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
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          _openCategoryManagement();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                      child: const Text('Manage Categories'),
                                    ),
                                  ],
                                );
                              }
                              
                              // FIX: Convert product.category (which is category name) to category ID
                              // First, find the category by name (since product.category stores the name)
                              String currentCategoryId = '';
                              
                              // Try to find the category by name first (this is what product.category stores)
                              final categoryByName = categories.firstWhere(
                                (c) => c.name == product.category,
                                orElse: () => ProductCategory(
                                  id: '',
                                  name: '',
                                  type: 'product',
                                  createdAt: DateTime.now(),
                                ),
                              );
                              
                              if (categoryByName.id.isNotEmpty) {
                                currentCategoryId = categoryByName.id;
                              } else {
                                // If not found by name, try by ID (some products might store ID)
                                final categoryById = categories.firstWhere(
                                  (c) => c.id == product.categoryId,
                                  orElse: () => categories.isNotEmpty ? categories.first : ProductCategory(
                                    id: '',
                                    name: '',
                                    type: 'product',
                                    createdAt: DateTime.now(),
                                  ),
                                );
                                
                                currentCategoryId = categoryById.id.isNotEmpty ? categoryById.id : categories.first.id;
                              }
                              
                              // Update the selectedCategory variable
                              selectedCategory = currentCategoryId;
                              
                              return DropdownButtonFormField<String>(
                                initialValue: currentCategoryId,
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
                          
                          const SizedBox(height: 16),
                          
                          // UPDATED: Inventory Dependency Checkbox
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: dependsOnInventory,
                                      onChanged: (value) {
                                        setState(() {
                                          dependsOnInventory = value ?? false;
                                          if (!dependsOnInventory) {
                                            // Clear ingredients if not depending on inventory
                                            ingredients.clear();
                                            calculateTotalCost();
                                          }
                                          // Reset stock controller if changing dependency
                                          if (dependsOnInventory) {
                                            stockController.text = '0';
                                          }
                                        });
                                      },
                                      activeColor: primaryColor,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Depends on Inventory',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            dependsOnInventory 
                                                ? 'Product stock will be calculated from inventory'
                                                : 'Product stock can be managed independently',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: mutedTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                if (!dependsOnInventory)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 32),
                                    child: Text(
                                      'For products like salads or ready-to-eat items that don\'t require inventory tracking',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: mutedTextColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                          
                          // UPDATED: Stock and Reorder Level Row with conditional enabling
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: stockController,
                                  decoration: InputDecoration(
                                    labelText: dependsOnInventory ? 'Current Stock (Not Used)' : 'Current Stock *',
                                    labelStyle: TextStyle(color: mutedTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: primaryColor),
                                    ),
                                    prefixIcon: Icon(Icons.inventory, color: primaryColor),
                                    enabled: !dependsOnInventory, // Disable for inventory-dependent
                                    hintText: dependsOnInventory ? 'Auto-calculated' : 'Enter stock quantity',
                                  ),
                                  style: TextStyle(color: textColor),
                                  keyboardType: TextInputType.number,
                                  enabled: !dependsOnInventory, // Disable for inventory-dependent
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: reorderController,
                                  decoration: InputDecoration(
                                    labelText: dependsOnInventory ? 'Reorder Level (Not Used)' : 'Reorder Level',
                                    labelStyle: TextStyle(color: mutedTextColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: primaryColor),
                                    ),
                                    prefixIcon: Icon(Icons.warning, color: primaryColor),
                                    enabled: !dependsOnInventory, // Disable for inventory-dependent
                                    hintText: dependsOnInventory ? 'N/A for inventory items' : 'Low stock alert',
                                  ),
                                  style: TextStyle(color: textColor),
                                  keyboardType: TextInputType.number,
                                  enabled: !dependsOnInventory, // Disable for inventory-dependent
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
                          
                          // UPDATED: Show ingredients section only for inventory-dependent products
                          if (dependsOnInventory) ...[
                            const SizedBox(height: 20),
                            
                            // INGREDIENTS SECTION
                            _buildSectionHeader('INGREDIENTS & PRODUCTION', primaryColor),
                            const SizedBox(height: 12),
                            
                            // Cost Breakdown
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Cost Breakdown:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        '₱${totalIngredientCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Ingredients Cost:',
                                        style: TextStyle(color: mutedTextColor),
                                      ),
                                      Text(
                                        '₱${totalIngredientCost.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Other Costs:',
                                        style: TextStyle(color: mutedTextColor),
                                      ),
                                      Text(
                                        '₱${(double.tryParse(costController.text) ?? 0) - totalIngredientCost > 0 ? ((double.tryParse(costController.text) ?? 0) - totalIngredientCost).toStringAsFixed(2) : '0.00'}',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(color: mutedTextColor.withOpacity(0.3)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Product Cost:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        '₱${(double.tryParse(costController.text) ?? 0).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (priceController.text.isNotEmpty && double.tryParse(priceController.text) != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Profit Margin:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            '${((double.parse(priceController.text) - (double.tryParse(costController.text) ?? 0)) / (double.tryParse(costController.text) ?? 1) * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Inventory Status Warning
                            if (hasInsufficientIngredients && ingredients.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Insufficient Inventory',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Some ingredients have insufficient stock:',
                                      style: TextStyle(color: textColor),
                                    ),
                                    const SizedBox(height: 4),
                                    ...insufficientIngredients.map((ingredient) => Padding(
                                      padding: const EdgeInsets.only(left: 8, top: 2),
                                      child: Text(
                                        '• $ingredient',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    )),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'You may need to restock these items before production.',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: 12),
                            
                            // Ingredients List
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ingredients (${ingredients.length})',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await _showAddIngredientDialog(
                                          context,
                                          setState,
                                          ingredients,
                                          calculateTotalCost,
                                          checkIngredientAvailability,
                                          isDarkMode,
                                          primaryColor,
                                          textColor,
                                          mutedTextColor,
                                        );
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Ingredient'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                if (ingredients.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.restaurant,
                                          size: 40,
                                          color: mutedTextColor,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No ingredients added yet',
                                          style: TextStyle(color: mutedTextColor),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Add ingredients to calculate production cost',
                                          style: TextStyle(
                                            color: mutedTextColor,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ...ingredients.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final ingredient = entry.value;
                                    return _buildIngredientCard(
                                      context,
                                      ingredient,
                                      index,
                                      ingredients,
                                      setState,
                                      calculateTotalCost,
                                      checkIngredientAvailability,
                                      isDarkMode,
                                      primaryColor,
                                      textColor,
                                      mutedTextColor,
                                    );
                                  }),
                              ],
                            ),
                          ],
                          
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
                      dependsOnInventory,
                      ingredients,
                    )) {
                      try {
                        setState(() => _isLoading = true);
                        
                        // Upload image if selected
                        String? finalImage;
                        if (selectedImage != null) {
                          setState(() => _isUploadingImage = true);
                          try {
                            final imageBytes = await File(selectedImage!.path).readAsBytes();
                            final fileName = '${product.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
                            finalImage = await ImageUploadService.uploadImage(
                              product.id,
                              imageBytes,
                              fileName,
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error uploading image: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => _isUploadingImage = false);
                            return;
                          }
                          setState(() => _isUploadingImage = false);
                        } else if (image.isNotEmpty && image != product.image) {
                          // Only process URL if it's different from existing image
                          // Validate URL format
                          if (ImageUploadService.isValidimage(image)) {
                            finalImage = image;
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid image URL'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        } else if (image.isEmpty && product.image != null && product.image!.isNotEmpty) {
                          // Keep existing image if URL is cleared but product already has an image
                          finalImage = product.image;
                        }
                        
                        // Use product.copyWith to update the existing product
                        final categories = await CategoryService.getCategoriesByTypeStream('product').first;
                        final selectedCategoryObj = categories.firstWhere(
                          (c) => c.id == selectedCategory,
                          orElse: () => ProductCategory(
                            id: 'unknown',
                            name: 'Unknown',
                            type: 'product',
                            createdAt: DateTime.now(),
                          ),
                        );

                        final updatedProduct = product.copyWith(
                          name: nameController.text.trim(),
                          category: selectedCategoryObj.name, // Save category name
                          categoryId: selectedCategoryObj.id, // Save category ID
                          description: descriptionController.text.trim(),
                          price: double.parse(priceController.text),
                          cost: double.parse(costController.text),
                          stock: int.parse(stockController.text),
                          reorderLevel: int.parse(reorderController.text),
                          unit: unitController.text.trim(),
                          image: finalImage,
                          ingredients: dependsOnInventory ? ingredients : null, // Only store ingredients for inventory-dependent products
                          dependsOnInventory: dependsOnInventory, // ADD THIS
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
                      } finally {
                        setState(() => _isLoading = false);
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
                      : const Text('Update Product'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      _isDialogOpen = false;
    }
  }

  Future<Map<String, double>> _checkInventoryAvailability(List<ProductIngredient> ingredients) async {
    final Map<String, double> availability = {};
    
    for (final ingredient in ingredients) {
      final inventoryItem = await InventoryService.getInventoryItem(ingredient.inventoryId);
      if (inventoryItem != null) {
        availability[ingredient.inventoryId] = inventoryItem.currentStock;
      } else {
        availability[ingredient.inventoryId] = 0;
      }
    }
    
    return availability;
  }

  Future<String> _getCategoryIdFromProduct(Product product) async {
    final categories = await CategoryService.getCategoriesByTypeStream('product').first;
    
    // First try to find by name (since product.category stores name)
    final categoryByName = categories.firstWhere(
      (c) => c.name == product.category,
      orElse: () => ProductCategory(
        id: '',
        name: '',
        type: 'product',
        createdAt: DateTime.now(),
      ),
    );
    
    if (categoryByName.id.isNotEmpty) {
      return categoryByName.id;
    }
    
    // If not found by name, try by ID
    final categoryById = categories.firstWhere(
      (c) => c.id == product.categoryId,
      orElse: () => categories.isNotEmpty ? categories.first : ProductCategory(
        id: '',
        name: '',
        type: 'product',
        createdAt: DateTime.now(),
      ),
    );
    
    return categoryById.id;
  }

  Future<void> _toggleProductStatus(Product product) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final primaryColor = getPrimaryColor();
      final textColor = isDarkMode ? Colors.white : Colors.black87;
      
      bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
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
          setState(() => _isLoading = true);
          
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
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } finally {
      _isDialogOpen = false;
    }
  }

  // =========== VALIDATION METHODS ===========

  bool _validateProductForm(
    String name,
    String price,
    String cost,
    String stock,
    String category,
    bool dependsOnInventory, // ADD THIS PARAMETER
    List<ProductIngredient> ingredients, // ADD THIS PARAMETER
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
    
    if (!dependsOnInventory) {
      // For non-inventory products, validate stock
      if (stock.isEmpty || int.tryParse(stock) == null) {
        _showErrorSnackbar('Please enter a valid stock quantity');
        return false;
      }
    }
    
    if (dependsOnInventory && ingredients.isEmpty) {
      _showErrorSnackbar('Please add at least one ingredient for inventory-dependent products');
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