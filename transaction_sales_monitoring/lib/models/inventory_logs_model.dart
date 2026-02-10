// lib/models/inventory_logs_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'itemsConsumed': itemsConsumed,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'action': action,
      'changeAmount': changeAmount,
      'remainingStock': remainingStock,
      'user': user,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'itemsConsumed': itemsConsumed,
    };
  }

  InventoryLog copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? action,
    double? changeAmount,
    double? remainingStock,
    String? user,
    String? notes,
    DateTime? timestamp,
    String? productId,
    String? productName,
    int? quantity,
    List<Map<String, dynamic>>? itemsConsumed,
  }) {
    return InventoryLog(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      action: action ?? this.action,
      changeAmount: changeAmount ?? this.changeAmount,
      remainingStock: remainingStock ?? this.remainingStock,
      user: user ?? this.user,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      itemsConsumed: itemsConsumed ?? this.itemsConsumed,
    );
  }

  // Helper getters
  bool get isPositiveChange => changeAmount > 0;
  bool get isNegativeChange => changeAmount < 0;
  bool get isStockIn => action.toLowerCase().contains('stock in') || action.toLowerCase().contains('restock');
  bool get isStockOut => action.toLowerCase().contains('consumption') || action.toLowerCase().contains('production');
  
  String get formattedChange => '${changeAmount > 0 ? '+' : ''}${changeAmount.toStringAsFixed(2)}';
  String get formattedRemainingStock => remainingStock.toStringAsFixed(2);
  
  String get displayAction {
    if (action == 'Stock In (Create)') return 'Initial Stock';
    if (action == 'Stock In (Edit)') return 'Stock Adjustment';
    if (action == 'Restock') return 'Restock';
    if (action == 'Consumption') return 'Consumed';
    if (action == 'Product Production') return 'Product Made';
    return action;
  }
  
  String get displayProductInfo {
    if (productName != null && quantity != null) {
      return '$productName x$quantity';
    }
    return notes;
  }
}