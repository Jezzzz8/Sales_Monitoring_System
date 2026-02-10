// lib/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCategory {
  final String id;
  final String name;
  final String description;
  final String type; // "inventory" or "product"
  final int displayOrder;
  final bool isActive;
  final String color;
  final String icon;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductCategory({
    required this.id,
    required this.name,
    this.description = '',
    required this.type,
    this.displayOrder = 0,
    this.isActive = true,
    this.color = '#2196F3',
    this.icon = '',
    required this.createdAt,
    this.updatedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory ProductCategory.fromMap(Map<String, dynamic> map, String id) {
    return ProductCategory(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'product',
      displayOrder: map['displayOrder']?.toInt() ?? 0,
      isActive: map['isActive'] ?? true,
      color: map['color'] ?? '#2196F3',
      icon: map['icon'] ?? '',
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']))
          : null,
    );
  }

  factory ProductCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductCategory.fromMap(data, doc.id);
  }

  ProductCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    int? displayOrder,
    bool? isActive,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : FieldValue.serverTimestamp(),
    };
  }
}