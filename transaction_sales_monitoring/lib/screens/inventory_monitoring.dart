// lib/screens/inventory_monitoring.dart - UPDATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../utils/responsive.dart';
import '../models/inventory.dart';
import '../models/category_model.dart';
import '../screens/category_management.dart';
import '../utils/settings_mixin.dart';
import '../services/inventory_service.dart';
import '../services/category_service.dart' hide InventoryService;

class InventoryMonitoring extends StatefulWidget {
  const InventoryMonitoring({super.key});

  @override
  State<InventoryMonitoring> createState() => _InventoryMonitoringState();
}

class _InventoryMonitoringState extends State<InventoryMonitoring> with SettingsMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  bool _showFilters = false;
  bool _isLoadingCategories = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _restockItem(InventoryItem item) {
    final primaryColor = getPrimaryColor();
    final quantityController = TextEditingController(text: item.reorderQuantity.toString());
    final unitCostController = TextEditingController(text: item.unitCost.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restock Inventory Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item.name} (${item.categoryName})', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity to Add',
                  border: const OutlineInputBorder(),
                  suffixText: item.unit,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: unitCostController,
                decoration: InputDecoration(
                  labelText: 'Unit Cost',
                  border: const OutlineInputBorder(),
                  prefixText: '₱',
                  suffixText: '/${item.unit}',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Total Stock:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${item.currentStock + (double.tryParse(quantityController.text) ?? 0)} ${item.unit}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
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
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final unitCost = double.tryParse(unitCostController.text) ?? item.unitCost;
              
              if (quantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity (greater than 0)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                await InventoryService.restockItem(
                  item.id, 
                  quantity,
                  newUnitCost: unitCost != item.unitCost ? unitCost : null,
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} restocked successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error restocking item: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text('RESTOCK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(InventoryItem item) {
    final primaryColor = getPrimaryColor();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name} (${item.categoryName})', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.description != null && item.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    item.description!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              _buildDetailRow('Category', item.categoryName),
              _buildDetailRow('Current Stock', '${item.currentStock} ${item.unit}'),
              _buildDetailRow('Minimum Stock', '${item.minimumStock} ${item.unit}'),
              _buildDetailRow('Reorder Quantity', '${item.reorderQuantity} ${item.unit}'),
              _buildDetailRow('Unit Cost', '₱${item.unitCost.toStringAsFixed(2)}/${item.unit}'),
              _buildDetailRow('Total Value', '₱${item.stockValue.toStringAsFixed(2)}'),
              _buildDetailRow('Status', item.status),
              _buildDetailRow('Last Restocked', _formatDate(item.lastRestocked)),
              if (item.nextRestockDate != null)
                _buildDetailRow('Next Restock', _formatDate(item.nextRestockDate!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () => _restockItem(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text('RESTOCK', style: TextStyle(color: Colors.white)),
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

  void _addItem() {
    final primaryColor = getPrimaryColor();
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final unitController = TextEditingController();
    final currentStockController = TextEditingController(text: '0');
    final minimumStockController = TextEditingController(text: '0');
    final reorderQuantityController = TextEditingController(text: '0');
    final unitCostController = TextEditingController(text: '0');
    
    String selectedCategoryId = '';
    String selectedCategoryName = '';
    String selectedStatus = 'In Stock';
    String selectedColor = '#2196F3';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_circle, color: primaryColor),
                const SizedBox(width: 8),
                const Text('Add Inventory Item'),
              ],
            ),
            content: SingleChildScrollView(
              child: StreamBuilder<List<ProductCategory>>(
                stream: CategoryService.getCategoriesByTypeStream('inventory'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final categories = snapshot.data ?? [];
                  
                  if (categories.isEmpty) {
                    return Column(
                      children: [
                        const Text('No inventory categories found. Please create categories first.'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _openCategoryManagement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Manage Categories'),
                        ),
                      ],
                    );
                  }
                  
                  // Set default category if not set
                  if (selectedCategoryId.isEmpty && categories.isNotEmpty) {
                    selectedCategoryId = categories.first.id;
                    selectedCategoryName = categories.first.name;
                    selectedColor = categories.first.color;
                  }
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                          hintText: 'e.g., Live Pig, Cooking Oil, Charcoal',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId.isNotEmpty ? selectedCategoryId : null,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories
                            .map<DropdownMenuItem<String>>((category) => DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: _parseColor(category.color),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(category.name),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final category = categories
                                .firstWhere((cat) => cat.id == value);
                            setState(() {
                              selectedCategoryId = value;
                              selectedCategoryName = category.name;
                              selectedColor = category.color;
                            });
                          }
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

                      // Unit Input
                      TextFormField(
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale),
                          hintText: 'e.g., kg, liter, head, piece',
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stock inputs row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: currentStockController,
                              decoration: const InputDecoration(
                                labelText: 'Current Stock',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: minimumStockController,
                              decoration: const InputDecoration(
                                labelText: 'Min Stock',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.warning),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reorder and Cost row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: reorderQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Reorder Quantity',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.restore),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: unitCostController,
                              decoration: const InputDecoration(
                                labelText: 'Unit Cost',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                                prefixText: '₱',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Add inventory items for production materials, supplies, and raw materials.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Total value display
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Value:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              '₱${((double.tryParse(currentStockController.text) ?? 0) * (double.tryParse(unitCostController.text) ?? 0)).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
                        content: Text('Please enter item name'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedCategoryId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select category'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (unitController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter unit'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final currentStock = double.tryParse(currentStockController.text);
                  final unitCost = double.tryParse(unitCostController.text);
                  
                  if (currentStock == null || currentStock < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid current stock'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (unitCost == null || unitCost <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid unit cost (greater than 0)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final newItem = InventoryItem(
                    id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    categoryId: selectedCategoryId,
                    categoryName: selectedCategoryName,
                    unit: unitController.text,
                    currentStock: currentStock,
                    minimumStock: double.tryParse(minimumStockController.text) ?? 0,
                    reorderQuantity: double.tryParse(reorderQuantityController.text) ?? 0,
                    unitCost: unitCost,
                    lastRestocked: DateTime.now(),
                    status: selectedStatus,
                    color: selectedColor,
                    description: descriptionController.text,
                    isActive: true,
                    createdAt: DateTime.now(),
                  );

                  try {
                    await InventoryService.createInventoryItem(newItem);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameController.text} added to inventory'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding item: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('ADD INVENTORY ITEM', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openCategoryManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategoryManagement(categoryType: 'inventory'),
      ),
    );
  }

  void _editItem(InventoryItem item) {
    final primaryColor = getPrimaryColor();
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description ?? '');
    final unitController = TextEditingController(text: item.unit);
    final currentStockController = TextEditingController(text: item.currentStock.toString());
    final minimumStockController = TextEditingController(text: item.minimumStock.toString());
    final reorderQuantityController = TextEditingController(text: item.reorderQuantity.toString());
    final unitCostController = TextEditingController(text: item.unitCost.toString());
    
    String selectedCategoryId = item.categoryId;
    String selectedCategoryName = item.categoryName;
    String selectedStatus = item.status;
    String selectedColor = item.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Inventory Item'),
              ],
            ),
            content: SingleChildScrollView(
              child: StreamBuilder<List<ProductCategory>>(
                stream: CategoryService.getCategoriesByTypeStream('inventory'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final categories = snapshot.data ?? [];
                  
                  if (categories.isEmpty) {
                    return const Column(
                      children: [
                        Text('No inventory categories found.'),
                      ],
                    );
                  }
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: categories
                            .map<DropdownMenuItem<String>>((category) => DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: _parseColor(category.color),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(category.name),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final category = categories
                                .firstWhere((cat) => cat.id == value);
                            setState(() {
                              selectedCategoryId = value;
                              selectedCategoryName = category.name;
                              selectedColor = category.color;
                            });
                          }
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
                        controller: unitController,
                        decoration: const InputDecoration(
                          labelText: 'Unit *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.scale),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: currentStockController,
                              decoration: const InputDecoration(
                                labelText: 'Current Stock',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: minimumStockController,
                              decoration: const InputDecoration(
                                labelText: 'Min Stock',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.warning),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: reorderQuantityController,
                              decoration: const InputDecoration(
                                labelText: 'Reorder Quantity',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.restore),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: unitCostController,
                              decoration: const InputDecoration(
                                labelText: 'Unit Cost',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                                prefixText: '₱',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This is an inventory item for production materials and supplies.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Value:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              '₱${(double.tryParse(currentStockController.text) ?? 0) * (double.tryParse(unitCostController.text) ?? 0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
                        content: Text('Item name cannot be empty'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (selectedCategoryId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select category'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (unitController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter unit'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final currentStock = double.tryParse(currentStockController.text);
                  final unitCost = double.tryParse(unitCostController.text);
                  
                  if (currentStock == null || currentStock < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid current stock'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (unitCost == null || unitCost <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid unit cost (greater than 0)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final updatedItem = item.copyWith(
                    name: nameController.text,
                    categoryId: selectedCategoryId,
                    categoryName: selectedCategoryName,
                    unit: unitController.text,
                    currentStock: currentStock,
                    minimumStock: double.tryParse(minimumStockController.text) ?? item.minimumStock,
                    reorderQuantity: double.tryParse(reorderQuantityController.text) ?? item.reorderQuantity,
                    unitCost: unitCost,
                    status: selectedStatus,
                    color: selectedColor,
                    description: descriptionController.text,
                    updatedAt: DateTime.now(),
                  );

                  try {
                    await InventoryService.updateInventoryItem(updatedItem);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inventory item updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating item: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
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

  void _deleteItem(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Inventory Item'),
        content: Text('Are you sure you want to delete "${item.name} (${item.categoryName})" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await InventoryService.deleteInventoryItem(item.id);
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} (${item.categoryName}) removed from inventory'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting item: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
    if (isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final isMobile = Responsive.isMobile(context);
    final isDesktop = Responsive.isDesktop(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
                  StreamBuilder<List<InventoryItem>>(
                    stream: InventoryService.getInventoryItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: primaryColor));
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading inventory: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      
                      final inventoryItems = snapshot.data ?? [];
                      final itemsNeedingReorder = inventoryItems.where((item) => item.needsReorder).toList();
                      final totalValue = inventoryItems.fold<double>(0, (sum, item) => sum + item.stockValue);
                      
                      return StreamBuilder<List<ProductCategory>>(
                        stream: CategoryService.getCategoriesByTypeStream('inventory'),
                        builder: (context, categorySnapshot) {
                          final categories = categorySnapshot.data ?? [];
                          
                          return Responsive.buildResponsiveCardGrid(
                            context: context,
                            title: 'INVENTORY OVERVIEW',
                            titleColor: primaryColor,
                            centerTitle: true,
                            cards: [
                              _buildStatCard(
                                'Total Items',
                                '${inventoryItems.length}',
                                Icons.inventory,
                                Colors.blue,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'Total inventory items',
                              ),
                              _buildStatCard(
                                'Total Value',
                                '₱${totalValue.toStringAsFixed(2)}',
                                Icons.attach_money,
                                Colors.green,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'Total inventory worth',
                              ),
                              _buildStatCard(
                                'Categories',
                                '${categories.length}',
                                Icons.category,
                                Colors.orange,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'Available categories',
                              ),
                              _buildStatCard(
                                'Need Reorder',
                                '${itemsNeedingReorder.length}',
                                Icons.warning,
                                Colors.red,
                                context,
                                isDarkMode: isDarkMode,
                                subtitle: 'Items below minimum',
                              ),
                            ],
                          );
                        },
                      );
                    },
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
                                hintText: 'Search items by name or category...',
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
                                          child: StreamBuilder<List<InventoryItem>>(
                                            stream: InventoryService.getInventoryItems(),
                                            builder: (context, snapshot) {
                                              final items = snapshot.data ?? [];
                                              final categories = items.map((item) => item.categoryName).toSet().toList();
                                              
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
                                                items: ['All', ...categories]
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
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedStatus,
                                            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                            style: TextStyle(color: textColor),
                                            decoration: InputDecoration(
                                              labelText: 'Status',
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
                                              prefixIcon: Icon(Icons.info, color: primaryColor),
                                            ),
                                            items: ['All', 'In Stock', 'Low Stock', 'Out of Stock']
                                                .map((status) => DropdownMenuItem(
                                                      value: status,
                                                      child: Text(status, style: TextStyle(color: textColor)),
                                                    ))
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedStatus = value!;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        StreamBuilder<List<InventoryItem>>(
                                          stream: InventoryService.getInventoryItems(),
                                          builder: (context, snapshot) {
                                            final items = snapshot.data ?? [];
                                            final categories = items.map((item) => item.categoryName).toSet().toList();
                                            
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
                                              items: ['All', ...categories]
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
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          value: _selectedStatus,
                                          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: 'Status',
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
                                            prefixIcon: Icon(Icons.info, color: primaryColor),
                                          ),
                                          items: ['All', 'In Stock', 'Low Stock', 'Out of Stock']
                                              .map((status) => DropdownMenuItem(
                                                    value: status,
                                                    child: Text(status, style: TextStyle(color: textColor)),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedStatus = value!;
                                            });
                                          },
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

                  // Low Stock Alert Card
                  StreamBuilder<List<InventoryItem>>(
                    stream: InventoryService.getLowStockItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      
                      final lowStockItems = snapshot.data ?? [];
                      
                      if (lowStockItems.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Column(
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                              minHeight: 120,
                            ),
                            child: Card(
                              elevation: isDarkMode ? 2 : 3,
                              color: Colors.orange.shade50.withOpacity(isDarkMode ? 0.2 : 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDarkMode ? Colors.orange.shade700 : Colors.orange.shade300,
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
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.warning, color: Colors.orange, size: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'LOW STOCK ALERT',
                                            style: TextStyle(
                                              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${lowStockItems.length} items need immediate attention:',
                                      style: TextStyle(
                                        fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: lowStockItems.map((item) => InkWell(
                                        onTap: () => _showItemDetails(item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDarkMode ? Colors.orange.shade800 : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDarkMode ? Colors.orange.shade700 : Colors.orange.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            '${item.name} (${item.categoryName})',
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white : Colors.orange.shade800,
                                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // Inventory Items Card
                  Container(
                    constraints: const BoxConstraints(
                      minHeight: 200,
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
                                Flexible(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.inventory, color: primaryColor, size: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'INVENTORY ITEMS',
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
                                ),
                                Responsive.getOrientationFlexLayout(
                                  context,
                                  children: [
                                    // Manage Categories Button
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
                                    // Add Item Button
                                    ElevatedButton.icon(
                                      onPressed: _addItem,
                                      icon: Icon(Icons.add, 
                                          size: Responsive.getIconSize(context, multiplier: 0.8)),
                                      label: Text(
                                        'ADD ITEM',
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
                            const SizedBox(height: 16),
                            
                            StreamBuilder<List<InventoryItem>>(
                              stream: InventoryService.getInventoryItems(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading items: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }
                                
                                final allItems = snapshot.data ?? [];
                                
                                // Filter items
                                final filteredItems = allItems.where((item) {
                                  final matchesCategory = _selectedCategory == 'All' || item.categoryName == _selectedCategory;
                                  final matchesStatus = _selectedStatus == 'All' || item.status == _selectedStatus;
                                  final matchesSearch = _searchController.text.isEmpty ||
                                      item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                                      item.categoryName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                                      (item.description ?? '').toLowerCase().contains(_searchController.text.toLowerCase());
                                  
                                  return matchesCategory && matchesStatus && matchesSearch;
                                }).toList();
                                
                                if (filteredItems.isEmpty) {
                                  return Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 150,
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            size: Responsive.getIconSize(context, multiplier: 2.5),
                                            color: mutedTextColor,
                                          ),
                                          SizedBox(height: Responsive.getSpacing(context).height),
                                          Text(
                                            'No items found',
                                            style: TextStyle(
                                              fontSize: Responsive.getBodyFontSize(context),
                                              color: mutedTextColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add items or check your filters',
                                            style: TextStyle(
                                              fontSize: Responsive.getBodyFontSize(context) * 0.9,
                                              color: mutedTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                
                                return isMobile
                                    ? ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredItems.length,
                                        itemBuilder: (context, index) {
                                          final item = filteredItems[index];
                                          return _buildInventoryCardMobile(item, context, isDarkMode: isDarkMode);
                                        },
                                      )
                                    : Container(
                                        constraints: const BoxConstraints(
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
                                              headingTextStyle: TextStyle(
                                                fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                              columns: const [
                                                DataColumn(label: Text('Item')),
                                                DataColumn(label: Text('Category')),
                                                DataColumn(label: Text('Current Stock')),
                                                DataColumn(label: Text('Min Stock')),
                                                DataColumn(label: Text('Unit Cost')),
                                                DataColumn(label: Text('Total Value')),
                                                DataColumn(label: Text('Status')),
                                                DataColumn(label: Text('Actions')),
                                              ],
                                              rows: filteredItems.map((item) {
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
                                                              item.name,
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: textColor,
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                            if (item.description != null && item.description!.isNotEmpty)
                                                              Text(
                                                                item.description!,
                                                                style: TextStyle(
                                                                  fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                                  color: mutedTextColor,
                                                                ),
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
                                                          color: _parseColor(item.color).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(
                                                            color: _parseColor(item.color).withOpacity(0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          item.categoryName,
                                                          style: TextStyle(
                                                            fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                            fontWeight: FontWeight.bold,
                                                            color: _parseColor(item.color),
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
                                                            '${item.currentStock} ${item.unit}',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: item.needsReorder ? Colors.red : Colors.green,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '${item.minimumStock} ${item.unit}',
                                                        style: TextStyle(color: textColor),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '₱${item.unitCost.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        '₱${item.stockValue.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: _getStatusColor(item.status).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(20),
                                                          border: Border.all(
                                                            color: _getStatusColor(item.status).withOpacity(0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          item.status,
                                                          style: TextStyle(
                                                            fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                            fontWeight: FontWeight.bold,
                                                            color: _getStatusColor(item.status),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(Icons.restore, size: Responsive.getIconSize(context, multiplier: 0.8)),
                                                            color: Colors.blue,
                                                            onPressed: () => _restockItem(item),
                                                            tooltip: 'Restock',
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.edit, size: Responsive.getIconSize(context, multiplier: 0.8)),
                                                            color: Colors.green,
                                                            onPressed: () => _editItem(item),
                                                            tooltip: 'Edit',
                                                          ),
                                                          IconButton(
                                                            icon: Icon(Icons.delete, size: Responsive.getIconSize(context, multiplier: 0.8)),
                                                            color: Colors.red,
                                                            onPressed: () => _deleteItem(item),
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
                                      );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

                  // Categories Summary Card
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
                                  child: Icon(Icons.category, color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'INVENTORY CATEGORIES',
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
                              stream: CategoryService.getCategoriesByTypeStream('inventory'),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(color: primaryColor),
                                  );
                                }
                                
                                final categories = snapshot.data ?? [];
                                
                                return StreamBuilder<List<InventoryItem>>(
                                  stream: InventoryService.getInventoryItems(),
                                  builder: (context, itemsSnapshot) {
                                    final items = itemsSnapshot.data ?? [];
                                    
                                    if (categories.isEmpty) {
                                      return Center(
                                        child: Column(
                                          children: [
                                            Icon(Icons.category_outlined, size: 48, color: mutedTextColor),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No inventory categories found',
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
                                              final itemsCount = items.where((item) => item.categoryId == category.id).length;
                                              return _buildCategoryCardMobile(category, itemsCount, context, isDarkMode: isDarkMode);
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
                                              DataColumn(label: Text('Description')),
                                              DataColumn(label: Text('Items Count')),
                                              DataColumn(label: Text('Status')),
                                            ],
                                            rows: categories.map((category) {
                                              final itemsCount = items
                                                  .where((item) => item.categoryId == category.id)
                                                  .length;
                                              
                                              return DataRow(
                                                cells: [
                                                  DataCell(
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 20,
                                                          height: 20,
                                                          decoration: BoxDecoration(
                                                            color: _parseColor(category.color),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: Colors.grey.shade300),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          category.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor,
                                                          ),
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
                                                    Text(
                                                      '$itemsCount items',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                  ),
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
                                                ],
                                              );
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
                  ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

                  // Inventory Guidelines Card
                  Container(
                    constraints: const BoxConstraints(
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
                                  child: const Icon(Icons.info, color: Colors.blue, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'INVENTORY GUIDELINES',
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
                              'Check inventory daily before accepting large orders',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
                            ),
                            _buildGuidelineItem(
                              'Reorder when stock reaches minimum level',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
                            ),
                            _buildGuidelineItem(
                              'Maintain 3-5 days worth of inventory for peak seasons',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
                            ),
                            _buildGuidelineItem(
                              'Track seasonal demand patterns (weddings, holidays, fiestas)',
                              context,
                              isDarkMode: isDarkMode,
                              iconColor: Colors.blue,
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

  Widget _buildInventoryCardMobile(InventoryItem item, BuildContext context, {bool isDarkMode = false}) {
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Card(
      margin: EdgeInsets.only(bottom: Responsive.getPaddingSize(context)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: () => _showItemDetails(item),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: Responsive.getCardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.name} (${item.categoryName})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getSubtitleFontSize(context),
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.description != null && item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                              color: mutedTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _parseColor(item.color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.categoryName,
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                              color: _parseColor(item.color),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(item.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(item.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.inventory,
                    size: Responsive.getIconSize(context, multiplier: 0.8),
                    color: mutedTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock: ${item.currentStock} ${item.unit}',
                      style: TextStyle(
                        fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.attach_money,
                    size: Responsive.getIconSize(context, multiplier: 0.8),
                    color: mutedTextColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₱${item.unitCost.toStringAsFixed(2)}/${item.unit}',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Min Stock: ${item.minimumStock} ${item.unit}',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                          color: mutedTextColor,
                        ),
                      ),
                      Text(
                        'Total: ₱${item.stockValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.restore, size: Responsive.getIconSize(context, multiplier: 0.9)),
                        color: Colors.blue,
                        onPressed: () => _restockItem(item),
                        tooltip: 'Restock',
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: Responsive.getIconSize(context, multiplier: 0.9)),
                        color: Colors.green,
                        onPressed: () => _editItem(item),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: Responsive.getIconSize(context, multiplier: 0.9)),
                        color: Colors.red,
                        onPressed: () => _deleteItem(item),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCardMobile(ProductCategory category, int itemsCount, BuildContext context, {bool isDarkMode = false}) {
    final primaryColor = getPrimaryColor();
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(category.color),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.category, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getSubtitleFontSize(context),
                      color: textColor,
                    ),
                  ),
                  Text(
                    category.description.isNotEmpty ? category.description : 'No description',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                      color: mutedTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '$itemsCount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                    color: primaryColor,
                  ),
                ),
                Text(
                  'items',
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                    color: mutedTextColor,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Stock': return Colors.green;
      case 'Low Stock': return Colors.orange;
      case 'Out of Stock': return Colors.red;
      default: return Colors.grey;
    }
  }
}