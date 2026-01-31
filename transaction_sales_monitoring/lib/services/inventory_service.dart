import '../models/inventory.dart';

class InventoryService {
  static final List<InventoryItem> _inventoryItems = [
    // Pig inventory
    InventoryItem(
      id: '1',
      name: 'Pig',
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
    InventoryItem(
      id: '2',
      name: 'Pig',
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
    InventoryItem(
      id: '3',
      name: 'Pig',
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
    // Other livestock
    InventoryItem(
      id: '4',
      name: 'Cow',
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
    InventoryItem(
      id: '5',
      name: 'Goat',
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
    InventoryItem(
      id: '6',
      name: 'Turkey',
      category: '8-10kg',
      unit: 'head',
      currentStock: 12,
      minimumStock: 4,
      reorderQuantity: 8,
      unitCost: 2500,
      lastRestocked: DateTime.now().subtract(const Duration(days: 1)),
      nextRestockDate: DateTime.now().add(const Duration(days: 5)),
      status: 'In Stock',
    ),
  ];

  static final List<String> _livestockTypes = ['Pig', 'Cow', 'Goat', 'Turkey'];
  static final Map<String, List<String>> _categoryByLivestock = {
    'Pig': ['18-20kg', '21-23kg', '24-26kg'],
    'Cow': ['150-200kg', '200-250kg', '250-300kg'],
    'Goat': ['15-20kg', '20-25kg', '25-30kg'],
    'Turkey': ['8-10kg', '10-12kg', '12-15kg'],
  };

  static Future<List<InventoryItem>> getInventoryItems() async {
    return List.from(_inventoryItems);
  }

  static Future<List<String>> getLivestockTypes() async {
    return List.from(_livestockTypes);
  }

  static Future<List<String>> getCategoriesForLivestock(String livestockType) async {
    return List.from(_categoryByLivestock[livestockType] ?? []);
  }

  static Future<void> addInventoryItem(InventoryItem item) async {
    _inventoryItems.add(item);
  }

  static Future<void> updateInventoryItem(InventoryItem item) async {
    final index = _inventoryItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _inventoryItems[index] = item;
    }
  }

  static Future<void> deleteInventoryItem(String itemId) async {
    _inventoryItems.removeWhere((item) => item.id == itemId);
  }

  static Future<void> restockItem(String itemId, double quantity) async {
    final index = _inventoryItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      final item = _inventoryItems[index];
      final newStock = item.currentStock + quantity;
      final newStatus = newStock <= item.minimumStock ? 'Low Stock' : 'In Stock';
      
      _inventoryItems[index] = InventoryItem(
        id: item.id,
        name: item.name,
        category: item.category,
        unit: item.unit,
        currentStock: newStock,
        minimumStock: item.minimumStock,
        reorderQuantity: item.reorderQuantity,
        unitCost: item.unitCost,
        lastRestocked: DateTime.now(),
        nextRestockDate: item.nextRestockDate,
        status: newStatus,
      );
    }
  }

  static Future<List<InventoryItem>> getItemsNeedingReorder() async {
    return _inventoryItems.where((item) => item.needsReorder).toList();
  }

  static Future<double> getTotalInventoryValue() async {
    
    double totalValue = 0.0;
    for (final item in _inventoryItems) {
      totalValue += item.stockValue;
    }
    return totalValue;
  }

  static Future<int> getTotalLivestockCount() async {
    
    int totalCount = 0;
    for (final item in _inventoryItems) {
      totalCount += item.currentStock.toInt();
    }
    return totalCount;
  }

  static Future<Map<String, int>> getLivestockCountByType() async {
    final Map<String, int> counts = {};
    for (final item in _inventoryItems) {
      counts[item.name] = (counts[item.name] ?? 0) + item.currentStock.toInt();
    }
    return counts;
  }
}