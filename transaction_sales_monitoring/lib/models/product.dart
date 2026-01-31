class Product {
  final String id;
  final String name;
  final String categoryId; // Changed from category string to categoryId
  final String description;
  final double price;
  final String unit;
  final int stock;
  final int reorderLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String? imageUrl;
  final List<String>? ingredients; // List of production inventory IDs needed
  
  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.unit,
    required this.stock,
    this.reorderLevel = 0,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.imageUrl,
    this.ingredients,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'unit': unit,
      'stock': stock,
      'reorderLevel': reorderLevel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    double? price,
    String? unit,
    int? stock,
    int? reorderLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: category ?? this.categoryId,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['category'],
      description: map['description'],
      price: map['price'].toDouble(),
      unit: map['unit'],
      stock: map['stock'],
      reorderLevel: map['reorderLevel'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      isActive: map['isActive'],
    );
  }
  
  bool get needsReorder => stock <= reorderLevel;
}