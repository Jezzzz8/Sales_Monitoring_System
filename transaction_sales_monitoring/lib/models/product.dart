// lib/models/product.dart - UPDATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String categoryId;
  final String description;
  final double price;
  final double cost;
  final String unit;
  final int stock;
  final int reorderLevel;
  final String? image;
  final String? kls;
  final List<dynamic>? ingredients;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.categoryId,
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
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'cost': cost,
      'unit': unit,
      'stock': stock,
      'reorderLevel': reorderLevel,
      'image': image,
      'kls': kls,
      'ingredients': ingredients,
      'active': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      cost: (data['cost'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'pcs',
      stock: data['stock'] ?? 0,
      reorderLevel: data['reorderLevel'] ?? 0,
      image: data['image'],
      kls: data['kls'],
      ingredients: data['ingredients'],
      isActive: data['active'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      categoryId: map['category'],
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      cost: (map['cost'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'pcs',
      stock: map['stock'] ?? 0,
      reorderLevel: map['reorderLevel'] ?? 0,
      image: map['image'],
      kls: map['kls'],
      ingredients: map['ingredients'],
      isActive: map['active'] ?? true,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? description,
    double? price,
    double? cost,
    String? unit,
    int? stock,
    int? reorderLevel,
    String? image,
    String? kls,
    List<dynamic>? ingredients,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  bool get needsReorder => stock <= reorderLevel;
  double get margin => price - cost;
  double get marginPercentage => cost > 0 ? ((price - cost) / cost) * 100 : 0;
}