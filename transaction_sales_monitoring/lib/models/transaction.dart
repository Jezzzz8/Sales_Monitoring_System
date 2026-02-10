// lib/models/transaction.dart - UPDATED VERSION with factory constructor fix
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String id;
  String transactionNumber;
  DateTime transactionDate;
  String customerName;
  String customerPhone;
  String paymentMethod;
  double totalAmount;
  double amountPaid;
  double cashReceived;
  double change;
  String status;
  List<TransactionItem> items;
  String? notes;
  DateTime createdAt;
  String cashier;
  String? reference;

  TransactionModel({
    required this.id,
    required this.transactionNumber,
    required this.transactionDate,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.totalAmount,
    required this.amountPaid,
    required this.cashReceived,
    required this.change,
    required this.status,
    required this.items,
    this.notes,
    required this.createdAt,
    this.cashier = 'Staff',
    this.reference,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionNumber': transactionNumber,
      'transactionDate': transactionDate.toIso8601String(),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'paymentMethod': paymentMethod,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'cashReceived': cashReceived,
      'change': change,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'cashier': cashier,
      'reference': reference,
    };
  }

  // For Firebase document
  Map<String, dynamic> toFirestore() {
    return {
      'amountPaid': amountPaid,
      'cashReceived': cashReceived,
      'cashier': cashier,
      'change': change,
      'contact': customerPhone,
      'customer': customerName,
      'customerName': customerName,
      'customerContact': customerPhone,
      'date': Timestamp.fromDate(transactionDate),
      'items': items.map((item) => item.toFirestoreMap()).toList(),
      'method': paymentMethod,
      'paymentMethod': paymentMethod,
      'orderId': transactionNumber,
      'reference': reference ?? '-',
      'total': totalAmount,
      'totalAmount': totalAmount,
      'status': status,
      'notes': notes ?? '',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    // Get totalAmount first (used in amountPaid default)
    final mapTotalAmount = (map['totalAmount'] ?? map['total'] ?? 0).toDouble();
    
    return TransactionModel(
      id: map['id'] ?? '',
      transactionNumber: map['transactionNumber'] ?? map['orderId'] ?? '#N/A',
      transactionDate: map['transactionDate'] != null 
          ? DateTime.parse(map['transactionDate'])
          : (map['date'] is Timestamp 
              ? (map['date'] as Timestamp).toDate()
              : DateTime.now()),
      customerName: map['customerName'] ?? map['customer'] ?? 'Walk-in',
      customerPhone: map['customerPhone'] ?? map['contact'] ?? map['customerContact'] ?? '-',
      paymentMethod: map['paymentMethod'] ?? map['method'] ?? 'Cash',
      totalAmount: mapTotalAmount,
      // amountPaid: The total amount the customer should pay
      amountPaid: (map['amountPaid'] ?? mapTotalAmount).toDouble(),
      // cashReceived: The actual cash received (can be partial)
      cashReceived: (map['cashReceived'] ?? map['amountPaid'] ?? mapTotalAmount).toDouble(),
      change: (map['change'] ?? 0).toDouble(),
      status: map['status'] ?? 'Completed',
      items: List<TransactionItem>.from(
        (map['items'] as List<dynamic>? ?? []).map((x) => TransactionItem.fromMap(x)),
      ),
      notes: map['notes'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
      cashier: map['cashier'] ?? 'Staff',
      reference: map['reference'] ?? '-',
    );
  }

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    print('Firestore Document ID: ${doc.id}');
    print('Firestore Data: $data');
    
    double totalAmount = (data['totalAmount'] ?? data['total'] ?? 0).toDouble();
    
    return TransactionModel(
      id: doc.id,
      transactionNumber: data['orderId'] ?? '#N/A',
      transactionDate: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerName: data['customerName'] ?? data['customer'] ?? 'Walk-in',
      customerPhone: data['customerContact'] ?? data['contact'] ?? '-',
      paymentMethod: data['paymentMethod'] ?? data['method'] ?? 'Cash',
      totalAmount: totalAmount,
      // amountPaid: The total amount the customer should pay
      amountPaid: (data['amountPaid'] ?? totalAmount).toDouble(),
      // cashReceived: The actual cash received (can be partial)
      cashReceived: (data['cashReceived'] ?? data['amountPaid'] ?? totalAmount).toDouble(),
      change: (data['change'] ?? 0).toDouble(),
      status: data['status'] ?? 'Completed',
      items: List<TransactionItem>.from(
        (data['items'] as List<dynamic>? ?? []).map((x) => TransactionItem.fromMap(x as Map<String, dynamic>)),
      ),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      cashier: data['cashier'] ?? 'Staff',
      reference: data['reference'] ?? '-',
    );
  }

  TransactionModel copyWith({
    String? id,
    String? transactionNumber,
    DateTime? transactionDate,
    String? customerName,
    String? customerPhone,
    String? paymentMethod,
    double? totalAmount,
    double? amountPaid,
    double? cashReceived,
    double? change,
    String? status,
    List<TransactionItem>? items,
    String? notes,
    DateTime? createdAt,
    String? cashier,
    String? reference,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      transactionNumber: transactionNumber ?? this.transactionNumber,
      transactionDate: transactionDate ?? this.transactionDate,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      cashReceived: cashReceived ?? this.cashReceived,
      change: change ?? this.change,
      status: status ?? this.status,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      cashier: cashier ?? this.cashier,
      reference: reference ?? this.reference,
    );
  }

  String get formattedDate => '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}';
  String get formattedTime => '${transactionDate.hour.toString().padLeft(2, '0')}:${transactionDate.minute.toString().padLeft(2, '0')}';
  
  String get displayTransactionNumber => transactionNumber.startsWith('#') ? transactionNumber : '#$transactionNumber';
  
  // Helper getters for business logic
  double get balance => amountPaid - cashReceived; // Amount still owed (negative means balance due)
  bool get isFullyPaid => cashReceived >= amountPaid;
  bool get hasPartialPayment => cashReceived > 0 && cashReceived < amountPaid;
  bool get hasChange => cashReceived > amountPaid;
  
  // Calculate actual change to give (positive if cashReceived > amountPaid, 0 otherwise)
  double get actualChange => cashReceived > amountPaid ? cashReceived - amountPaid : 0;
}

class TransactionItem {
  String productId;
  String productName;
  int quantity;
  double unitPrice;
  double total;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': productId,
      'name': productName,
      'qty': quantity,
      'price': unitPrice,
      'total': total,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': productId,
      'name': productName,
      'price': unitPrice,
      'qty': quantity,
      'total': total,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    print('TransactionItem map: $map');
    
    return TransactionItem(
      productId: map['id']?.toString() ?? '',
      productName: map['name']?.toString() ?? 'Unknown Product',
      quantity: (map['qty'] ?? map['quantity'] ?? 0).toInt(),
      unitPrice: (map['price'] ?? map['unitPrice'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  factory TransactionItem.fromFirestore(Map<String, dynamic> map) {
    return TransactionItem.fromMap(map);
  }

  TransactionItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? total,
  }) {
    return TransactionItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      total: total ?? this.total,
    );
  }
}