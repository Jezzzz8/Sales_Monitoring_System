// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/responsive.dart';
import '../services/category_service.dart';
import '../screens/category_management.dart';
import '../utils/settings_mixin.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> with SettingsMixin {
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Whole Lechon (18-20kg)',
      categoryId: '5', // Whole Lechon category ID
      description: 'Traditional roasted pig, serves 30-40 persons',
      price: 6000,
      unit: 'piece',
      stock: 5,
      reorderLevel: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isActive: true,
    ),
    Product(
      id: '2',
      name: 'Whole Lechon (21-23kg)',
      categoryId: '5', // Whole Lechon category ID
      description: 'Traditional roasted pig, serves 40-50 persons',
      price: 7000,
      unit: 'piece',
      stock: 3,
      reorderLevel: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      isActive: true,
    ),
    Product(
      id: '3',
      name: 'Lechon Belly (3kg)',
      categoryId: '6', // Lechon Belly category ID
      description: 'Boneless lechon belly, serves 8-10 persons',
      price: 1800,
      unit: 'piece',
      stock: 10,
      reorderLevel: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      isActive: true,
    ),
    Product(
      id: '4',
      name: 'Lechon Belly (5kg)',
      categoryId: '6', // Lechon Belly category ID
      description: 'Boneless lechon belly, serves 12-15 persons',
      price: 2700,
      unit: 'piece',
      stock: 8,
      reorderLevel: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      isActive: true,
    ),
    Product(
      id: '7',
      name: 'Pork BBQ (10 sticks)',
      categoryId: '7', // Appetizers category ID
      description: 'Grilled pork barbecue sticks',
      price: 400,
      unit: 'pack',
      stock: 20,
      reorderLevel: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isActive: true,
    ),
    Product(
      id: '8',
      name: 'Dinakdakan',
      categoryId: '7', // Appetizers category ID
      description: 'Pork appetizer with special sauce',
      price: 1200,
      unit: 'tray',
      stock: 6,
      reorderLevel: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isActive: true,
    ),
    Product(
      id: '9',
      name: 'Leche Flan',
      categoryId: '8', // Desserts category ID
      description: 'Creamy caramel flan',
      price: 250,
      unit: 'slice',
      stock: 15,
      reorderLevel: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isActive: true,
    ),
    Product(
      id: '10',
      name: 'Carbonara Pasta',
      categoryId: '9', // Pastas category ID
      description: 'Creamy carbonara pasta',
      price: 300,
      unit: 'plate',
      stock: 12,
      reorderLevel: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isActive: true,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showInactive = false;
  bool _showFilters = false;
  String _sortColumn = 'name';
  bool _sortAscending = true;
  Map<String, String> _categoryNames = {}; // Store category names by ID
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategoryNames();
  }

  Future<void> _loadCategoryNames() async {
    setState(() {
      _loadingCategories = true;
    });
    
    try {
      // Load categories from service
      final categories = await CategoryService.getCategoriesByType('product');
      final Map<String, String> categoryMap = {};
      for (var category in categories) {
        categoryMap[category.id] = category.name;
      }
      
      setState(() {
        _categoryNames = categoryMap;
        _loadingCategories = false;
      });
    } catch (e) {
      // Fallback to hardcoded mapping if service fails
      final categoryMap = {
        '5': 'Whole Lechon',
        '6': 'Lechon Belly',
        '7': 'Appetizers',
        '8': 'Desserts',
        '9': 'Pastas',
      };
      
      setState(() {
        _categoryNames = categoryMap;
        _loadingCategories = false;
      });
    }
  }

  String _getCategoryName(String categoryId) {
    return _categoryNames[categoryId] ?? 'Unknown Category';
  }

  List<Product> get _filteredProducts {
    List<Product> filtered = _products.where((product) {
      final matchesCategory = _selectedCategory == 'All' || product.categoryId == _selectedCategory;
      final matchesActive = _showInactive || product.isActive;
      final matchesSearch = _searchController.text.isEmpty ||
          product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchController.text.toLowerCase());
      
      return matchesCategory && matchesActive && matchesSearch;
    }).toList();

    // Sort the filtered products
    filtered.sort((a, b) {
      int compare;
      switch (_sortColumn) {
        case 'name':
          compare = a.name.compareTo(b.name);
          break;
        case 'category':
          compare = _getCategoryName(a.categoryId).compareTo(_getCategoryName(b.categoryId));
          break;
        case 'price':
          compare = a.price.compareTo(b.price);
          break;
        case 'stock':
          compare = a.stock.compareTo(b.stock);
          break;
        case 'status':
          compare = a.isActive.toString().compareTo(b.isActive.toString());
          break;
        default:
          compare = a.name.compareTo(b.name);
      }
      return _sortAscending ? compare : -compare;
    });

    return filtered;
  }

  Set<String> get _categories {
    return _products.map((p) => p.categoryId).toSet();
  }

  void _showProductDetails(Product product) {
    final primaryColor = getPrimaryColor();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', _getCategoryName(product.categoryId)),
              _buildDetailRow('Description', product.description),
              _buildDetailRow('Price', '₱${product.price.toStringAsFixed(2)}'),
              _buildDetailRow('Unit', product.unit),
              _buildDetailRow('Current Stock', '${product.stock}'),
              _buildDetailRow('Reorder Level', '${product.reorderLevel}'),
              _buildDetailRow('Status', product.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', _formatDate(product.createdAt)),
              if (product.updatedAt != null)
                _buildDetailRow('Last Updated', _formatDate(product.updatedAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () => _editProduct(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text('EDIT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  void _addProduct() {
    // Create controllers for all fields
    final primaryColor = getPrimaryColor();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final unitController = TextEditingController();
    final stockController = TextEditingController();
    final reorderLevelController = TextEditingController();
    
    String? selectedCategory = _categories.isNotEmpty ? _categories.first : null;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_circle, color: primaryColor),
                const SizedBox(width: 8),
                const Text('Add New Product'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showImageOptions(
                        context,
                        isEditing: false,
                        onRemoveImage: null,
                      );
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Product Image',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '(Optional - Tap to add)',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant_menu),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(_getCategoryName(category)),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
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
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '₱',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      hintText: 'piece, kg, pack, etc.',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Initial Stock',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: reorderLevelController,
                          decoration: const InputDecoration(
                            labelText: 'Reorder Level',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.warning),
                          ),
                          keyboardType: TextInputType.number,
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
                      const Text('Active Product'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? Colors.green.shade200 : Colors.orange.shade200,
                          ),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product name is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedCategory == null || selectedCategory!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (priceController.text.isEmpty || double.tryParse(priceController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Valid price is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (unitController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unit is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newProduct = Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    categoryId: selectedCategory!,
                    description: descriptionController.text,
                    price: double.parse(priceController.text),
                    unit: unitController.text,
                    stock: int.tryParse(stockController.text) ?? 0,
                    reorderLevel: int.tryParse(reorderLevelController.text) ?? 0,
                    createdAt: DateTime.now(),
                    isActive: isActive,
                  );

                  setState(() {
                    _products.add(newProduct);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product added successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('ADD PRODUCT', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editProduct(Product product) {
    final nameController = TextEditingController(text: product.name);
    final categoryController = TextEditingController(text: product.categoryId);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final unitController = TextEditingController(text: product.unit);
    final stockController = TextEditingController(text: product.stock.toString());
    final reorderLevelController = TextEditingController(text: product.reorderLevel.toString());
    
    String selectedCategory = product.categoryId;
    bool isActive = product.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Product'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showImageOptions(
                        context,
                        isEditing: true,
                        onRemoveImage: () {
                          final index = _products.indexWhere((p) => p.id == product.id);
                          if (index != -1) {
                            final updatedProduct = Product(
                              id: product.id,
                              name: product.name,
                              categoryId: product.categoryId,
                              description: product.description,
                              price: product.price,
                              unit: product.unit,
                              stock: product.stock,
                              reorderLevel: product.reorderLevel,
                              createdAt: product.createdAt,
                              updatedAt: DateTime.now(),
                              isActive: product.isActive,
                              imageUrl: null,
                            );
                            
                            setState(() {
                              _products[index] = updatedProduct;
                            });
                            
                            Navigator.pop(context);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Image removed successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        image: product.imageUrl != null 
                            ? DecorationImage(
                                image: NetworkImage(product.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: product.imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Edit Product Image',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '(Optional - Tap to change)',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Change Image',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant_menu),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(_getCategoryName(category)),
                        )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
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
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      prefixText: '₱',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      hintText: 'piece, kg, pack, etc.',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: reorderLevelController,
                          decoration: const InputDecoration(
                            labelText: 'Reorder Level',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.warning),
                          ),
                          keyboardType: TextInputType.number,
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
                      const Text('Active Product'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive ? Colors.green.shade200 : Colors.orange.shade200,
                          ),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product name is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (priceController.text.isEmpty || double.tryParse(priceController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Valid price is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (unitController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unit is required'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final updatedProduct = Product(
                    id: product.id,
                    name: nameController.text,
                    categoryId: selectedCategory,
                    description: descriptionController.text,
                    price: double.parse(priceController.text),
                    unit: unitController.text,
                    stock: int.tryParse(stockController.text) ?? 0,
                    reorderLevel: int.tryParse(reorderLevelController.text) ?? 0,
                    createdAt: product.createdAt,
                    updatedAt: DateTime.now(),
                    isActive: isActive,
                    imageUrl: product.imageUrl,
                  );

                  final index = _products.indexWhere((p) => p.id == product.id);
                  if (index != -1) {
                    setState(() {
                      _products[index] = updatedProduct;
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product updated successfully'),
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

  void _showImageOptions(BuildContext context, {bool isEditing = false, VoidCallback? onRemoveImage}) {
    final primaryColor = getPrimaryColor();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEditing ? 'Edit Product Image' : 'Add Product Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an image from your device'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 
                        'Gallery access will be implemented for editing' : 
                        'Gallery access will be implemented for adding'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text('Take a Photo'),
                subtitle: const Text('Use your camera to capture an image'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? 
                        'Camera will be implemented for editing' : 
                        'Camera will be implemented for adding'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (isEditing && onRemoveImage != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Remove current product image'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Image'),
                        content: const Text('Are you sure you want to remove this product image?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('CANCEL'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onRemoveImage();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleProductStatus(Product product) {
    setState(() {
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = Product(
          id: product.id,
          name: product.name,
          categoryId: product.categoryId,
          description: product.description,
          price: product.price,
          unit: product.unit,
          stock: product.stock,
          reorderLevel: product.reorderLevel,
          createdAt: product.createdAt,
          updatedAt: DateTime.now(),
          isActive: !product.isActive,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product ${product.isActive ? 'deactivated' : 'activated'}'),
        backgroundColor: product.isActive ? Colors.orange : Colors.green,
      ),
    );
  }

  void _onSort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
  }

  void _openCategoryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryManagement(categoryType: 'product'),
      ),
    );
  }

  // Helper method to get grid column count based on screen size
  int _getGridColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 960) {
      return 3; // Tablet
    } else if (screenWidth < 1280) {
      return 4; // Small desktop
    } else {
      return 5; // Large desktop
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if settings are still loading
    if (isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
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
                  Responsive.buildResponsiveCardGrid(
                    context: context,
                    title: 'PRODUCT OVERVIEW',
                    titleColor: primaryColor,
                    centerTitle: true,
                    cards: [
                      _buildStatCard(
                        'Total Products',
                        '${_products.length}',
                        Icons.restaurant_menu,
                        Colors.blue,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'All menu items',
                      ),
                      _buildStatCard(
                        'Active Products',
                        '${_products.where((p) => p.isActive).length}',
                        Icons.check_circle,
                        Colors.green,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'Available for sale',
                      ),
                      _buildStatCard(
                        'Categories',
                        '${_categories.length}',
                        Icons.category,
                        Colors.orange,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'Menu categories',
                      ),
                      _buildStatCard(
                        'Low Stock',
                        '${_products.where((p) => p.needsReorder).length}',
                        Icons.warning,
                        Colors.red,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'Need reorder',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Filter Options Card
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
                                          child: DropdownButtonFormField<String>(
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
                                            items: ['All', ..._categories]
                                                .map((category) => DropdownMenuItem(
                                                      value: category,
                                                      child: Text(_getCategoryName(category), style: TextStyle(color: textColor)),
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
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Row(
                                            children: [
                                              Checkbox(
                                                value: _showInactive,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _showInactive = value ?? false;
                                                  });
                                                },
                                              ),
                                              Text(
                                                'Show Inactive',
                                                style: TextStyle(color: textColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
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
                                          items: ['All', ..._categories]
                                              .map((category) => DropdownMenuItem(
                                                    value: category,
                                                    child: Text(_getCategoryName(category), style: TextStyle(color: textColor)),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCategory = value!;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _showInactive,
                                              onChanged: (value) {
                                                setState(() {
                                                  _showInactive = value ?? false;
                                                });
                                              },
                                            ),
                                            Text(
                                              'Show Inactive',
                                              style: TextStyle(color: textColor),
                                            ),
                                          ],
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
                  ),

                  const SizedBox(height: 16),

                  // Sort and Add Product Row
                  Card(
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
                                if (!isMobile) ...[
                                  const SizedBox(width: 16),
                                  DropdownButton<String>(
                                    value: _sortColumn,
                                    underline: Container(height: 0),
                                    style: TextStyle(color: textColor, fontSize: 14),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _onSort(value, _sortAscending);
                                      }
                                    },
                                    items: [
                                      DropdownMenuItem(
                                        value: 'name',
                                        child: Row(
                                          children: [
                                            Icon(Icons.sort_by_alpha, size: 16),
                                            const SizedBox(width: 8),
                                            const Text('Sort by Name'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'category',
                                        child: Row(
                                          children: [
                                            Icon(Icons.category, size: 16),
                                            const SizedBox(width: 8),
                                            const Text('Sort by Category'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'price',
                                        child: Row(
                                          children: [
                                            Icon(Icons.attach_money, size: 16),
                                            const SizedBox(width: 8),
                                            const Text('Sort by Price'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'stock',
                                        child: Row(
                                          children: [
                                            Icon(Icons.inventory, size: 16),
                                            const SizedBox(width: 8),
                                            const Text('Sort by Stock'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                      size: 16,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _sortAscending = !_sortAscending;
                                        _onSort(_sortColumn, _sortAscending);
                                      });
                                    },
                                  ),
                                ],
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
                  ),

                  const SizedBox(height: 16),

                  // Product Grid - ALWAYS CARDS, NO TABLE
                  if (_filteredProducts.isEmpty)
                    Container(
                      constraints: BoxConstraints(
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
                                  'Try adjusting your filters or add a new product',
                                  style: TextStyle(
                                    fontSize: Responsive.getBodyFontSize(context) * 0.9,
                                    color: mutedTextColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getGridColumnCount(context),
                        crossAxisSpacing: Responsive.getPaddingSize(context),
                        mainAxisSpacing: Responsive.getPaddingSize(context),
                        childAspectRatio: _getCardAspectRatio(context), // NEW: Dynamic aspect ratio
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index], context, 
                        isDarkMode: isDarkMode),
                    ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

                  // Pricing Guidelines Card
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 150,
                    ),
                    child: Card(
                      elevation: isDarkMode ? 2 : 3,
                      color: Colors.blue.shade50.withOpacity(isDarkMode ? 0.2 : 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300,
                          width: 1.5,
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
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.price_change, color: Colors.blue, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'PRICING GUIDELINES',
                                    style: TextStyle(
                                      fontSize: Responsive.getSubtitleFontSize(context),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Responsive.getSpacing(context).height),
                            _buildGuidelineItem(
                              'Review and update prices quarterly',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
                            ),
                            _buildGuidelineItem(
                              'Consider ingredient cost changes when adjusting prices',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
                            ),
                            _buildGuidelineItem(
                              'Maintain consistent pricing across similar products',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
                            ),
                            _buildGuidelineItem(
                              'Update menu display when prices change',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

                  // Category Overview Card
                  Container(
                    constraints: BoxConstraints(
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
                            if (_loadingCategories)
                              Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                ),
                              )
                            else if (isMobile)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories.elementAt(index);
                                  return _buildCategorySummaryMobile(category, context, isDarkMode: isDarkMode);
                                },
                              )
                            else
                              DataTable(
                                headingRowHeight: Responsive.getDataTableRowHeight(context),
                                dataRowHeight: Responsive.getDataTableRowHeight(context),
                                headingTextStyle: TextStyle(
                                  fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor, // Use the primaryColor from settings
                                ),
                                columns: const [
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Products')),
                                  DataColumn(label: Text('Average Price')),
                                  DataColumn(label: Text('Total Stock')),
                                ],
                                rows: _categories.map((category) {
                                  final categoryProducts = _products
                                      .where((p) => p.categoryId == category && p.isActive);
                                  final avgPrice = categoryProducts.isEmpty
                                      ? 0
                                      : categoryProducts.fold(0.0, (sum, p) => sum + p.price) /
                                          categoryProducts.length;
                                  final totalStock = categoryProducts.fold(
                                      0, (sum, p) => sum + p.stock);
                                  
                                  return DataRow(cells: [
                                    DataCell(
                                      Text(
                                        _getCategoryName(category),
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

  double _getCardAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 0.65; // Mobile: taller cards
    } else if (screenWidth < 960) {
      return 0.7; // Tablet
    } else if (screenWidth < 1280) {
      return 0.75; // Small desktop
    } else {
      return 0.8; // Large desktop
    }
  }

  Widget _buildProductCard(Product product, BuildContext context, {bool isDarkMode = false}) {
    final primaryColor = getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    
    // Calculate responsive values - MATCHING POS SYSTEM
    final cardHeight = isMobile ? 180 : (isTablet ? 200 : 180);
    final iconSize = isMobile ? 32.0 : (isTablet ? 36.0 : 32.0);
    final titleFontSize = isMobile ? 11.0 : (isTablet ? 13.0 : 12.0);
    final priceFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 14.0);
    final cardPadding = isMobile ? 6.0 : 8.0;
    
    return SizedBox(
      height: cardHeight.toDouble(),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                // Square Image Container - FIXED ASPECT RATIO
                Container(
                  width: double.infinity,
                  height: cardHeight * 0.5, // Fixed height for square-ish shape
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              Colors.grey.shade700,
                              Colors.grey.shade800,
                            ]
                          : [
                              primaryColor.withOpacity(0.05),
                              primaryColor.withOpacity(0.1),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _getProductIcon(product.categoryId),
                          color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                          size: iconSize,
                        ),
                      ),
                      // Badges
                      if (product.stock < product.reorderLevel)
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
                                Icon(
                                  Icons.warning,
                                  size: 12,
                                  color: Colors.white,
                                ),
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
                
                // Category and Stock info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 10,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              _getCategoryName(product.categoryId),
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
                          side: BorderSide(color: Colors.blue, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
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

  IconData _getProductIcon(String categoryId) {
    final categoryName = _getCategoryName(categoryId);
    switch (categoryName) {
      case 'Whole Lechon':
        return Icons.celebration;
      case 'Lechon Belly':
        return Icons.restaurant_menu;
      case 'Appetizers':
        return Icons.fastfood;
      case 'Desserts':
        return Icons.cake;
      case 'Pastas':
        return Icons.restaurant;
      default:
        return Icons.fastfood;
    }
  }

  Widget _buildCategorySummaryMobile(String category, BuildContext context, {bool isDarkMode = false}) {
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    final categoryProducts = _products
        .where((p) => p.categoryId == category && p.isActive);
    final avgPrice = categoryProducts.isEmpty
        ? 0
        : categoryProducts.fold(0.0, (sum, p) => sum + p.price) /
            categoryProducts.length;
    final totalStock = categoryProducts.fold(
        0, (sum, p) => sum + p.stock);
    
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.getPaddingSize(context)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: Responsive.getCardPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getCategoryName(category),
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
                        '${categoryProducts.length}',
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
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context, 
    {bool isDarkMode = false, String? subtitle}) {
    final primaryColor = getPrimaryColor(); // ADD THIS LINE
    
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

  Widget _buildGuidelineItem(String text, BuildContext context, {
    bool isDarkMode = false,
    Color iconColor = Colors.blue,
  }) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.getFontSize(context, mobile: 4, tablet: 5, desktop: 6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, 
              size: Responsive.getIconSize(context, multiplier: 0.8), 
              color: iconColor),
          SizedBox(width: Responsive.getHorizontalSpacing(context).width),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: Responsive.getBodyFontSize(context) * 0.95,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}