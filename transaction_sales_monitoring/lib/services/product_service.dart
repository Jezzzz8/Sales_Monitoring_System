// lib/services/product_service.dart - UPDATED with import alias
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/category_model.dart';
import '../models/product.dart';
import '../models/inventory.dart'; // Add this import
import 'category_service.dart';
import 'inventory_service.dart' as inventory_service; // Add alias to avoid conflict

class ProductService {
  static CollectionReference get productsCollection => 
      FirebaseConfig.firestore.collection('products');

  // Get all products with inventory information
  static Stream<List<Product>> getProducts() {
    return productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      
      // Enhance products with inventory data
      return await _enhanceProductsWithInventory(products);
    });
  }

  // Get products by category with inventory information
  static Stream<List<Product>> getProductsByCategory(String categoryId) {
    return productsCollection
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) => product.isActive)
          .toList();
      
      return await _enhanceProductsWithInventory(products);
    });
  }

  // Get low stock products
  static Stream<List<Product>> getLowStockProducts() {
    return productsCollection
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) => product.isActive && product.needsReorder)
          .toList();
      
      return await _enhanceProductsWithInventory(products);
    });
  }

  // Get products that can be produced (all ingredients in stock)
  static Stream<List<Product>> getProducibleProducts() {
    return productsCollection
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) => product.isActive)
          .toList();
      
      final enhancedProducts = await _enhanceProductsWithInventory(products);
      return enhancedProducts.where((product) => product.hasAllIngredients).toList();
    });
  }

  // Get products that cannot be produced (missing ingredients)
  static Stream<List<Product>> getNonProducibleProducts() {
    return productsCollection
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) => product.isActive)
          .toList();
      
      final enhancedProducts = await _enhanceProductsWithInventory(products);
      return enhancedProducts.where((product) => !product.hasAllIngredients).toList();
    });
  }

  // Create product
  static Future<void> createProduct(Product product) async {
    try {
      await productsCollection.doc(product.id).set(product.toFirestore());
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  // Update product
  static Future<void> updateProduct(Product product) async {
    try {
      await productsCollection.doc(product.id).update({
        'name': product.name,
        'category': product.category,
        'categoryId': product.categoryId,
        'description': product.description,
        'price': product.price,
        'cost': product.cost,
        'unit': product.unit,
        'stock': product.stock,
        'reorderLevel': product.reorderLevel,
        'image': product.image,
        'kls': product.kls,
        'ingredients': product.ingredients?.map((ing) => ing.toMap()).toList() ?? [],
        'active': product.isActive,
        'supplier': product.supplier ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Update stock (for POS sales) - also consumes ingredients
  static Future<void> updateStock(String productId, int quantityChange, {bool consumeIngredients = true}) async {
    try {
      final doc = await productsCollection.doc(productId).get();
      if (!doc.exists) throw Exception('Product not found');

      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['stock'] ?? 0).toInt();
      final newStock = currentStock + quantityChange;
      final dependsOnInventory = data['dependsOnInventory'] ?? false;

      // Only consume ingredients if the product depends on inventory AND consumeIngredients is true
      if (quantityChange > 0 && consumeIngredients && dependsOnInventory) {
        final product = Product.fromFirestore(doc);
        if (product.ingredients != null && product.ingredients!.isNotEmpty) {
          await inventory_service.InventoryService.consumeInventoryForProduct(product, quantityChange);
        }
      }

      await productsCollection.doc(productId).update({
        'stock': newStock >= 0 ? newStock : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }

  // Sell product (for POS - updates stock and optionally consumes ingredients)
  static Future<void> sellProduct(String productId, int quantity, {bool consumeIngredients = true}) async {
    return updateStock(productId, -quantity, consumeIngredients: consumeIngredients);
  }

  // Produce product (increase stock and consume ingredients)
  static Future<void> produceProduct(String productId, int quantity) async {
    return updateStock(productId, quantity, consumeIngredients: true);
  }

  // Restock product (increase stock without consuming ingredients)
  static Future<void> restockProduct(String productId, int quantity) async {
    return updateStock(productId, quantity, consumeIngredients: false);
  }

  // Delete product (soft delete)
  static Future<void> deleteProduct(String productId) async {
    try {
      await productsCollection.doc(productId).update({
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  // Search products
  static Stream<List<Product>> searchProducts(String query) {
    return productsCollection
        .orderBy('name')
        .snapshots()
        .asyncMap((snapshot) async {
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) =>
              product.isActive &&
              (product.name.toLowerCase().contains(query.toLowerCase()) ||
               (product.description).toLowerCase().contains(query.toLowerCase())))
          .toList();
      
      return await _enhanceProductsWithInventory(products);
    });
  }

  // Get product by ID with inventory information
  static Future<Product?> getProduct(String productId) async {
    try {
      final doc = await productsCollection.doc(productId).get();
      if (doc.exists) {
        final product = Product.fromFirestore(doc);
        return await _enhanceProductWithInventory(product);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Get product statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final snapshot = await productsCollection
          .orderBy('name')
          .get();
      
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((product) => product.isActive)
          .toList();

      int totalProducts = products.length;
      int lowStockProducts = products.where((p) => p.needsReorder).length;
      int outOfStockProducts = products.where((p) => p.stock <= 0).length;
      double totalCostValue = products.fold(0.0, (sum, p) => sum + (p.stock * p.cost));
      double totalRetailValue = products.fold(0.0, (sum, p) => sum + (p.stock * p.price));
      double totalPotentialProfit = totalRetailValue - totalCostValue;

      // Get producible products
      final enhancedProducts = await _enhanceProductsWithInventory(products);
      int producibleProducts = enhancedProducts.where((p) => p.hasAllIngredients).length;
      int nonProducibleProducts = totalProducts - producibleProducts;

      return {
        'totalProducts': totalProducts,
        'lowStockProducts': lowStockProducts,
        'outOfStockProducts': outOfStockProducts,
        'producibleProducts': producibleProducts,
        'nonProducibleProducts': nonProducibleProducts,
        'totalCostValue': totalCostValue,
        'totalRetailValue': totalRetailValue,
        'totalPotentialProfit': totalPotentialProfit,
      };
    } catch (e) {
      print('Error getting product statistics: $e');
      return {
        'totalProducts': 0,
        'lowStockProducts': 0,
        'outOfStockProducts': 0,
        'producibleProducts': 0,
        'nonProducibleProducts': 0,
        'totalCostValue': 0,
        'totalRetailValue': 0,
        'totalPotentialProfit': 0,
      };
    }
  }
  
  // Helper method to enhance products with inventory data
  static Future<List<Product>> _enhanceProductsWithInventory(List<Product> products) async {
    if (products.isEmpty) return products;
    
    // Get all inventory items using the alias
    final inventorySnapshot = await inventory_service.InventoryService.inventoryCollection.get();
    final inventoryItems = inventorySnapshot.docs
        .map((doc) => InventoryItem.fromFirestore(doc))
        .where((item) => item.isActive)
        .toList();
    
    // Create inventory map for quick lookup
    final inventoryMap = {for (var item in inventoryItems) item.id: item};
    
    // Enhance each product
    return products.map((product) {
      if (product.ingredients == null) return product;
      
      final enhancedIngredients = product.ingredients!.map((ingredient) {
        return ProductIngredient(
          inventoryId: ingredient.inventoryId,
          inventoryName: ingredient.inventoryName,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          unitCost: ingredient.unitCost,
          inventoryItem: inventoryMap[ingredient.inventoryId] != null 
            ? InventoryItemData(
                id: inventoryMap[ingredient.inventoryId]!.id,
                name: inventoryMap[ingredient.inventoryId]!.name,
                currentStock: inventoryMap[ingredient.inventoryId]!.currentStock,
                unit: inventoryMap[ingredient.inventoryId]!.unit,
                unitCost: inventoryMap[ingredient.inventoryId]!.unitCost,
              )
            : null,
        );
      }).toList();
      
      return product.copyWith(ingredients: enhancedIngredients);
    }).toList();
  }
  
  // Helper method to enhance single product with inventory data
  static Future<Product> _enhanceProductWithInventory(Product product) async {
    if (product.ingredients == null) return product;
    
    // Get inventory items for this product's ingredients
    final inventoryIds = product.ingredients!.map((ing) => ing.inventoryId).toList();
    
    if (inventoryIds.isEmpty) return product;
    
    // Use the alias to access the inventory collection
    final inventorySnapshot = await inventory_service.InventoryService.inventoryCollection
        .where('id', whereIn: inventoryIds)
        .get();
    
    final inventoryItems = inventorySnapshot.docs
        .map((doc) => InventoryItem.fromFirestore(doc))
        .where((item) => item.isActive)
        .toList();
    
    final inventoryMap = {for (var item in inventoryItems) item.id: item};
    
    final enhancedIngredients = product.ingredients!.map((ingredient) {
      return ProductIngredient(
        inventoryId: ingredient.inventoryId,
        inventoryName: ingredient.inventoryName,
        quantity: ingredient.quantity,
        unit: ingredient.unit,
        unitCost: ingredient.unitCost,
        inventoryItem: inventoryMap[ingredient.inventoryId] != null 
          ? InventoryItemData(
              id: inventoryMap[ingredient.inventoryId]!.id,
              name: inventoryMap[ingredient.inventoryId]!.name,
              currentStock: inventoryMap[ingredient.inventoryId]!.currentStock,
              unit: inventoryMap[ingredient.inventoryId]!.unit,
              unitCost: inventoryMap[ingredient.inventoryId]!.unitCost,
            )
          : null,
      );
    }).toList();
    
    return product.copyWith(ingredients: enhancedIngredients);
  }
  
  // Initialize default products
  static Future<void> initializeDefaultProducts() async {
    try {
      // Check if products already exist
      final snapshot = await productsCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      // Get product categories
      final categories = await CategoryService.getCategoriesByTypeStream('product').first;
      
      if (categories.isEmpty) {
        print('No product categories found. Please create categories first.');
        return;
      }

      // Get inventory items for ingredients using alias
      final inventorySnapshot = await inventory_service.InventoryService.inventoryCollection.get();
      final inventoryItems = inventorySnapshot.docs
          .map((doc) => InventoryItem.fromFirestore(doc))
          .toList();

      // Create default products with ingredients
      final List<Map<String, dynamic>> defaultProducts = [
        {
          'name': 'Whole Lechon (Small)',
          'description': 'Small whole roasted pig, serves 10-15 people',
          'price': 5000.0,
          'cost': 3000.0,
          'unit': 'head',
          'stock': 5,
          'reorderLevel': 2,
          'image': null,
          'kls': '10-15kg',
          'categoryId': 'lechon',
          'ingredients': [
            {
              'inventoryId': inventoryItems.isNotEmpty ? inventoryItems[0].id : '',
              'inventoryName': inventoryItems.isNotEmpty ? inventoryItems[0].name : 'Live Pig',
              'quantity': 1.0,
              'unit': 'head',
              'unitCost': inventoryItems.isNotEmpty ? inventoryItems[0].unitCost : 5000.0,
            },
            {
              'inventoryId': inventoryItems.length > 2 ? inventoryItems[2].id : '',
              'inventoryName': inventoryItems.length > 2 ? inventoryItems[2].name : 'Charcoal',
              'quantity': 10.0,
              'unit': 'kg',
              'unitCost': inventoryItems.length > 2 ? inventoryItems[2].unitCost : 50.0,
            },
          ],
        },
        {
          'name': 'Lechon Belly',
          'description': 'Roasted pork belly with special spices',
          'price': 1500.0,
          'cost': 800.0,
          'unit': 'kg',
          'stock': 10,
          'reorderLevel': 5,
          'image': null,
          'kls': '1-2kg',
          'categoryId': 'belly',
          'ingredients': [
            {
              'inventoryId': inventoryItems.isNotEmpty ? inventoryItems[0].id : '',
              'inventoryName': inventoryItems.isNotEmpty ? inventoryItems[0].name : 'Live Pig',
              'quantity': 0.5,
              'unit': 'head',
              'unitCost': inventoryItems.isNotEmpty ? inventoryItems[0].unitCost : 5000.0,
            },
            {
              'inventoryId': inventoryItems.length > 3 ? inventoryItems[3].id : '',
              'inventoryName': inventoryItems.length > 3 ? inventoryItems[3].name : 'Cooking Oil',
              'quantity': 2.0,
              'unit': 'liter',
              'unitCost': inventoryItems.length > 3 ? inventoryItems[3].unitCost : 80.0,
            },
          ],
        },
      ];

      // Add default products
      for (var i = 0; i < defaultProducts.length; i++) {
        final productData = defaultProducts[i];
        
        // Find category
        final category = categories.firstWhere(
          (cat) => cat.id == productData['categoryId'],
          orElse: () => categories.isNotEmpty ? categories[0] : ProductCategory(
            id: 'other',
            name: 'Other',
            type: 'product',
            createdAt: DateTime.now(),
          ),
        );

        // Parse ingredients
        final List<ProductIngredient> ingredients = (productData['ingredients'] as List<dynamic>)
            .map((item) => ProductIngredient.fromMap(item as Map<String, dynamic>))
            .toList();

        final product = Product(
          id: 'prod_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: productData['name'] as String,
          category: category.name,
          categoryId: category.id,
          description: productData['description'] as String,
          price: productData['price'] as double,
          cost: productData['cost'] as double,
          unit: productData['unit'] as String,
          stock: productData['stock'] as int,
          reorderLevel: productData['reorderLevel'] as int,
          image: productData['image'] as String?,
          kls: productData['kls'] as String,
          ingredients: ingredients,
          isActive: true,
          createdAt: DateTime.now(),
        );

        await productsCollection.doc(product.id).set(product.toFirestore());
      }

      print('Default products initialized');
    } catch (e) {
      print('Error initializing default products: $e');
    }
  }
}