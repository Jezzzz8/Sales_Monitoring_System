// lib/services/inventory_service.dart - UPDATED with product integration
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/category_model.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import 'category_service.dart';

class InventoryService {
  static CollectionReference get inventoryCollection => 
      FirebaseConfig.firestore.collection('inventory');
  
  static CollectionReference get inventoryLogsCollection => 
      FirebaseConfig.firestore.collection('inventory_logs');
  
  static CollectionReference get productsCollection => 
      FirebaseConfig.firestore.collection('products');

  // Get all inventory items
  static Stream<List<InventoryItem>> getInventoryItems() {
    return inventoryCollection
        .orderBy('createdAt', descending: true)
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
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .where((item) => item.isActive)
            .toList());
  }

  // Get low stock items
  static Stream<List<InventoryItem>> getLowStockItems() {
    return inventoryCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .where((item) => item.isActive && item.needsReorder)
            .toList());
  }

  // Add inventory item
  static Future<void> createInventoryItem(InventoryItem item) async {
    try {
      await inventoryCollection.doc(item.id).set(item.toFirestore());
      
      // Log the inventory creation
      await _logInventoryAction(
        itemId: item.id,
        itemName: item.name,
        action: 'Stock In (Create)',
        changeAmount: item.currentStock,
        remainingStock: item.currentStock,
        notes: 'Initial stock',
      );
    } catch (e) {
      print('Error creating inventory item: $e');
      rethrow;
    }
  }

  // Update inventory item
  static Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      // Get current stock before update
      final currentDoc = await inventoryCollection.doc(item.id).get();
      final currentData = currentDoc.data() as Map<String, dynamic>;
      final oldStock = (currentData['currentStock'] ?? 0).toDouble();
      final stockChange = item.currentStock - oldStock;
      
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
        'active': item.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log the inventory update if stock changed
      if (stockChange != 0) {
        await _logInventoryAction(
          itemId: item.id,
          itemName: item.name,
          action: 'Stock In (Edit)',
          changeAmount: stockChange,
          remainingStock: item.currentStock,
          notes: 'Manual adjustment',
        );
      }
    } catch (e) {
      print('Error updating inventory item: $e');
      rethrow;
    }
  }

  // Restock inventory
  static Future<void> restockItem(String itemId, double quantity, {double? newUnitCost, String? notes}) async {
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
      
      // Log the restock
      await _logInventoryAction(
        itemId: itemId,
        itemName: data['name'] ?? 'Unknown',
        action: 'Restock',
        changeAmount: quantity,
        remainingStock: newStock,
        notes: notes ?? 'Regular restock',
      );
    } catch (e) {
      print('Error restocking item: $e');
      rethrow;
    }
  }

  // Consume inventory for production/sales
  static Future<void> consumeInventoryForProduct(Product product, int quantity) async {
    try {
      if (product.ingredients == null || product.ingredients!.isEmpty) {
        throw Exception('Product has no ingredients defined');
      }
      
      final batch = FirebaseConfig.firestore.batch();
      final consumptionLogs = <Map<String, dynamic>>[];
      
      for (final ingredient in product.ingredients!) {
        final itemId = ingredient.inventoryId;
        final requiredQuantity = ingredient.quantity * quantity;
        
        final doc = await inventoryCollection.doc(itemId).get();
        if (!doc.exists) {
          throw Exception('Inventory item ${ingredient.inventoryName} not found');
        }

        final data = doc.data() as Map<String, dynamic>;
        final currentStock = (data['currentStock'] ?? 0).toDouble();
        final minimumStock = (data['minimumStock'] ?? 0).toDouble();
        final newStock = currentStock - requiredQuantity;
        
        if (newStock < 0) {
          throw Exception('Insufficient stock for ${ingredient.inventoryName}. Required: $requiredQuantity, Available: $currentStock');
        }
        
        final status = _calculateStatus(newStock, minimumStock);
        final itemRef = inventoryCollection.doc(itemId);
        
        batch.update(itemRef, {
          'currentStock': newStock,
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        consumptionLogs.add({
          'itemId': itemId,
          'itemName': ingredient.inventoryName,
          'changeAmount': -requiredQuantity,
          'remainingStock': newStock,
        });
      }

      await batch.commit();
      
      // Log the consumption
      await _logInventoryConsumption(
        productId: product.id,
        productName: product.name,
        quantity: quantity,
        itemsConsumed: consumptionLogs,
        notes: 'Production for ${product.name} x$quantity',
      );
      
    } catch (e) {
      print('Error consuming inventory for product: $e');
      rethrow;
    }
  }

  // Consume inventory (for production/sales) - generic version
  static Future<void> consumeItem(String itemId, double quantity, {String? reason}) async {
    try {
      final doc = await inventoryCollection.doc(itemId).get();
      if (!doc.exists) throw Exception('Item not found');

      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['currentStock'] ?? 0).toDouble();
      final minimumStock = (data['minimumStock'] ?? 0).toDouble();
      final newStock = currentStock - quantity;
      
      if (newStock < 0) {
        throw Exception('Insufficient stock. Available: $currentStock, Required: $quantity');
      }
      
      final status = _calculateStatus(newStock, minimumStock);

      await inventoryCollection.doc(itemId).update({
        'currentStock': newStock,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log the consumption
      await _logInventoryAction(
        itemId: itemId,
        itemName: data['name'] ?? 'Unknown',
        action: 'Consumption',
        changeAmount: -quantity,
        remainingStock: newStock,
        notes: reason ?? 'Manual consumption',
      );
    } catch (e) {
      print('Error consuming item: $e');
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

  // Get inventory statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final snapshot = await inventoryCollection
          .orderBy('name')
          .get();
      
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
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryItem.fromFirestore(doc))
            .where((item) =>
                item.isActive &&
                (item.name.toLowerCase().contains(query.toLowerCase()) ||
                 item.categoryName.toLowerCase().contains(query.toLowerCase()) ||
                 (item.description ?? '').toLowerCase().contains(query.toLowerCase())))
            .toList());
  }

  // Get inventory logs for an item
  static Stream<List<InventoryLog>> getInventoryLogs(String itemId) {
    return inventoryLogsCollection
        .where('itemId', isEqualTo: itemId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryLog.fromFirestore(doc))
            .toList());
  }

  // Get recent inventory logs
  static Stream<List<InventoryLog>> getRecentInventoryLogs({int limit = 50}) {
    return inventoryLogsCollection
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InventoryLog.fromFirestore(doc))
            .toList());
  }

  // Helper method to calculate status
  static String _calculateStatus(double currentStock, double minimumStock) {
    if (currentStock <= 0) return 'Out of Stock';
    if (currentStock <= minimumStock * 1.2) return 'Low Stock';
    if (currentStock <= minimumStock) return 'Critical';
    return 'In Stock';
  }

  // Private method to log inventory actions
  static Future<void> _logInventoryAction({
    required String itemId,
    required String itemName,
    required String action,
    required double changeAmount,
    required double remainingStock,
    String? notes,
    String user = 'System',
  }) async {
    try {
      await inventoryLogsCollection.add({
        'itemId': itemId,
        'itemName': itemName,
        'action': action,
        'changeAmount': changeAmount,
        'remainingStock': remainingStock,
        'user': user,
        'notes': notes ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging inventory action: $e');
    }
  }

  // Private method to log inventory consumption for products
  static Future<void> _logInventoryConsumption({
    required String productId,
    required String productName,
    required int quantity,
    required List<Map<String, dynamic>> itemsConsumed,
    String? notes,
    String user = 'System',
  }) async {
    try {
      await inventoryLogsCollection.add({
        'productId': productId,
        'productName': productName,
        'action': 'Product Production',
        'quantity': quantity,
        'itemsConsumed': itemsConsumed,
        'user': user,
        'notes': notes ?? '',
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

// Inventory Log Model
class InventoryLog {
  final String id;
  final String itemId;
  final String itemName;
  final String action;
  final double changeAmount;
  final double remainingStock;
  final String user;
  final String notes;
  final DateTime timestamp;
  final String? productId;
  final String? productName;
  final int? quantity;
  final List<Map<String, dynamic>>? itemsConsumed;

  InventoryLog({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.action,
    required this.changeAmount,
    required this.remainingStock,
    required this.user,
    required this.notes,
    required this.timestamp,
    this.productId,
    this.productName,
    this.quantity,
    this.itemsConsumed,
  });

  factory InventoryLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return InventoryLog(
      id: doc.id,
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      action: data['action'] ?? '',
      changeAmount: (data['changeAmount'] ?? 0).toDouble(),
      remainingStock: (data['remainingStock'] ?? 0).toDouble(),
      user: data['user'] ?? 'System',
      notes: data['notes'] ?? '',
      productId: data['productId'],
      productName: data['productName'],
      quantity: data['quantity']?.toInt(),
      itemsConsumed: data['itemsConsumed'] != null 
          ? List<Map<String, dynamic>>.from(data['itemsConsumed'] as List)
          : null,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'action': action,
      'changeAmount': changeAmount,
      'remainingStock': remainingStock,
      'user': user,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}