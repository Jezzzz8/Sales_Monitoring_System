import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../models/production_inventory.dart';
import '../screens/category_management.dart';
import '../utils/settings_mixin.dart';

class InventoryMonitoring extends StatefulWidget {
  const InventoryMonitoring({super.key});

  @override
  State<InventoryMonitoring> createState() => _InventoryMonitoringState();
}

class _InventoryMonitoringState extends State<InventoryMonitoring>  with SettingsMixin {
  
  final List<ProductionInventory> _inventoryItems = [
    ProductionInventory(
      id: '1',
      name: 'Live Pig',
      category: '18-20kg',
      unit: 'head',
      currentStock: 15,
      minimumStock: 5,
      reorderQuantity: 10,
      unitCost: 3000,
      lastRestocked: DateTime.now().subtract(const Duration(days: 2)),
      nextRestockDate: DateTime.now().add(const Duration(days: 5)),
      status: 'In Stock',
    ),
    ProductionInventory(
      id: '2',
      name: 'Live Pig',
      category: '21-23kg',
      unit: 'head',
      currentStock: 8,
      minimumStock: 3,
      reorderQuantity: 8,
      unitCost: 3500,
      lastRestocked: DateTime.now().subtract(const Duration(days: 5)),
      nextRestockDate: DateTime.now().add(const Duration(days: 2)),
      status: 'Low Stock',
    ),
    ProductionInventory(
      id: '3',
      name: 'Live Pig',
      category: '24-26kg',
      unit: 'head',
      currentStock: 5,
      minimumStock: 2,
      reorderQuantity: 5,
      unitCost: 4000,
      lastRestocked: DateTime.now().subtract(const Duration(days: 3)),
      nextRestockDate: DateTime.now().add(const Duration(days: 7)),
      status: 'In Stock',
    ),
    ProductionInventory(
      id: '4',
      name: 'Live Cow',
      category: '150-200kg',
      unit: 'head',
      currentStock: 3,
      minimumStock: 1,
      reorderQuantity: 2,
      unitCost: 35000,
      lastRestocked: DateTime.now().subtract(const Duration(days: 10)),
      nextRestockDate: DateTime.now().add(const Duration(days: 14)),
      status: 'In Stock',
    ),
    ProductionInventory(
      id: '5',
      name: 'Live Goat',
      category: '15-20kg',
      unit: 'head',
      currentStock: 10,
      minimumStock: 3,
      reorderQuantity: 5,
      unitCost: 4500,
      lastRestocked: DateTime.now().subtract(const Duration(days: 7)),
      nextRestockDate: DateTime.now().add(const Duration(days: 10)),
      status: 'In Stock',
    ),
    ProductionInventory(
      id: '6',
      name: 'Pork Belly',
      category: '3kg',
      unit: 'piece',
      currentStock: 25,
      minimumStock: 10,
      reorderQuantity: 20,
      unitCost: 1800,
      lastRestocked: DateTime.now().subtract(const Duration(days: 3)),
      nextRestockDate: DateTime.now().add(const Duration(days: 7)),
      status: 'In Stock',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedItemType = 'All';
  String _selectedStatus = 'All';
  bool _showFilters = false;

  List<ProductionInventory> get _filteredItems {
    return _inventoryItems.where((item) {
      final matchesItemType = _selectedItemType == 'All' || item.name == _selectedItemType;
      final matchesStatus = _selectedStatus == 'All' || item.status == _selectedStatus;
      final matchesSearch = _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchController.text.toLowerCase());
      
      return matchesItemType && matchesStatus && matchesSearch;
    }).toList();
  }

  List<ProductionInventory> get _itemsNeedingReorder {
    return _inventoryItems.where((item) => item.currentStock <= item.minimumStock).toList();
  }

  double get _totalInventoryValue {
    return _inventoryItems.fold<double>(0, (sum, item) => sum + (item.currentStock * item.unitCost));
  }

  int get _totalItemCount {
    return _inventoryItems.fold<int>(
        0, (sum, item) => sum + item.currentStock.toInt());
  }

  Set<String> get _itemTypes {
    return _inventoryItems.map((item) => item.name).toSet();
  }

  void _restockItem(ProductionInventory item) {
    final primaryColor = getPrimaryColor();
    final quantityController = TextEditingController(text: item.reorderQuantity.toString());
    final unitCostController = TextEditingController(text: item.unitCost.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restock Production Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${item.name} (${item.category})', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
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
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final newStock = item.currentStock + quantity;
              
              setState(() {
                final index = _inventoryItems.indexWhere((i) => i.id == item.id);
                if (index != -1) {
                  final newStatus = newStock <= item.minimumStock ? 'Low Stock' : 'In Stock';
                  _inventoryItems[index] = ProductionInventory(
                    id: item.id,
                    name: item.name,
                    category: item.category,
                    unit: item.unit,
                    currentStock: newStock,
                    minimumStock: item.minimumStock,
                    reorderQuantity: double.tryParse(quantityController.text) ?? item.reorderQuantity,
                    unitCost: double.tryParse(unitCostController.text) ?? item.unitCost,
                    lastRestocked: DateTime.now(),
                    nextRestockDate: item.nextRestockDate,
                    status: newStatus,
                  );
                }
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} restocked successfully'),
                  backgroundColor: Colors.green,
                ),
              );
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

  void _showItemDetails(ProductionInventory item) {
    final primaryColor = getPrimaryColor();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name} (${item.category})', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', item.name),
              _buildDetailRow('Category', item.category),
              _buildDetailRow('Current Stock', '${item.currentStock} ${item.unit}'),
              _buildDetailRow('Minimum Stock', '${item.minimumStock} ${item.unit}'),
              _buildDetailRow('Reorder Quantity', '${item.reorderQuantity} ${item.unit}'),
              _buildDetailRow('Unit Cost', '₱${item.unitCost.toStringAsFixed(2)}/${item.unit}'),
              _buildDetailRow('Total Value', '₱${(item.currentStock * item.unitCost).toStringAsFixed(2)}'),
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
    final categoryController = TextEditingController();
    final unitController = TextEditingController();
    final currentStockController = TextEditingController(text: '0');
    final minimumStockController = TextEditingController(text: '0');
    final reorderQuantityController = TextEditingController(text: '0');
    final unitCostController = TextEditingController(text: '0');
    
    String selectedStatus = 'In Stock';
    List<String> statuses = ['In Stock', 'Low Stock', 'Out of Stock'];
    
    final List<Map<String, dynamic>> productionItemTypes = [
      {'name': 'Live Pig', 'units': ['head'], 'categories': ['18-20kg', '21-23kg', '24-26kg', '27-30kg']},
      {'name': 'Live Cow', 'units': ['head'], 'categories': ['150-200kg', '200-250kg', '250-300kg']},
      {'name': 'Live Goat', 'units': ['head'], 'categories': ['15-20kg', '20-25kg', '25-30kg']},
      {'name': 'Live Turkey', 'units': ['head'], 'categories': ['8-10kg', '10-12kg', '12-15kg']},
      {'name': 'Pork Belly', 'units': ['piece', 'kg'], 'categories': ['3kg', '5kg', '6kg', '8kg']},
      {'name': 'Pork Shoulder', 'units': ['kg', 'piece'], 'categories': ['5kg', '8kg', '10kg']},
      {'name': 'Pork Leg', 'units': ['piece', 'kg'], 'categories': ['3-4kg', '4-5kg', '5-6kg']},
    ];
    
    String? selectedItemType;
    List<String> availableCategories = [];
    List<String> availableUnits = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.add_circle, color: primaryColor),
                const SizedBox(width: 8),
                const Text('Add Production Item'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedItemType,
                    decoration: const InputDecoration(
                      labelText: 'Item Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pets),
                      hintText: 'Select meat/livestock type',
                    ),
                    items: productionItemTypes
                        .map<DropdownMenuItem<String>>((type) => DropdownMenuItem<String>(
                              value: type['name'] as String?,
                              child: Text(type['name'] as String),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedItemType = value;
                        nameController.text = value ?? '';
                        
                        final selectedType = productionItemTypes.firstWhere(
                          (item) => item['name'] == value,
                          orElse: () => {'categories': [], 'units': []},
                        );
                        
                        availableCategories = (selectedType['categories'] as List<dynamic>?)?.cast<String>() ?? [];
                        availableUnits = (selectedType['units'] as List<dynamic>?)?.cast<String>() ?? [];
                        
                        if (availableCategories.isNotEmpty) {
                          categoryController.text = availableCategories.first;
                        }
                        if (availableUnits.isNotEmpty) {
                          unitController.text = availableUnits.first;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select item type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: availableCategories.isNotEmpty && categoryController.text.isNotEmpty 
                        ? categoryController.text 
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Category/Variant *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      hintText: 'Select weight/size category',
                    ),
                    items: availableCategories
                        .map<DropdownMenuItem<String>>((category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        categoryController.text = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: availableUnits.isNotEmpty && unitController.text.isNotEmpty 
                        ? unitController.text 
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Unit *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.scale),
                      hintText: 'Select unit of measurement',
                    ),
                    items: availableUnits
                        .map<DropdownMenuItem<String>>((unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        unitController.text = value ?? '';
                      });
                    },
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info),
                    ),
                    items: statuses
                        .map<DropdownMenuItem<String>>((status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value ?? selectedStatus;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  if (selectedItemType == null)
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
                              'This is for production inventory only. Add only meats, livestock, and raw materials needed for cooking.',
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
                      color: primaryColor,
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
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedItemType == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select item type'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (categoryController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select category/variant'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (unitController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select unit'),
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

                  final newItem = ProductionInventory(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: selectedItemType!,
                    category: categoryController.text,
                    unit: unitController.text,
                    currentStock: currentStock,
                    minimumStock: double.tryParse(minimumStockController.text) ?? 0,
                    reorderQuantity: double.tryParse(reorderQuantityController.text) ?? 0,
                    unitCost: unitCost,
                    lastRestocked: DateTime.now(),
                    status: selectedStatus,
                  );

                  setState(() {
                    _inventoryItems.add(newItem);
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$selectedItemType added to production inventory'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('ADD PRODUCTION ITEM', style: TextStyle(color: Colors.white)),
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
        builder: (context) => CategoryManagement(categoryType: 'inventory'),
      ),
    );
  }

  void _editItem(ProductionInventory item) {
    final primaryColor = getPrimaryColor();
    final nameController = TextEditingController(text: item.name);
    final categoryController = TextEditingController(text: item.category);
    final unitController = TextEditingController(text: item.unit);
    final currentStockController = TextEditingController(text: item.currentStock.toString());
    final minimumStockController = TextEditingController(text: item.minimumStock.toString());
    final reorderQuantityController = TextEditingController(text: item.reorderQuantity.toString());
    final unitCostController = TextEditingController(text: item.unitCost.toString());
    
    String selectedStatus = item.status;
    List<String> statuses = ['In Stock', 'Low Stock', 'Out of Stock'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Edit Production Inventory Item'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pets),
                    ),
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category/Variant *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info),
                    ),
                    items: statuses.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

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
                            'This is a production inventory item. Only meats, livestock, and raw materials for cooking.',
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
                      color: primaryColor,
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
                        content: Text('Item type cannot be empty'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (categoryController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter category/variant'),
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

                  final updatedItem = ProductionInventory(
                    id: item.id,
                    name: nameController.text,
                    category: categoryController.text,
                    unit: unitController.text,
                    currentStock: currentStock,
                    minimumStock: double.tryParse(minimumStockController.text) ?? item.minimumStock,
                    reorderQuantity: double.tryParse(reorderQuantityController.text) ?? item.reorderQuantity,
                    unitCost: unitCost,
                    lastRestocked: item.lastRestocked,
                    nextRestockDate: item.nextRestockDate,
                    status: selectedStatus,
                  );

                  setState(() {
                    final index = _inventoryItems.indexWhere((i) => i.id == item.id);
                    if (index != -1) {
                      _inventoryItems[index] = updatedItem;
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Production item updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text('UPDATE PRODUCTION ITEM', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteItem(ProductionInventory item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Production Item'),
        content: Text('Are you sure you want to delete "${item.name} (${item.category})" from production inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _inventoryItems.removeWhere((i) => i.id == item.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} (${item.category}) removed from production inventory'),
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
  // Check if settings are still loading
  if (isLoadingSettings) {
    return const Center(child: CircularProgressIndicator());
  }
  
  final isMobile = Responsive.isMobile(context);
  final isTablet = Responsive.isTablet(context);
  final isDesktop = Responsive.isDesktop(context);
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Theme colors based on dark mode - MATCHING sales_monitoring.dart
  final primaryColor = getPrimaryColor(); // Get from settings AFTER loading
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
                  // ENHANCED: Main Stats Grid - Matching sales_monitoring style
                  Responsive.buildResponsiveCardGrid(
                    context: context,
                    title: 'INVENTORY OVERVIEW',
                    titleColor: primaryColor,
                    centerTitle: true,
                    cards: [
                      _buildStatCard(
                        'Total Items',
                        '$_totalItemCount',
                        Icons.inventory,
                        Colors.blue,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'All inventory units',
                      ),
                      _buildStatCard(
                        'Total Value',
                        '₱${_totalInventoryValue.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'Total inventory worth',
                      ),
                      _buildStatCard(
                        'Need Reorder',
                        '${_itemsNeedingReorder.length}',
                        Icons.warning,
                        Colors.orange,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'Items below minimum',
                      ),
                      _buildStatCard(
                        'Item Types',
                        '${_itemTypes.length}',
                        Icons.category,
                        primaryColor,
                        context,
                        isDarkMode: isDarkMode,
                        subtitle: 'Product categories',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ENHANCED: Filter Options Card - Matching sales_monitoring style
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
                                          child: DropdownButtonFormField<String>(
                                            initialValue: _selectedItemType,
                                            dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                            style: TextStyle(color: textColor),
                                            decoration: InputDecoration(
                                              labelText: 'Item Type',
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
                                              prefixIcon: Icon(Icons.pets, color: primaryColor),
                                            ),
                                            items: ['All', ..._itemTypes]
                                                .map((type) => DropdownMenuItem(
                                                      value: type,
                                                      child: Text(type, style: TextStyle(color: textColor)),
                                                    ))
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedItemType = value!;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            initialValue: _selectedStatus,
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
                                        DropdownButtonFormField<String>(
                                          initialValue: _selectedItemType,
                                          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                          style: TextStyle(color: textColor),
                                          decoration: InputDecoration(
                                            labelText: 'Item Type',
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
                                            prefixIcon: Icon(Icons.pets, color: primaryColor),
                                          ),
                                          items: ['All', ..._itemTypes]
                                              .map((type) => DropdownMenuItem(
                                                    value: type,
                                                    child: Text(type, style: TextStyle(color: textColor)),
                                                  ))
                                              .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedItemType = value!;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          initialValue: _selectedStatus,
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

                  // ENHANCED: Low Stock Alert Card - Matching sales_monitoring style
                  if (_itemsNeedingReorder.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          constraints: BoxConstraints(
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
                                        child: Icon(Icons.warning, color: Colors.orange, size: 20),
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
                                    '${_itemsNeedingReorder.length} items need immediate attention:',
                                    style: TextStyle(
                                      fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _itemsNeedingReorder.map((item) => InkWell(
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
                                          '${item.name} (${item.category})',
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
                    ),

                  // ENHANCED: Inventory Items Card - Matching sales_monitoring style
                  Container(
                    constraints: BoxConstraints(
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
                                    // ENHANCED: Manage Categories Button - Matching sales_monitoring style
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
                                    // ENHANCED: Add Item Button - Matching sales_monitoring style
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
                            _filteredItems.isEmpty
                                ? Container(
                                    constraints: BoxConstraints(
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
                                        ],
                                      ),
                                    ),
                                  )
                                : isMobile
                                    ? ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _filteredItems.length,
                                        itemBuilder: (context, index) {
                                          final item = _filteredItems[index];
                                          return _buildInventoryCardMobile(item, context, isDarkMode: isDarkMode);
                                        },
                                      )
                                    : Container(
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
                                              headingTextStyle: TextStyle(
                                                fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor, // Use the primaryColor from settings
                                              ),                                              columns: const [
                                                DataColumn(label: Text('Item')),
                                                DataColumn(label: Text('Category')),
                                                DataColumn(label: Text('Current Stock')),
                                                DataColumn(label: Text('Min Stock')),
                                                DataColumn(label: Text('Unit Cost')),
                                                DataColumn(label: Text('Total Value')),
                                                DataColumn(label: Text('Status')),
                                                DataColumn(label: Text('Actions')),
                                              ],
                                              rows: _filteredItems.map((item) {
                                                return DataRow(
                                                  cells: [
                                                    DataCell(
                                                      Container(
                                                        constraints: BoxConstraints(maxWidth: Responsive.width(context) * 0.15),
                                                        child: Text(
                                                          item.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: textColor,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
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
                                                          color: _getItemColor(item.name).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(
                                                            color: _getItemColor(item.name).withOpacity(0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          item.category,
                                                          style: TextStyle(
                                                            fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                                                            fontWeight: FontWeight.bold,
                                                            color: _getItemColor(item.name),
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
                                      ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

                  // ENHANCED: Item Summary Card - Matching sales_monitoring style
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
                                  child: Icon(Icons.summarize, color: primaryColor, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ITEM SUMMARY',
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
                            isMobile
                                ? ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _itemTypes.length,
                                    itemBuilder: (context, index) {
                                      final type = _itemTypes.elementAt(index);
                                      return _buildTypeSummaryMobile(type, context, isDarkMode: isDarkMode);
                                    },
                                  )
                                : DataTable(
                                    headingRowHeight: Responsive.getDataTableRowHeight(context),
                                    dataRowHeight: Responsive.getDataTableRowHeight(context),
                                    headingTextStyle: TextStyle(
                                      fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 13, desktop: 14),
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor, // Use the primaryColor from settings
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Item Type')),
                                      DataColumn(label: Text('Items')),
                                      DataColumn(label: Text('Total Stock')),
                                      DataColumn(label: Text('Total Value')),
                                    ],
                                    rows: _itemTypes.map((type) {
                                      final typeItems = _inventoryItems
                                          .where((item) => item.name == type);
                                      final totalStock = typeItems.fold<double>(
                                          0, (sum, item) => sum + item.currentStock);
                                      final totalValue = typeItems.fold<double>(
                                          0.0, (sum, item) => sum + item.stockValue);
                                      
                                      return DataRow(cells: [
                                        DataCell(
                                          Text(
                                            type,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text('${typeItems.length}', style: TextStyle(color: textColor))),
                                        DataCell(Text(totalStock.toStringAsFixed(0), style: TextStyle(color: textColor))),
                                        DataCell(
                                          Text(
                                            '₱${totalValue.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.getLargeSpacing(context).height),

                  // ENHANCED: Inventory Guidelines Card - Matching sales_monitoring style
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
                                  child: Icon(Icons.info, color: Colors.blue, size: 20),
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

  Widget _buildInventoryCardMobile(ProductionInventory item, BuildContext context, {bool isDarkMode = false}) {
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
                          '${item.name} (${item.category})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.getSubtitleFontSize(context),
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getItemColor(item.name).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                              color: _getItemColor(item.name),
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

  Widget _buildTypeSummaryMobile(String type, BuildContext context, {bool isDarkMode = false}) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final mutedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    final typeItems = _inventoryItems.where((item) => item.name == type);
    final totalStock = typeItems.fold<double>(0, (sum, item) => sum + item.currentStock);
    final totalValue = typeItems.fold<double>(0.0, (sum, item) => sum + item.stockValue);
    
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
              type,
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
                        'Items',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                          color: mutedTextColor,
                        ),
                      ),
                      Text(
                        '${typeItems.length}',
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
                        'Total Stock',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                          color: mutedTextColor,
                        ),
                      ),
                      Text(
                        totalStock.toStringAsFixed(0),
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
                        'Total Value',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                          color: mutedTextColor,
                        ),
                      ),
                      Text(
                        '₱${totalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                          color: getPrimaryColor(),
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
    final primaryColor = getPrimaryColor();
    
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

  Color _getItemColor(String itemName) {
    if (itemName.toLowerCase().contains('pig')) return Colors.deepOrange;
    if (itemName.toLowerCase().contains('cow')) return Colors.brown;
    if (itemName.toLowerCase().contains('goat')) return Colors.orange;
    if (itemName.toLowerCase().contains('turkey')) return Colors.red;
    if (itemName.toLowerCase().contains('pork')) return Colors.pink;
    if (itemName.toLowerCase().contains('charcoal')) return Colors.grey;
    if (itemName.toLowerCase().contains('oil')) return Colors.amber;
    return Colors.blue;
  }
}