// lib/models/product.dart - UPDATED with fixed InventoryItem reference
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String category;
  final String categoryId;
  final String name;
  final String description;
  final double price;
  final double cost;
  final String unit;
  final int stock;
  final int reorderLevel;
  final String? image;
  final String? kls;
  final List<ProductIngredient>? ingredients;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? supplier;
  final bool dependsOnInventory; // ADD THIS

  Product({
    required this.id,
    required this.category,
    this.categoryId = '',
    required this.name,
    required this.description,
    required this.price,
    required this.cost,
    required this.unit,
    required this.stock,
    required this.reorderLevel,
    this.image,
    this.kls,
    this.ingredients,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.supplier,
    this.dependsOnInventory = false, // DEFAULT TO FALSE
  });

  // Update the toFirestore method:
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'cost': cost,
      'unit': unit,
      'stock': stock,
      'reorderLevel': reorderLevel,
      'image': image,
      'kls': kls,
      'ingredients': ingredients?.map((ing) => ing.toMap()).toList() ?? [],
      'active': isActive,
      'dependsOnInventory': dependsOnInventory, // ADD THIS
      'supplier': supplier ?? '',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Update the fromFirestore method:
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse ingredients
    List<ProductIngredient> ingredientsList = [];
    if (data['ingredients'] != null && data['ingredients'] is List) {
      ingredientsList = (data['ingredients'] as List<dynamic>)
          .map((item) => ProductIngredient.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      cost: (data['cost'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'pcs',
      stock: data['stock'] ?? 0,
      reorderLevel: data['reorderLevel'] ?? 0,
      image: data['image'],
      kls: data['kls'],
      ingredients: ingredientsList,
      isActive: data['active'] ?? true,
      dependsOnInventory: data['dependsOnInventory'] ?? false, // ADD THIS
      supplier: data['supplier'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  // Update the copyWith method:
  Product copyWith({
    String? id,
    String? category,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    double? cost,
    String? unit,
    int? stock,
    int? reorderLevel,
    String? image,
    String? kls,
    List<ProductIngredient>? ingredients,
    bool? isActive,
    bool? dependsOnInventory, // ADD THIS
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supplier,
  }) {
    return Product(
      id: id ?? this.id,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      image: image ?? this.image,
      kls: kls ?? this.kls,
      ingredients: ingredients ?? this.ingredients,
      isActive: isActive ?? this.isActive,
      dependsOnInventory: dependsOnInventory ?? this.dependsOnInventory, // ADD THIS
      supplier: supplier ?? this.supplier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  bool get needsReorder => stock <= reorderLevel;
  double get margin => price - cost;
  double get marginPercentage => cost > 0 ? ((price - cost) / cost) * 100 : 0;
  
  // Calculate total cost from ingredients
  double get totalIngredientCost {
    if (ingredients == null || ingredients!.isEmpty) return 0;
    return ingredients!.fold(0.0, (sum, ing) => sum + ing.totalCost);
  }
  
  // Check if product has all ingredients in stock
  bool get hasAllIngredients {
    if (ingredients == null || ingredients!.isEmpty) return true;
    return ingredients!.every((ing) => ing.isStockSufficient);
  }
  
  // Get low stock ingredients
  List<ProductIngredient> get lowStockIngredients {
    if (ingredients == null) return [];
    return ingredients!.where((ing) => !ing.isStockSufficient).toList();
  }
}

// Separate the InventoryItemData class to avoid dependency issues
class InventoryItemData {
  final String id;
  final String name;
  final double currentStock;
  final String unit;
  final double unitCost;
  
  InventoryItemData({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.unitCost,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentStock': currentStock,
      'unit': unit,
      'unitCost': unitCost,
    };
  }
}

class ProductIngredient {
  final String inventoryId;
  final String inventoryName;
  final double quantity;
  final String unit;
  final double unitCost;
  final InventoryItemData? inventoryItem; // Use InventoryItemData instead of InventoryItem
  
  ProductIngredient({
    required this.inventoryId,
    required this.inventoryName,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    this.inventoryItem,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'inventoryId': inventoryId,
      'inventoryName': inventoryName,
      'quantity': quantity,
      'unit': unit,
      'unitCost': unitCost,
      'inventoryItem': inventoryItem?.toMap(),
    };
  }
  
  factory ProductIngredient.fromMap(Map<String, dynamic> map) {
    InventoryItemData? inventoryItemData;
    if (map['inventoryItem'] != null) {
      final itemData = map['inventoryItem'] as Map<String, dynamic>;
      inventoryItemData = InventoryItemData(
        id: itemData['id'] ?? '',
        name: itemData['name'] ?? '',
        currentStock: (itemData['currentStock'] ?? 0).toDouble(),
        unit: itemData['unit'] ?? '',
        unitCost: (itemData['unitCost'] ?? 0).toDouble(),
      );
    }
    
    return ProductIngredient(
      inventoryId: map['inventoryId'] ?? '',
      inventoryName: map['inventoryName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      unit: map['unit'] ?? '',
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      inventoryItem: inventoryItemData,
    );
  }
  
  double get totalCost => quantity * unitCost;
  
  Object get hasEnoughStock {
    return inventoryItem?.currentStock ?? 0 >= quantity;
  }
  
  bool get isStockSufficient => hasEnoughStock is bool;
  
  double get availableQuantity => inventoryItem?.currentStock ?? 0;
  double get missingQuantity {
    final available = availableQuantity;
    return available >= quantity ? 0 : quantity - available;
  }
  
  String get stockStatus {
    if (isStockSufficient) return 'In Stock';
    return 'Low Stock (${missingQuantity.toStringAsFixed(2)} $unit needed)';
  }
}