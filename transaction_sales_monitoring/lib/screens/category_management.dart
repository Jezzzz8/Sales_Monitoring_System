// lib/screens/category_management.dart - FIXED VERSION
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import '../utils/responsive.dart';

class CategoryManagement extends StatefulWidget {
  final String categoryType; // 'inventory' or 'product'
  
  const CategoryManagement({super.key, required this.categoryType});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  OverlayEntry? _overlayEntry;
  
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
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      if (hexColor.length == 8) {
        return Color(int.parse(hexColor, radix: 16));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }
  
  void _addCategory() {
    _removeOverlay();
    
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final displayOrderController = TextEditingController(text: '0');
    bool isActive = true;
    String selectedColor = '#2196F3';
    String selectedIcon = ''; // Add icon field
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.add_circle, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text('Add ${widget.categoryType == 'inventory' ? 'Inventory' : 'Product'} Category'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: displayOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Display Order',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  
                  // Icon Selection (You can replace this with an icon picker)
                  TextFormField(
                    controller: TextEditingController(text: selectedIcon),
                    onChanged: (value) {
                      selectedIcon = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Icon Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.emoji_objects),
                      hintText: 'pig, food, drink, etc.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Color Picker Section
                  Row(
                    children: [
                      const Icon(Icons.color_lens, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text('Color:'),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pick a color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: _parseColor(selectedColor),
                                  onColorChanged: (color) {
                                    setState(() {
                                      selectedColor = '#${color.value.toRadixString(16).substring(2)}';
                                    });
                                  },
                                  showLabel: true,
                                  pickerAreaHeightPercent: 0.8,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColor(selectedColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(text: selectedColor),
                          onChanged: (value) {
                            setState(() {
                              selectedColor = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Hex Color',
                            border: OutlineInputBorder(),
                            hintText: '#2196F3',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Checkbox(
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value ?? false;
                          });
                        },
                      ),
                      const Text('Active'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category name is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  final newCategory = ProductCategory(
                    id: '${widget.categoryType}_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    description: descriptionController.text,
                    type: widget.categoryType,
                    displayOrder: int.tryParse(displayOrderController.text) ?? 0,
                    isActive: isActive,
                    color: selectedColor,
                    icon: selectedIcon,
                    createdAt: DateTime.now(),
                  );
                  
                  try {
                    setState(() => _isLoading = true);
                    await CategoryService.addCategory(newCategory);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding category: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: const Text('ADD CATEGORY', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _editCategory(ProductCategory category) {
    _removeOverlay();
    
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final displayOrderController = TextEditingController(text: category.displayOrder.toString());
    bool isActive = category.isActive;
    String selectedColor = category.color;
    String selectedIcon = category.icon;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Category'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: displayOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Display Order',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  
                  // Icon Selection
                  TextFormField(
                    controller: TextEditingController(text: selectedIcon),
                    onChanged: (value) {
                      selectedIcon = value;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Icon Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.emoji_objects),
                      hintText: 'pig, food, drink, etc.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Color Picker Section
                  Row(
                    children: [
                      const Icon(Icons.color_lens, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      const Text('Color:'),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Pick a color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: _parseColor(selectedColor),
                                  onColorChanged: (color) {
                                    setState(() {
                                      selectedColor = '#${color.value.toRadixString(16).substring(2)}';
                                    });
                                  },
                                  showLabel: true,
                                  pickerAreaHeightPercent: 0.8,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _parseColor(selectedColor),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: TextEditingController(text: selectedColor),
                          onChanged: (value) {
                            setState(() {
                              selectedColor = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Hex Color',
                            border: OutlineInputBorder(),
                            hintText: '#2196F3',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Checkbox(
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value ?? false;
                          });
                        },
                      ),
                      const Text('Active'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category name is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  final updatedCategory = category.copyWith(
                    name: nameController.text,
                    description: descriptionController.text,
                    displayOrder: int.tryParse(displayOrderController.text) ?? 0,
                    isActive: isActive,
                    color: selectedColor,
                    icon: selectedIcon,
                    updatedAt: DateTime.now(),
                  );
                  
                  try {
                    setState(() => _isLoading = true);
                    await CategoryService.updateCategory(updatedCategory);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating category: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('UPDATE', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _toggleCategoryStatus(ProductCategory category) async {
    _removeOverlay();
    
    try {
      setState(() => _isLoading = true);
      
      // For toggling, we need to update the category with the opposite status
      final updatedCategory = category.copyWith(
        isActive: !category.isActive,
        updatedAt: DateTime.now(),
      );
      
      await CategoryService.updateCategory(updatedCategory);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category ${category.isActive ? 'deactivated' : 'activated'}'),
          backgroundColor: category.isActive ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling category status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // SKELETON LOADING WIDGETS
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
          padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  Widget _buildSkeletonTable(BuildContext context, {bool isDarkMode = false, int rowCount = 5}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 150),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 150,
                height: 24,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(rowCount, (rowIndex) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: List.generate(6, (colIndex) => Expanded(
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          if (isMobile)
            _buildMobileLayout(context, isDarkMode)
          else
            _buildDesktopLayout(context, isDarkMode),
          
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

  Widget _buildMobileLayout(BuildContext context, bool isDarkMode) {
    final padding = Responsive.getScreenPadding(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.categoryType == 'inventory' ? 'Inventory' : 'Product'} Categories',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCategory,
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: _buildContent(context, padding, true, isDarkMode),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDarkMode) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.categoryType == 'inventory' ? 'INVENTORY' : 'PRODUCT'} CATEGORY MANAGEMENT',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('ADD CATEGORY'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepOrange,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildContent(context, const EdgeInsets.all(24), false, isDarkMode),
    );
  }

  Widget _buildContent(BuildContext context, EdgeInsets padding, bool isMobile, bool isDarkMode) {
    return LayoutBuilder(
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
                if (isMobile)
                  Container(
                    constraints: const BoxConstraints(minHeight: 100),
                    child: Card(
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.categoryType == 'inventory' ? 'INVENTORY' : 'PRODUCT'} CATEGORY MANAGEMENT',
                              style: TextStyle(
                                fontSize: Responsive.getTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.categoryType == 'inventory' 
                                ? 'Manage categories for production inventory (meats, livestock, supplies)'
                                : 'Manage categories for POS products (menu items)',
                              style: TextStyle(
                                fontSize: Responsive.getBodyFontSize(context),
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
                
                if (isMobile) const SizedBox(height: 16),
                
                // Search and Filters
                if (_isInitialLoad)
                  _buildSkeletonCard(context, height: 150, isDarkMode: isDarkMode)
                else
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search categories...',
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
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: _addCategory,
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('ADD CATEGORY'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Show Inactive:'),
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return Checkbox(
                                    value: _showInactive,
                                    onChanged: (value) {
                                      setState(() {
                                        _showInactive = value ?? false;
                                      });
                                    },
                                  );
                                },
                              ),
                              if (isMobile) const Spacer(),
                              if (isMobile)
                                ElevatedButton.icon(
                                  onPressed: _addCategory,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('ADD'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Categories List - Using StreamBuilder for real-time updates
                if (_isInitialLoad)
                  _buildSkeletonTable(context, isDarkMode: isDarkMode, rowCount: 5)
                else
                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CATEGORIES',
                            style: TextStyle(
                              fontSize: Responsive.getTitleFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          StreamBuilder<List<ProductCategory>>(
                            stream: CategoryService.getCategoriesByTypeStream(widget.categoryType),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting && 
                                  !snapshot.hasData) {
                                return _buildSkeletonTableContent(context, isDarkMode: isDarkMode, rowCount: 3);
                              }
                              
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error loading categories: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                );
                              }
                              
                              final categories = snapshot.data ?? [];
                              
                              // Filter categories based on search and inactive toggle
                              final filteredCategories = categories.where((category) {
                                final matchesSearch = _searchController.text.isEmpty ||
                                    category.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                                    category.description.toLowerCase().contains(_searchController.text.toLowerCase());
                                final matchesActive = _showInactive || category.isActive;
                                
                                return matchesSearch && matchesActive;
                              }).toList()
                              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
                              
                              if (filteredCategories.isEmpty) {
                                return Container(
                                  constraints: const BoxConstraints(minHeight: 150),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 60,
                                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                        ),
                                        SizedBox(height: Responsive.getSpacing(context).height),
                                        Text(
                                          'No categories found',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              if (isMobile) {
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filteredCategories.length,
                                  itemBuilder: (context, index) {
                                    final category = filteredCategories[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: _parseColor(category.color),
                                          child: Text(
                                            category.icon.isNotEmpty 
                                                ? category.icon[0].toUpperCase()
                                                : category.name[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          category.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (category.description.isNotEmpty)
                                              Text(
                                                category.description,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            if (category.icon.isNotEmpty)
                                              Text(
                                                'Icon: ${category.icon}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Chip(
                                              label: Text(
                                                category.isActive ? 'Active' : 'Inactive',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                              backgroundColor: category.isActive
                                                  ? Colors.green.shade100
                                                  : Colors.grey.shade200,
                                              labelStyle: TextStyle(
                                                color: category.isActive ? Colors.green : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            ),
                                            PopupMenuButton<String>(
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 18, color: Colors.blue),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'toggle',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.toggle_on, size: 18, color: Colors.orange),
                                                      SizedBox(width: 8),
                                                      Text('Toggle Status'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _editCategory(category);
                                                } else if (value == 'toggle') {
                                                  _toggleCategoryStatus(category);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                // Desktop Table View
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 20,
                                    columns: const [
                                      DataColumn(label: Text('Category')),
                                      DataColumn(label: Text('Description')),
                                      DataColumn(label: Text('Icon')),
                                      DataColumn(label: Text('Display Order')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: filteredCategories.map((category) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                Container(
                                                  width: 24,
                                                  height: 24,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  decoration: BoxDecoration(
                                                    color: _parseColor(category.color),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.grey.shade300),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      category.icon.isNotEmpty 
                                                          ? category.icon[0].toUpperCase()
                                                          : category.name[0].toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  category.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 200,
                                              child: Text(
                                                category.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(category.icon.isNotEmpty ? category.icon : '-'),
                                          ),
                                          DataCell(Text('${category.displayOrder}')),
                                          DataCell(
                                            Chip(
                                              label: Text(
                                                category.isActive ? 'Active' : 'Inactive',
                                              ),
                                              backgroundColor: category.isActive
                                                  ? Colors.green.shade100
                                                  : Colors.grey.shade200,
                                              labelStyle: TextStyle(
                                                color: category.isActive ? Colors.green : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 18),
                                                  color: Colors.blue,
                                                  onPressed: () => _editCategory(category),
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    category.isActive ? Icons.toggle_on : Icons.toggle_off,
                                                    size: 18,
                                                  ),
                                                  color: category.isActive ? Colors.green : Colors.orange,
                                                  onPressed: () => _toggleCategoryStatus(category),
                                                  tooltip: category.isActive ? 'Deactivate' : 'Activate',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Category Type Info
                if (!_isInitialLoad)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.categoryType == 'inventory' 
                          ? Colors.blue.shade50 
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.categoryType == 'inventory' 
                            ? Colors.blue.shade100 
                            : Colors.orange.shade100,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.categoryType == 'inventory' 
                              ? Icons.pets 
                              : Icons.restaurant_menu,
                          color: widget.categoryType == 'inventory' 
                              ? Colors.blue 
                              : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.categoryType == 'inventory' 
                                    ? 'Inventory Categories' 
                                    : 'Product Categories',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.categoryType == 'inventory' 
                                      ? Colors.blue 
                                      : Colors.orange,
                                ),
                              ),
                              Text(
                                widget.categoryType == 'inventory'
                                    ? 'These are used for production inventory items like meats, livestock, and raw materials.'
                                    : 'These are used for POS product items that customers can purchase.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (!isMobile)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryManagement(
                                    categoryType: widget.categoryType == 'inventory' 
                                        ? 'product' 
                                        : 'inventory',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.categoryType == 'inventory' 
                                  ? Colors.orange 
                                  : Colors.blue,
                            ),
                            child: Text(
                              'Switch to ${widget.categoryType == 'inventory' ? 'Product' : 'Inventory'}',
                              style: const TextStyle(color: Colors.white),
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
  }

  Widget _buildSkeletonTableContent(BuildContext context, {bool isDarkMode = false, int rowCount = 5}) {
    return Column(
      children: [
        // Skeleton Rows
        ...List.generate(rowCount, (rowIndex) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                    ),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}