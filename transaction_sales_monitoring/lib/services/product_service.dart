// lib/services/product_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/category_model.dart';
import '../models/product.dart';
import 'category_service.dart';

class ProductService {
  static CollectionReference get productsCollection => 
      FirebaseConfig.firestore.collection('products');

  // Get all products
  static Stream<List<Product>> getProducts() {
    return productsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList()); // Don't filter here, filter in UI
  }

  // Get products by category
  static Stream<List<Product>> getProductsByCategory(String categoryId) {
    return productsCollection
        .where('categoryId', isEqualTo: categoryId)  // Single where clause
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs
                .map((doc) => Product.fromFirestore(doc))
                .where((product) => product.isActive)  // Filter in memory
                .toList());
  }

  // Get low stock products
  static Stream<List<Product>> getLowStockProducts() {
    return productsCollection
        .orderBy('name')  // Remove isActive filter
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) => product.isActive && product.needsReorder)  // Filter in memory
            .toList());
  }

  // Get featured products (for POS)
  static Stream<List<Product>> getFeaturedProducts() {
    return productsCollection
        .orderBy('stock', descending: true)  // Remove isActive filter
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) => product.isActive && product.stock > 0)  // Filter in memory
            .toList());
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
        'categoryId': product.categoryId,
        'description': product.description,
        'price': product.price,
        'cost': product.cost,
        'unit': product.unit,
        'stock': product.stock,
        'reorderLevel': product.reorderLevel,
        'image': product.image,
        'kls': product.kls,
        'ingredients': product.ingredients,
        'active': product.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Update stock (for POS sales)
  static Future<void> updateStock(String productId, int quantityChange) async {
    try {
      final doc = await productsCollection.doc(productId).get();
      if (!doc.exists) throw Exception('Product not found');

      final data = doc.data() as Map<String, dynamic>;
      final currentStock = (data['stock'] ?? 0).toInt();
      final newStock = currentStock + quantityChange;

      await productsCollection.doc(productId).update({
        'stock': newStock >= 0 ? newStock : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating stock: $e');
      rethrow;
    }
  }

  // Sell product (for POS - updates stock)
  static Future<void> sellProduct(String productId, int quantity) async {
    return updateStock(productId, -quantity);
  }

  // Restock product
  static Future<void> restockProduct(String productId, int quantity) async {
    return updateStock(productId, quantity);
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
        .orderBy('name')  // Remove isActive filter
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) =>
                product.isActive &&  // Filter in memory
                (product.name.toLowerCase().contains(query.toLowerCase()) ||
                 (product.description ?? '').toLowerCase().contains(query.toLowerCase())))
            .toList());
  }

  // Get product by ID
  static Future<Product?> getProduct(String productId) async {
    try {
      final doc = await productsCollection.doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
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
          .orderBy('name')  // Remove isActive filter
          .get();
      
      // Filter in memory
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

      return {
        'totalProducts': totalProducts,
        'lowStockProducts': lowStockProducts,
        'outOfStockProducts': outOfStockProducts,
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
        'totalCostValue': 0,
        'totalRetailValue': 0,
        'totalPotentialProfit': 0,
      };
    }
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

      // Create default products - FIXED TYPES
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
          'ingredients': ['pig', 'spices', 'charcoal'],
          'categoryId': 'lechon',
        },
        {
          'name': 'Whole Lechon (Medium)',
          'description': 'Medium whole roasted pig, serves 20-25 people',
          'price': 8000.0,
          'cost': 5000.0,
          'unit': 'head',
          'stock': 3,
          'reorderLevel': 1,
          'image': null,
          'kls': '20-25kg',
          'ingredients': ['pig', 'spices', 'charcoal'],
          'categoryId': 'lechon',
        },
        {
          'name': 'Lechon Belly (Regular)',
          'description': 'Roasted pork belly, serves 5-8 people',
          'price': 1500.0,
          'cost': 800.0,
          'unit': 'roll',
          'stock': 10,
          'reorderLevel': 3,
          'image': null,
          'kls': '2-3kg',
          'ingredients': ['pork belly', 'spices', 'charcoal'],
          'categoryId': 'belly',
        },
        {
          'name': 'Lechon Belly (Spicy)',
          'description': 'Spicy roasted pork belly, serves 5-8 people',
          'price': 1800.0,
          'cost': 900.0,
          'unit': 'roll',
          'stock': 8,
          'reorderLevel': 2,
          'image': null,
          'kls': '2-3kg',
          'ingredients': ['pork belly', 'spices', 'chili', 'charcoal'],
          'categoryId': 'belly',
        },
        {
          'name': 'Softdrinks (1.5L)',
          'description': '1.5 liter softdrinks',
          'price': 80.0,
          'cost': 40.0,
          'unit': 'bottle',
          'stock': 50,
          'reorderLevel': 10,
          'image': null,
          'kls': '1.5L',
          'ingredients': ['soda', 'sugar', 'water'],
          'categoryId': 'drinks',
        },
        {
          'name': 'Bottled Water (500ml)',
          'description': '500ml bottled water',
          'price': 20.0,
          'cost': 8.0,
          'unit': 'bottle',
          'stock': 100,
          'reorderLevel': 20,
          'image': null,
          'kls': '500ml',
          'ingredients': ['water'],
          'categoryId': 'drinks',
        },
      ];

      // Add default products
      for (var i = 0; i < defaultProducts.length; i++) {
        final Map<String, dynamic> productData = defaultProducts[i]; // Explicit type
        
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

        final product = Product(
          id: 'prod_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: productData['name'] as String, // Cast to String
          categoryId: category.id,
          description: productData['description'] as String, // Cast to String
          price: productData['price'] as double, // Cast to double
          cost: productData['cost'] as double, // Cast to double
          unit: productData['unit'] as String, // Cast to String
          stock: productData['stock'] as int, // Cast to int
          reorderLevel: productData['reorderLevel'] as int, // Cast to int
          image: productData['image'] as String?, // Explicit cast to String?
          kls: productData['kls'] as String, // Cast to String
          ingredients: productData['ingredients'] as List<dynamic>, // Cast to List<dynamic>
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