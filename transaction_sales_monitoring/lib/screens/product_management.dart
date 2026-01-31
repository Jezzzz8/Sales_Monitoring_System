// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/responsive.dart';
import '../services/category_service.dart';
import '../screens/category_management.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
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
              backgroundColor: Colors.deepOrange,
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
            title: const Row(
              children: [
                Icon(Icons.add_circle, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text('Add New Product'),
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
                  backgroundColor: Colors.deepOrange,
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
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

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final padding = Responsive.getScreenPadding(context);

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
                              'PRODUCT MANAGEMENT',
                              style: TextStyle(
                                fontSize: Responsive.getTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage menu items, prices, and product information',
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
                                  'Total Products',
                                  '${_products.length}',
                                  Icons.restaurant_menu,
                                  Colors.blue,
                                  context,
                                ),
                                _buildStatCard(
                                  'Active Products',
                                  '${_products.where((p) => p.isActive).length}',
                                  Icons.check_circle,
                                  Colors.green,
                                  context,
                                ),
                                _buildStatCard(
                                  'Categories',
                                  '${_categories.length}',
                                  Icons.category,
                                  Colors.orange,
                                  context,
                                ),
                                _buildStatCard(
                                  'Low Stock',
                                  '${_products.where((p) => p.needsReorder).length}',
                                  Icons.warning,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'FILTERS',
                                  style: TextStyle(
                                    fontSize: Responsive.getSubtitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                if (isMobile)
                                  IconButton(
                                    icon: Icon(
                                      _showFilters ? Icons.filter_list_off : Icons.filter_list,
                                      color: Colors.deepOrange,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showFilters = !_showFilters;
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search products by name or description...',
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
                            if ((!isMobile || _showFilters))
                              Column(
                                children: [
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedCategory,
                                          decoration: const InputDecoration(
                                            labelText: 'Category',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: ['All', ..._categories]
                                              .map((category) => DropdownMenuItem(
                                                    value: category,
                                                    child: Text(_getCategoryName(category)),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCategory = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      if (!isMobile) const SizedBox(width: 16),
                                      if (!isMobile)
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
                                              const Text('Show Inactive'),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (isMobile)
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
                                        const Text('Show Inactive'),
                                      ],
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
                                  'PRODUCT LIST',
                                  style: TextStyle(
                                    fontSize: Responsive.getTitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Responsive.getOrientationFlexLayout(
                                  context,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _openCategoryManagement,
                                      icon: const Icon(Icons.category, size: 16),
                                      label: const Text('MANAGE CATEGORIES'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                          vertical: Responsive.getButtonHeight(context) * 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addProduct,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('ADD PRODUCT'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                          vertical: Responsive.getButtonHeight(context) * 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            if (_filteredProducts.isEmpty)
                              Container(
                                constraints: BoxConstraints(
                                  minHeight: 150,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restaurant_menu_outlined,
                                        size: Responsive.getIconSize(context, multiplier: 2.5),
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: Responsive.getSpacing(context).height),
                                      Text(
                                        'No products found',
                                        style: TextStyle(
                                          fontSize: Responsive.getBodyFontSize(context),
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (isDesktop)
                            Container(
                              constraints: BoxConstraints(
                                minHeight: 150,
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: MediaQuery.of(context).size.width - Responsive.getPaddingSize(context) * 2,
                                  ),
                                  child: DataTable(
                                    headingRowHeight: Responsive.getDataTableRowHeight(context),
                                    dataRowHeight: Responsive.getDataTableRowHeight(context),
                                    columns: [
                                      DataColumn(
                                        label: const Text('Product'),
                                        onSort: (columnIndex, ascending) => _onSort('name', ascending),
                                      ),
                                      DataColumn(
                                        label: const Text('Category'),
                                        onSort: (columnIndex, ascending) => _onSort('category', ascending),
                                      ),
                                      DataColumn(
                                        label: const Text('Price'),
                                        onSort: (columnIndex, ascending) => _onSort('price', ascending),
                                      ),
                                      DataColumn(
                                        label: const Text('Stock'),
                                        onSort: (columnIndex, ascending) => _onSort('stock', ascending),
                                      ),
                                      DataColumn(
                                        label: const Text('Status'),
                                        onSort: (columnIndex, ascending) => _onSort('status', ascending),
                                      ),
                                      const DataColumn(label: Text('Actions')),
                                    ],
                                    rows: _filteredProducts.map((product) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Container(
                                              constraints: BoxConstraints(maxWidth: Responsive.width(context) * 0.15),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    product.description,
                                                    style: TextStyle(fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12), color: Colors.grey),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: Responsive.getFontSize(context, mobile: 6, tablet: 8, desktop: 10),
                                                vertical: Responsive.getFontSize(context, mobile: 3, tablet: 4, desktop: 5),
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getCategoryColor(product.categoryId).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: _getCategoryColor(product.categoryId).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                _getCategoryName(product.categoryId),
                                                style: TextStyle(
                                                  fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                  fontWeight: FontWeight.bold,
                                                  color: _getCategoryColor(product.categoryId),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '₱${product.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.deepOrange,
                                                  ),
                                                ),
                                                Text(
                                                  'per ${product.unit}',
                                                  style: TextStyle(fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12), color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${product.stock}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: product.needsReorder ? Colors.red : Colors.green,
                                                  ),
                                                ),
                                                Text(
                                                  'Reorder: ${product.reorderLevel}',
                                                  style: TextStyle(fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12), color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Chip(
                                              label: Text(
                                                product.isActive ? 'Active' : 'Inactive',
                                                style: TextStyle(fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13)),
                                              ),
                                              backgroundColor: product.isActive
                                                  ? Colors.green.shade100
                                                  : Colors.grey.shade200,
                                              labelStyle: TextStyle(
                                                color: product.isActive ? Colors.green : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, size: Responsive.getIconSize(context, multiplier: 0.8)),
                                                  color: Colors.blue,
                                                  onPressed: () => _editProduct(product),
                                                  tooltip: 'Edit',
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    product.isActive ? Icons.toggle_on : Icons.toggle_off,
                                                    size: Responsive.getIconSize(context, multiplier: 0.8),
                                                  ),
                                                  color: product.isActive ? Colors.green : Colors.grey,
                                                  onPressed: () => _toggleProductStatus(product),
                                                  tooltip: product.isActive ? 'Deactivate' : 'Activate',
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, size: Responsive.getIconSize(context, multiplier: 0.8)),
                                                  color: Colors.red,
                                                  onPressed: () {
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Delete Product'),
                                                        content: Text('Are you sure you want to delete "${product.name}"?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('CANCEL'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              setState(() {
                                                                _products.removeWhere((p) => p.id == product.id);
                                                              });
                                                              Navigator.pop(context);
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text('"${product.name}" deleted successfully'),
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
                                                  },
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
                              ),
                            )
                            else if (isTablet)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: Responsive.getPaddingSize(context),
                                  mainAxisSpacing: Responsive.getPaddingSize(context),
                                  childAspectRatio: Responsive.getCardAspectRatio(context),
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index], context, isTablet: true),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index], context, isTablet: false),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

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
                                Icon(Icons.price_change, color: Colors.blue, size: Responsive.getIconSize(context, multiplier: 1.2)),
                                SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                                Text(
                                  'PRICING GUIDELINES',
                                  style: TextStyle(
                                    fontSize: Responsive.getSubtitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Responsive.getSpacing(context).height),
                            _buildGuidelineItem(
                              'Review and update prices quarterly',
                              context,
                            ),
                            _buildGuidelineItem(
                              'Consider ingredient cost changes when adjusting prices',
                              context,
                            ),
                            _buildGuidelineItem(
                              'Maintain consistent pricing across similar products',
                              context,
                            ),
                            _buildGuidelineItem(
                              'Update menu display when prices change',
                              context,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

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
                              'CATEGORY OVERVIEW',
                              style: TextStyle(
                                fontSize: Responsive.getTitleFontSize(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: Responsive.getSpacing(context).height),
                            if (_loadingCategories)
                              Center(
                                child: CircularProgressIndicator(
                                  color: Colors.deepOrange,
                                ),
                              )
                            else if (isMobile)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _categories.length,
                                itemBuilder: (context, index) {
                                  final category = _categories.elementAt(index);
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
                                            ),
                                          ),
                                          SizedBox(height: Responsive.getSmallSpacing(context).height),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Products:',
                                                    style: TextStyle(
                                                      fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${categoryProducts.length}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Avg Price:',
                                                    style: TextStyle(
                                                      fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    '₱${avgPrice.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Total Stock:',
                                                    style: TextStyle(
                                                      fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$totalStock',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
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
                            else
                              DataTable(
                                headingRowHeight: Responsive.getDataTableRowHeight(context),
                                dataRowHeight: Responsive.getDataTableRowHeight(context),
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
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataCell(Text('${categoryProducts.length}')),
                                    DataCell(Text('₱${avgPrice.toStringAsFixed(2)}')),
                                    DataCell(Text('$totalStock')),
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

  Widget _buildProductCard(Product product, BuildContext context, {bool isTablet = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: isTablet ? 0 : Responsive.getPaddingSize(context)),
      child: InkWell(
        onTap: () => _showProductDetails(product),
        child: Padding(
          padding: Responsive.getCardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getFontSize(context, mobile: 6, tablet: 8, desktop: 10),
                      vertical: Responsive.getFontSize(context, mobile: 3, tablet: 4, desktop: 5),
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(product.categoryId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getCategoryColor(product.categoryId).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getCategoryName(product.categoryId),
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(product.categoryId),
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      product.isActive ? 'Active' : 'Inactive',
                    ),
                    backgroundColor: product.isActive
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: product.isActive ? Colors.green : Colors.grey,
                      fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.getSubtitleFontSize(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              Text(
                product.description,
                style: TextStyle(
                  fontSize: Responsive.getBodyFontSize(context),
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: Responsive.getSpacing(context).height),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₱${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                          color: Colors.deepOrange,
                        ),
                      ),
                      Text(
                        'per ${product.unit}',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                          fontWeight: FontWeight.bold,
                          color: product.needsReorder
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      Text(
                        'Reorder: ${product.reorderLevel}',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: Responsive.getSpacing(context).height),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editProduct(product),
                      icon: Icon(Icons.edit, size: Responsive.getIconSize(context, multiplier: 0.6)),
                      label: Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: Responsive.getButtonHeight(context) * 0.3),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.getHorizontalSpacing(context).width),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleProductStatus(product),
                      icon: Icon(
                        product.isActive ? Icons.toggle_on : Icons.toggle_off,
                        size: Responsive.getIconSize(context, multiplier: 0.6),
                      ),
                      label: Text(product.isActive ? 'Deactivate' : 'Activate'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: Responsive.getButtonHeight(context) * 0.3),
                        side: BorderSide(
                          color: product.isActive ? Colors.orange : Colors.green,
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
    );
  }

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
          SizedBox(width: Responsive.getHorizontalSpacing(context).width),
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

  Widget _buildGuidelineItem(String text, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Responsive.getFontSize(context, mobile: 4, tablet: 5, desktop: 6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: Responsive.getIconSize(context, multiplier: 0.8), color: Colors.blue),
          SizedBox(width: Responsive.getHorizontalSpacing(context).width),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: Responsive.getBodyFontSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryId) {
    final categoryName = _getCategoryName(categoryId);
    switch (categoryName) {
      case 'Whole Lechon':
        return Colors.deepOrange;
      case 'Lechon Belly':
        return Colors.orange;
      case 'Appetizers':
        return Colors.blue;
      case 'Desserts':
        return Colors.purple;
      case 'Pastas':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}