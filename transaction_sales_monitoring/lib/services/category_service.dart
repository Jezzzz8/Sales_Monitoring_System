import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/category_model.dart';
import '../models/inventory.dart';

class CategoryService {
  static final CollectionReference categoriesCollection = 
      FirebaseConfig.firestore.collection('categories');

  // Get categories by type
  static Stream<List<ProductCategory>> getCategoriesByTypeStream(String type) {
    return categoriesCollection
        .where('type', isEqualTo: type)  // Single where clause
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .where((category) => category.isActive)  // Filter in memory
            .toList());
  }

  // Get all categories
  static Stream<List<ProductCategory>> getAllCategoriesStream() {
    return categoriesCollection
        .orderBy('type')  // Single orderBy
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .where((category) => category.isActive)  // Filter in memory
            .toList());
  }

  // Get inventory categories stream
  static Stream<List<ProductCategory>> getInventoryCategoriesStream() {
    return getCategoriesByTypeStream('inventory');
  }

  // Add new category
    static Future<void> addCategory(ProductCategory category) async {
    try {
      await categoriesCollection.doc(category.id).set({
        'id': category.id,
        'name': category.name,
        'description': category.description,
        'type': category.type,
        'displayOrder': category.displayOrder,
        'active': category.isActive,
        'color': category.color,
        'icon': category.icon,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  static Future<List<ProductCategory>> getProductCategories() async {
  try {
    final snapshot = await categoriesCollection
        .where('type', isEqualTo: 'product')
        .orderBy('name')
        .get();
    
    return snapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .where((category) => category.isActive)
        .toList();
  } catch (e) {
    print('Error getting product categories: $e');
    return [];
  }
}

  // Update category
  static Future<void> updateCategory(ProductCategory category) async {
    try {
      await categoriesCollection.doc(category.id).update({
        'name': category.name,
        'description': category.description,
        'type': category.type,
        'displayOrder': category.displayOrder,
        'active': category.isActive,
        'color': category.color,
        'icon': category.icon,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  // Delete category (soft delete)
  static Future<void> deleteCategory(String categoryId) async {
    try {
      await categoriesCollection.doc(categoryId).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Toggle category status
  static Future<void> toggleCategoryStatus(
      String categoryId, bool isActive) async {
    try {
      await categoriesCollection.doc(categoryId).update({
        'active': !isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling category status: $e');
      rethrow;
    }
  }

  // Get category by ID
  static Future<ProductCategory?> getCategoryById(String categoryId) async {
    try {
      final doc = await categoriesCollection.doc(categoryId).get();
      if (doc.exists) {
        return ProductCategory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  // Get category statistics
  static Future<Map<String, dynamic>> getCategoryStats(String type) async {
    try {
      // Get categories - SIMPLIFIED
      final categoriesSnapshot = await categoriesCollection
          .where('type', isEqualTo: type)  // Single where clause
          .get();

      final categories = categoriesSnapshot.docs
          .map((doc) => ProductCategory.fromFirestore(doc))
          .where((category) => category.isActive)  // Filter in memory
          .toList();

      // Get products for each category - SIMPLIFIED
      final productsCollection = FirebaseConfig.firestore.collection('products');
      final productCounts = <String, int>{};

      for (final category in categories) {
        final productsSnapshot = await productsCollection
            .where('categoryId', isEqualTo: category.id)
            .get();  // Remove isActive filter from query

        // Filter in memory
        final activeProducts = productsSnapshot.docs.where((doc) {
          final data = doc.data();
          return data['active'] == true;
        }).length;

        productCounts[category.id] = activeProducts;
      }

      return {
        'categoryCount': categories.length,
        'categories': categories,
        'productCounts': productCounts,
      };
    } catch (e) {
      print('Error getting category stats: $e');
      return {
        'categoryCount': 0,
        'categories': [],
        'productCounts': {},
      };
    }
  }

  // Initialize default categories
  static Future<void> initializeDefaultCategories() async {
    try {
      // Check if categories already exist
      final snapshot = await categoriesCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      // Default categories
      const defaultCategories = [
        {
          'id': 'lechon',
          'name': 'Whole Lechon',
          'description': 'Whole roasted pig products',
          'type': 'product',
          'displayOrder': 1,
          'active': true,
          'color': '#c62828',
          'icon': 'fas fa-piggy-bank',
        },
        {
          'id': 'belly',
          'name': 'Lechon Belly',
          'description': 'Roasted pork belly products',
          'type': 'product',
          'displayOrder': 2,
          'active': true,
          'color': '#ff9800',
          'icon': 'fas fa-bacon',
        },
        {
          'id': 'drinks',
          'name': 'Drinks',
          'description': 'Beverages and drinks',
          'type': 'product',
          'displayOrder': 3,
          'active': true,
          'color': '#2196f3',
          'icon': 'fas fa-wine-bottle',
        },
        {
          'id': 'other',
          'name': 'Other Products',
          'description': 'Other food items',
          'type': 'product',
          'displayOrder': 4,
          'active': true,
          'color': '#4caf50',
          'icon': 'fas fa-utensils',
        },
        // Production inventory categories
        {
          'id': 'live_pigs',
          'name': 'Live Pigs',
          'description': 'Live pigs inventory',
          'type': 'inventory',
          'displayOrder': 1,
          'active': true,
          'color': '#8d6e63',
          'icon': 'fas fa-pig',
        },
        {
          'id': 'meat_cuts',
          'name': 'Meat Cuts',
          'description': 'Prepared meat cuts',
          'type': 'inventory',
          'displayOrder': 2,
          'active': true,
          'color': '#e53935',
          'icon': 'fas fa-drumstick-bite',
        },
      ];

      // Add default categories
      for (final category in defaultCategories) {
        await categoriesCollection.doc(category['id'] as String).set({
          ...category,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      print('Default categories initialized');
    } catch (e) {
      print('Error initializing default categories: $e');
    }
  }
}

class InventoryService {
  static final CollectionReference inventoryCollection = 
      FirebaseConfig.firestore.collection('inventory');
  
  static final CollectionReference categoriesCollection = 
      FirebaseConfig.firestore.collection('categories');

  // Get inventory categories stream
  static Stream<List<ProductCategory>> getInventoryCategoriesStream() {
    return categoriesCollection
        .where('type', isEqualTo: 'inventory')  // Single where clause
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .where((category) => category.isActive)  // Filter in memory
            .toList());
  }

  static Stream<List<ProductCategory>> getCategoriesByTypeStream(String type) {
    return categoriesCollection
        .where('type', isEqualTo: type)  // Single where clause
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .where((category) => category.isActive)  // Filter in memory
            .toList());
  }

  static Stream<List<ProductCategory>> getAllCategoriesStream() {
    return categoriesCollection
        .orderBy('type')  // Single orderBy
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromFirestore(doc))
            .where((category) => category.isActive)  // Filter in memory
            .toList());
  }

  static Future<void> addCategory(ProductCategory category) async {
    try {
      await categoriesCollection.doc(category.id).set({
        ...category.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding category: $e');
      rethrow;
    }
  }

  static Future<void> updateCategory(ProductCategory category) async {
    try {
      await categoriesCollection.doc(category.id).update({
        ...category.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  static Future<void> deleteCategory(String categoryId) async {
    try {
      await categoriesCollection.doc(categoryId).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  static Future<void> toggleCategoryStatus(
      String categoryId, bool isActive) async {
    try {
      await categoriesCollection.doc(categoryId).update({
        'active': !isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling category status: $e');
      rethrow;
    }
  }

  static Future<ProductCategory?> getCategoryById(String categoryId) async {
    try {
      final doc = await categoriesCollection.doc(categoryId).get();
      if (doc.exists) {
        return ProductCategory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getCategoryStats(String type) async {
    try {
      // Get categories
      final categoriesSnapshot = await categoriesCollection
          .where('type', isEqualTo: type)
          .where('active', isEqualTo: true)
          .get();

      final categories = categoriesSnapshot.docs
          .map((doc) => ProductCategory.fromFirestore(doc))
          .toList();

      // Get products for each category
      final productsCollection = FirebaseConfig.firestore.collection('products');
      final productCounts = <String, int>{};

      for (final category in categories) {
        final productsSnapshot = await productsCollection
            .where('categoryId', isEqualTo: category.id)
            .where('active', isEqualTo: true)
            .get();

        productCounts[category.id] = productsSnapshot.docs.length;
      }

      return {
        'categoryCount': categories.length,
        'categories': categories,
        'productCounts': productCounts,
      };
    } catch (e) {
      print('Error getting category stats: $e');
      return {
        'categoryCount': 0,
        'categories': [],
        'productCounts': {},
      };
    }
  }

  // Get all inventory items with category information
  static Stream<List<InventoryItem>> getInventoryItemsStream() {
    return inventoryCollection
        .orderBy('createdAt', descending: true)  // Remove isActive filter from query
        .snapshots()
        .asyncMap((snapshot) async {
      // Filter in memory
      final items = snapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .where((item) => item.isActive)
          .toList();

      // Fetch categories to get category names and colors
      final categoriesSnapshot = await categoriesCollection
          .where('type', isEqualTo: 'inventory')
          .get();
      
      final categoryMap = {
        for (var doc in categoriesSnapshot.docs) 
          doc.id: ProductCategory.fromFirestore(doc)
      };

      // Update items with full category information
      for (var item in items) {
        final category = categoryMap[item.categoryId];
        if (category != null) {
          item.categoryName = category.name;
          // Use category color if item doesn't have one
          if (item.color.isEmpty || item.color == '#2196F3') {
            item.color = category.color;
          }
        }
      }

      return items;
    });
  }

  // Get low stock items
  static Stream<List<InventoryItem>> getLowStockItemsStream() {
    return inventoryCollection
        .orderBy('name')  // Remove multiple where clauses
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .where((item) => item.isActive && (item.status == 'Low Stock' || item.status == 'Critical'))
            .toList());
  }

  // Add inventory item
  static Future<void> addInventoryItem(InventoryItem item) async {
    try {
      await inventoryCollection.doc(item.id).set({
        ...item.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding inventory item: $e');
      rethrow;
    }
  }

  // Update inventory item
  static Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      await inventoryCollection.doc(item.id).update({
        ...item.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }

  // Delete inventory item (soft delete)
  static Future<void> deleteInventoryItem(String itemId) async {
    try {
      await inventoryCollection.doc(itemId).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting inventory item: $e');
      rethrow;
    }
  }

  // Toggle inventory item status
  static Future<void> toggleInventoryItemStatus(String itemId, bool isActive) async {
    try {
      await inventoryCollection.doc(itemId).update({
        'active': !isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling inventory item status: $e');
      rethrow;
    }
  }

  // Restock inventory item
  static Future<void> restockInventoryItem(
      String itemId, double quantity, double? newUnitCost) async {
    try {
      final doc = await inventoryCollection.doc(itemId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentStock = (data['currentStock'] ?? 0).toDouble();
        final unitCost = newUnitCost ?? (data['unitCost'] ?? 0).toDouble();
        final minimumStock = (data['minimumStock'] ?? 0).toDouble();
        final newStock = currentStock + quantity;
        final newStatus = _calculateStatus(newStock, minimumStock);

        await inventoryCollection.doc(itemId).update({
          'currentStock': newStock,
          'unitCost': unitCost,
          'lastRestocked': FieldValue.serverTimestamp(),
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error restocking inventory item: $e');
      rethrow;
    }
  }

  // Get inventory item by ID
  static Future<InventoryItem?> getInventoryItemById(String itemId) async {
    try {
      final doc = await inventoryCollection.doc(itemId).get();
      if (doc.exists) {
        return InventoryItem.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting inventory item by ID: $e');
      return null;
    }
  }

  // Search inventory items
  static Stream<List<InventoryItem>> searchInventoryItems(String query) {
    return inventoryCollection
        .orderBy('name')  // Remove isActive filter from query
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

  // Get inventory statistics
  static Future<Map<String, dynamic>> getInventoryStatistics() async {
    try {
      final snapshot = await inventoryCollection
          .orderBy('name')  // Remove isActive filter from query
          .get();
      
      // Filter in memory
      final items = snapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .where((item) => item.isActive)
          .toList();

      final totalValue = items.fold(0.0, (sum, item) => sum + item.stockValue);
      final totalItems = items.length;
      final lowStockCount = items.where((item) => item.needsReorder).length;
      final outOfStockCount = items.where((item) => item.currentStock <= 0).length;

      // Group by category
      final categoryBreakdown = <String, double>{};
      for (final item in items) {
        final category = item.categoryName;
        categoryBreakdown[category] =
            (categoryBreakdown[category] ?? 0) + item.stockValue;
      }

      return {
        'totalValue': totalValue,
        'totalItems': totalItems,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'categoryBreakdown': categoryBreakdown,
        'items': items,
      };
    } catch (e) {
      print('Error getting inventory statistics: $e');
      return {
        'totalValue': 0,
        'totalItems': 0,
        'lowStockCount': 0,
        'outOfStockCount': 0,
        'categoryBreakdown': {},
        'items': [],
      };
    }
  }

  // Consume inventory for production/sales
  static Future<void> consumeInventory(
      Map<String, double> consumptionMap, String reason) async {
    try {
      final batch = FirebaseConfig.firestore.batch();

      for (final entry in consumptionMap.entries) {
        final itemId = entry.key;
        final quantity = entry.value;

        final doc = await inventoryCollection.doc(itemId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final currentStock = (data['currentStock'] ?? 0).toDouble();
          final minimumStock = (data['minimumStock'] ?? 0).toDouble();
          final newStock = currentStock - quantity;
          final newStatus = _calculateStatus(newStock, minimumStock);

          final itemRef = inventoryCollection.doc(itemId);
          batch.update(itemRef, {
            'currentStock': newStock >= 0 ? newStock : 0,
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      
      // Log the consumption in a separate collection
      await _logInventoryConsumption(consumptionMap, reason);
    } catch (e) {
      print('Error consuming inventory: $e');
      rethrow;
    }
  }

  // Helper method to calculate status based on stock levels
    static String _calculateStatus(double currentStock, double minimumStock) {
    if (currentStock <= 0) {
      return 'Out of Stock';
    } else if (currentStock <= minimumStock) {
      return 'Low Stock';
    } else {
      return 'In Stock';
    }
  }

  // Log inventory consumption for tracking
  static Future<void> _logInventoryConsumption(
      Map<String, double> consumptionMap, String reason) async {
    try {
      final logsCollection = FirebaseConfig.firestore.collection('inventory_logs');
      await logsCollection.add({
        'type': 'consumption',
        'items': consumptionMap,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging inventory consumption: $e');
    }
  }

  // Initialize default inventory items
  static Future<void> initializeDefaultInventory() async {
    try {
      // Check if inventory already exists
      final snapshot = await inventoryCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      // Get inventory categories
      final categoriesSnapshot = await categoriesCollection
          .where('type', isEqualTo: 'inventory')
          .get();
      
      if (categoriesSnapshot.docs.isEmpty) {
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
      ];

      // Add default items
      for (var i = 0; i < defaultItems.length; i++) {
        final item = defaultItems[i];
        // Assign to first category found, or create default category
        final categoryId = categoriesSnapshot.docs.isNotEmpty 
            ? categoriesSnapshot.docs[0].id 
            : 'default_inventory';
        
        final categoryDoc = await categoriesCollection.doc(categoryId).get();
        final categoryName = categoryDoc.exists 
            ? (categoryDoc.data() as Map<String, dynamic>)['name'] ?? 'Inventory'
            : 'Inventory';

        final inventoryItem = InventoryItem(
          id: 'inv_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: item['name'] as String,
          categoryId: categoryId,
          categoryName: categoryName,
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