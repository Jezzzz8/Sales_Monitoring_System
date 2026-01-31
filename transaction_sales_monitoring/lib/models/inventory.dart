class InventoryItem {
  String id;
  String name;
  String category;
  String unit;
  double currentStock;
  double minimumStock;
  double reorderQuantity;
  double unitCost;
  DateTime lastRestocked;
  DateTime? nextRestockDate;
  String status;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    required this.reorderQuantity,
    required this.unitCost,
    required this.lastRestocked,
    this.nextRestockDate,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'reorderQuantity': reorderQuantity,
      'unitCost': unitCost,
      'lastRestocked': lastRestocked.toIso8601String(),
      'nextRestockDate': nextRestockDate?.toIso8601String(),
      'status': status,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      unit: map['unit'],
      currentStock: map['currentStock'].toDouble(),
      minimumStock: map['minimumStock'].toDouble(),
      reorderQuantity: map['reorderQuantity'].toDouble(),
      unitCost: map['unitCost'].toDouble(),
      lastRestocked: DateTime.parse(map['lastRestocked']),
      nextRestockDate: map['nextRestockDate'] != null ? DateTime.parse(map['nextRestockDate']) : null,
      status: map['status'],
    );
  }

  bool get needsReorder => currentStock <= minimumStock;
  double get stockValue => currentStock * unitCost;
}