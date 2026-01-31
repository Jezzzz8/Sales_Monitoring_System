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
  late List<ProductCategory> _categories = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final categories = await CategoryService.getCategoriesByType(widget.categoryType);
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<ProductCategory> get _filteredCategories {
    return _categories.where((category) {
      final matchesSearch = _searchController.text.isEmpty ||
          category.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          category.description.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesActive = _showInactive || category.isActive;
      
      return matchesSearch && matchesActive;
    }).toList();
  }
  
  void _addCategory() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final displayOrderController = TextEditingController(text: '0');
    bool isActive = true;
    
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
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descriptionController.text,
                    type: widget.categoryType,
                    displayOrder: int.tryParse(displayOrderController.text) ?? 0,
                    isActive: isActive,
                    createdAt: DateTime.now(),
                  );
                  
                  await CategoryService.addCategory(newCategory);
                  await _loadCategories();
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final displayOrderController = TextEditingController(text: category.displayOrder.toString());
    bool isActive = category.isActive;
    
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
                    updatedAt: DateTime.now(),
                  );
                  
                  await CategoryService.updateCategory(updatedCategory);
                  await _loadCategories();
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
    await CategoryService.toggleCategoryStatus(category.id, category.type);
    await _loadCategories();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category ${category.isActive ? 'deactivated' : 'activated'}'),
        backgroundColor: category.isActive ? Colors.orange : Colors.green,
      ),
    );
  }
  
  void _deleteCategory(ProductCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              await CategoryService.deleteCategory(category.id, category.type);
              await _loadCategories();
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${category.name}" deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return _buildMobileLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
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
      body: _buildContent(context, padding, true),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
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
      body: _buildContent(context, EdgeInsets.all(24), false),
    );
  }

  Widget _buildContent(BuildContext context, EdgeInsets padding, bool isMobile) {
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
                            Checkbox(
                              value: _showInactive,
                              onChanged: (value) {
                                setState(() {
                                  _showInactive = value ?? false;
                                });
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
                
                // Categories List
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
                        
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (_filteredCategories.isEmpty)
                          Container(
                            constraints: const BoxConstraints(minHeight: 150),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No categories found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (isMobile)
                          // Mobile List View
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = _filteredCategories[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.deepOrange.shade50,
                                    child: Icon(
                                      Icons.category,
                                      color: Colors.deepOrange,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    category.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: category.description.isNotEmpty
                                      ? Text(
                                          category.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Chip(
                                        label: Text(
                                          category.isActive ? 'Active' : 'Inactive',
                                        ),
                                        backgroundColor: category.isActive
                                            ? Colors.green.shade100
                                            : Colors.grey.shade200,
                                        labelStyle: TextStyle(
                                          color: category.isActive ? Colors.green : Colors.grey,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                                          PopupMenuItem(
                                            value: 'toggle',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  category.isActive ? Icons.toggle_off : Icons.toggle_on,
                                                  size: 18,
                                                  color: category.isActive ? Colors.orange : Colors.green,
                                                ),
                                                SizedBox(width: 8),
                                                Text(category.isActive ? 'Deactivate' : 'Activate'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, size: 18, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete'),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _editCategory(category);
                                          } else if (value == 'toggle') {
                                            _toggleCategoryStatus(category);
                                          } else if (value == 'delete') {
                                            _deleteCategory(category);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          // Desktop Table View
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Description')),
                                DataColumn(label: Text('Type')),
                                DataColumn(label: Text('Display Order')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: _filteredCategories.map((category) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        category.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
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
                                      Chip(
                                        label: Text(
                                          category.type == 'inventory' ? 'Inventory' : 'Product',
                                        ),
                                        backgroundColor: category.type == 'inventory' 
                                            ? Colors.blue.shade100 
                                            : Colors.orange.shade100,
                                        labelStyle: TextStyle(
                                          color: category.type == 'inventory' 
                                              ? Colors.blue 
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                            color: category.isActive ? Colors.green : Colors.grey,
                                            onPressed: () => _toggleCategoryStatus(category),
                                            tooltip: category.isActive ? 'Deactivate' : 'Activate',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 18),
                                            color: Colors.red,
                                            onPressed: () => _deleteCategory(category),
                                            tooltip: 'Delete',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Category Type Info
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
}