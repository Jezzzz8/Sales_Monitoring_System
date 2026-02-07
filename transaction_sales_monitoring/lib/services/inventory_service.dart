// lib/services/inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/category_model.dart';
import '../models/inventory.dart';
import 'category_service.dart';

class InventoryService {
  static CollectionReference get inventoryCollection => 
      FirebaseConfig.firestore.collection('inventory');

  // Get all inventory items
    static Stream<List<InventoryItem>> getInventoryItems() {
    return inventoryCollection
        .orderBy('createdAt', descending: true)  // Remove isActive filter
        .snapshots()
        .asyncMap((snapshot) async {
      // Filter in memory
      final items = snapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .where((item) => item.isActive)
          .toList();

      // Fetch categories to get category names
      final categories = await CategoryService.getCategoriesByTypeStream('inventory').first;
      final categoryMap = {for (var cat in categories) cat.id: cat};

      // Update items with full category information
      for (var item in items) {
        final category = categoryMap[item.categoryId];
        if (category != null) {
          item.categoryName = category.name;
          if (item.color.isEmpty || item.color == '#2196F3') {
            item.color = category.color;
          }
        }
      }

      return items;
    });
  }

  // Get inventory items by category
  static Stream<List<InventoryItem>> getInventoryByCategory(String categoryId) {
    return inventoryCollection
        .where('categoryId', isEqualTo: categoryId)  // Single where clause
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .where((item) => item.isActive)  // Filter in memory
            .toList());
  }

  // Get low stock items
  static Stream<List<InventoryItem>> getLowStockItems() {
    return inventoryCollection
        .orderBy('name')  // Remove isActive filter
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .where((item) => item.isActive && item.needsReorder)  // Filter in memory
            .toList());
  }

  // Add inventory item
  static Future<void> createInventoryItem(InventoryItem item) async {
    try {
      await inventoryCollection.doc(item.id).set(item.toFirestore());
    } catch (e) {
      print('Error creating inventory item: $e');
      rethrow;
    }
  }

  // Update inventory item
  static Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      await inventoryCollection.doc(item.id).update({
        'name': item.name,
        'categoryId': item.categoryId,
        'categoryName': item.categoryName,
        'unit': item.unit,
        'currentStock': item.currentStock,
        'minimumStock': item.minimumStock,
        'reorderQuantity': item.reorderQuantity,
        'unitCost': item.unitCost,
        'lastRestocked': Timestamp.fromDate(item.lastRestocked),
        'nextRestockDate': item.nextRestockDate != null 
            ? Timestamp.fromDate(item.nextRestockDate!)
            : null,
        'status': item.status,
        'color': item.color,
        'description': item.description ?? '',
        // FIX: Changed from isActive to active
        'active': item.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }

  // Restock inventory
    static Future<void> restockItem(String itemId, double quantity, {double? newUnitCost}) async {
    try {
      final doc = await inventoryCollection.doc(itemId).get();
      if (!doc.exists) throw Exception('Item not found');

      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['currentStock'] ?? 0).toDouble();
      final unitCost = newUnitCost ?? (data['unitCost'] ?? 0).toDouble();
      final minimumStock = (data['minimumStock'] ?? 0).toDouble();
      final newStock = currentStock + quantity;
      
      final status = _calculateStatus(newStock, minimumStock);

      await inventoryCollection.doc(itemId).update({
        'currentStock': newStock,
        'unitCost': unitCost,
        'status': status,
        'lastRestocked': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error restocking item: $e');
      rethrow;
    }
  }

  // Consume inventory (for production/sales)
  static Future<void> consumeItem(String itemId, double quantity) async {
    try {
      final doc = await inventoryCollection.doc(itemId).get();
      if (!doc.exists) throw Exception('Item not found');

      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['currentStock'] ?? 0).toDouble();
      final minimumStock = (data['minimumStock'] ?? 0).toDouble();
      final newStock = currentStock - quantity;
      
      final status = _calculateStatus(newStock, minimumStock);

      await inventoryCollection.doc(itemId).update({
        'currentStock': newStock >= 0 ? newStock : 0,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error consuming item: $e');
      rethrow;
    }
  }

  // Delete inventory item (soft delete)
  static Future<void> deleteInventoryItem(String itemId) async {
    try {
      await inventoryCollection.doc(itemId).update({
        // FIX: Changed from isActive to active
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting inventory item: $e');
      rethrow;
    }
  }

  static Future<void> toggleInventoryItemStatus(String itemId, bool isActive) async {
    try {
      await inventoryCollection.doc(itemId).update({
        // FIX: Changed from isActive to active
        'active': !isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling inventory item status: $e');
      rethrow;
    }
  }

  // Get inventory statistics
    static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final snapshot = await inventoryCollection
          .orderBy('name')  // Remove isActive filter
          .get();
      
      // Filter in memory
      final items = snapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .where((item) => item.isActive)
          .toList();

      double totalValue = 0;
      int lowStockCount = 0;
      int outOfStockCount = 0;
      final Map<String, double> categoryValues = {};

      for (final item in items) {
        totalValue += item.stockValue;
        
        if (item.currentStock <= 0) {
          outOfStockCount++;
        } else if (item.needsReorder) {
          lowStockCount++;
        }
        
        categoryValues.update(
          item.categoryName,
          (value) => value + item.stockValue,
          ifAbsent: () => item.stockValue,
        );
      }

      return {
        'totalItems': items.length,
        'totalValue': totalValue,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'categoryBreakdown': categoryValues,
      };
    } catch (e) {
      print('Error getting inventory statistics: $e');
      return {
        'totalItems': 0,
        'totalValue': 0,
        'lowStockCount': 0,
        'outOfStockCount': 0,
        'categoryBreakdown': {},
      };
    }
  }

  // Get inventory item by ID
  static Future<InventoryItem?> getInventoryItem(String itemId) async {
    try {
      final doc = await inventoryCollection.doc(itemId).get();
      if (doc.exists) {
        return InventoryItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting inventory item: $e');
      return null;
    }
  }

  // Search inventory items
  static Stream<List<InventoryItem>> searchInventoryItems(String query) {
    return inventoryCollection
        .orderBy('name')  // Remove isActive filter
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .where((item) =>
                item.isActive &&  // Filter in memory
                (item.name.toLowerCase().contains(query.toLowerCase()) ||
                 item.categoryName.toLowerCase().contains(query.toLowerCase()) ||
                 (item.description ?? '').toLowerCase().contains(query.toLowerCase())))
            .toList());
  }

  // Helper method to calculate status
  static String _calculateStatus(double currentStock, double minimumStock) {
    if (currentStock <= 0) return 'Out of Stock';
    if (currentStock <= minimumStock * 1.2) return 'Low Stock';
    if (currentStock <= minimumStock) return 'Critical';
    return 'In Stock';
  }

  // Initialize default inventory items
  static Future<void> initializeDefaultInventory() async {
    try {
      // Check if inventory already exists
      final snapshot = await inventoryCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      // Get inventory categories
      final categories = await CategoryService.getCategoriesByTypeStream('inventory').first;
      
      if (categories.isEmpty) {
        print('No inventory categories found. Please create categories first.');
        return;
      }

      // Create default inventory items
      final defaultItems = [
        {
          'name': 'Live Pig',
          'description': 'Whole live pig for roasting',
          'unit': 'head',
          'currentStock': 10.0,
          'minimumStock': 3.0,
          'reorderQuantity': 5.0,
          'unitCost': 5000.0,
          'status': 'In Stock',
          'color': '#8d6e63',
        },
        {
          'name': 'Live Chicken',
          'description': 'Whole live chicken',
          'unit': 'head',
          'currentStock': 20.0,
          'minimumStock': 5.0,
          'reorderQuantity': 10.0,
          'unitCost': 200.0,
          'status': 'In Stock',
          'color': '#ff9800',
        },
        {
          'name': 'Charcoal',
          'description': 'Cooking charcoal',
          'unit': 'kg',
          'currentStock': 100.0,
          'minimumStock': 20.0,
          'reorderQuantity': 50.0,
          'unitCost': 50.0,
          'status': 'In Stock',
          'color': '#424242',
        },
        {
          'name': 'Cooking Oil',
          'description': 'Vegetable cooking oil',
          'unit': 'liter',
          'currentStock': 50.0,
          'minimumStock': 10.0,
          'reorderQuantity': 25.0,
          'unitCost': 80.0,
          'status': 'In Stock',
          'color': '#ffeb3b',
        },
        {
          'name': 'Salt',
          'description': 'Iodized salt',
          'unit': 'kg',
          'currentStock': 20.0,
          'minimumStock': 5.0,
          'reorderQuantity': 10.0,
          'unitCost': 30.0,
          'status': 'In Stock',
          'color': '#f5f5f5',
        },
      ];

      // Add default items
      for (var i = 0; i < defaultItems.length; i++) {
        final item = defaultItems[i];
        // Assign to first category found
        final categoryId = categories.isNotEmpty 
            ? categories[0].id 
            : 'default_inventory';
        
        final category = categories.firstWhere(
          (cat) => cat.id == categoryId,
          orElse: () => categories.isNotEmpty ? categories[0] : ProductCategory(
            id: 'default_inventory',
            name: 'Inventory',
            type: 'inventory',
            createdAt: DateTime.now(),
          ),
        );

        final inventoryItem = InventoryItem(
          id: 'inv_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: item['name'] as String,
          categoryId: categoryId,
          categoryName: category.name,
          unit: item['unit'] as String,
          currentStock: item['currentStock'] as double,
          minimumStock: item['minimumStock'] as double,
          reorderQuantity: item['reorderQuantity'] as double,
          unitCost: item['unitCost'] as double,
          lastRestocked: DateTime.now(),
          status: item['status'] as String,
          color: item['color'] as String,
          description: item['description'] as String?,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await inventoryCollection.doc(inventoryItem.id).set(
          inventoryItem.toFirestore()
        );
      }

      print('Default inventory items initialized');
    } catch (e) {
      print('Error initializing default inventory: $e');
    }
  }
}