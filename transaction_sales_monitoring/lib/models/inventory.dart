import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  String id;
  String name;
  String categoryId;
  String categoryName;
  String unit;
  double currentStock;
  double minimumStock;
  double reorderQuantity;
  double unitCost;
  DateTime lastRestocked;
  DateTime? nextRestockDate;
  String status;
  String color;
  String? description;
  bool isActive;
  DateTime createdAt;
  DateTime? updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName = '',
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    required this.reorderQuantity,
    required this.unitCost,
    required this.lastRestocked,
    this.nextRestockDate,
    required this.status,
    this.color = '#2196F3',
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // For backward compatibility
  String get category => categoryName;
  
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'unit': unit,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'reorderQuantity': reorderQuantity,
      'unitCost': unitCost,
      'lastRestocked': Timestamp.fromDate(lastRestocked),
      'nextRestockDate': nextRestockDate != null 
          ? Timestamp.fromDate(nextRestockDate!) 
          : null,
      'status': status,
      'color': color,
      'description': description ?? '',
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null 
          ? Timestamp.fromDate(updatedAt!) 
          : FieldValue.serverTimestamp(),
    };
  }

  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryItem(
      id: doc.id,
      name: data['name'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      unit: data['unit'] ?? '',
      currentStock: (data['currentStock'] ?? 0).toDouble(),
      minimumStock: (data['minimumStock'] ?? 0).toDouble(),
      reorderQuantity: (data['reorderQuantity'] ?? 0).toDouble(),
      unitCost: (data['unitCost'] ?? 0).toDouble(),
      lastRestocked: (data['lastRestocked'] as Timestamp).toDate(),
      nextRestockDate: data['nextRestockDate'] != null 
          ? (data['nextRestockDate'] as Timestamp).toDate()
          : null,
      status: data['status'] ?? 'In Stock',
      color: data['color'] ?? '#2196F3',
      description: data['description'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': categoryName,
      'unit': unit,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'reorderQuantity': reorderQuantity,
      'unitCost': unitCost,
      'lastRestocked': lastRestocked.toIso8601String(),
      'nextRestockDate': nextRestockDate?.toIso8601String(),
      'status': status,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      categoryId: map['categoryId'] ?? map['category'] ?? '',
      categoryName: map['categoryName'] ?? map['category'] ?? '',
      unit: map['unit'],
      currentStock: (map['currentStock'] ?? 0).toDouble(),
      minimumStock: (map['minimumStock'] ?? 0).toDouble(),
      reorderQuantity: (map['reorderQuantity'] ?? 0).toDouble(),
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      lastRestocked: DateTime.parse(map['lastRestocked']),
      nextRestockDate: map['nextRestockDate'] != null 
          ? DateTime.parse(map['nextRestockDate']) 
          : null,
      status: map['status'] ?? 'In Stock',
      color: map['color'] ?? '#2196F3',
      description: map['description'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  bool get needsReorder => currentStock <= minimumStock;
  double get stockValue => currentStock * unitCost;
  
  InventoryItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryName,
    String? unit,
    double? currentStock,
    double? minimumStock,
    double? reorderQuantity,
    double? unitCost,
    DateTime? lastRestocked,
    DateTime? nextRestockDate,
    String? status,
    String? color,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      reorderQuantity: reorderQuantity ?? this.reorderQuantity,
      unitCost: unitCost ?? this.unitCost,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      nextRestockDate: nextRestockDate ?? this.nextRestockDate,
      status: status ?? this.status,
      color: color ?? this.color,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}