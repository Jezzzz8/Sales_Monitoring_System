class TransactionModel {
  String id;
  String transactionNumber;
  DateTime transactionDate;
  String customerName;
  String customerPhone;
  String paymentMethod;
  double totalAmount;
  double amountPaid;
  double change;
  String status;
  List<TransactionItem> items;
  String? notes;
  DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.transactionNumber,
    required this.transactionDate,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.totalAmount,
    required this.amountPaid,
    required this.change,
    required this.status,
    required this.items,
    this.notes,
    required this.createdAt,
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
      'change': change,
      'status': status,
      'items': items.map((item) => item.toMap()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      transactionNumber: map['transactionNumber'],
      transactionDate: DateTime.parse(map['transactionDate']),
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      paymentMethod: map['paymentMethod'],
      totalAmount: map['totalAmount'].toDouble(),
      amountPaid: map['amountPaid'].toDouble(),
      change: map['change'].toDouble(),
      status: map['status'],
      items: List<TransactionItem>.from(
        map['items'].map((x) => TransactionItem.fromMap(x)),
      ),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String get formattedDate => '${transactionDate.day}/${transactionDate.month}/${transactionDate.year}';
  String get formattedTime => '${transactionDate.hour.toString().padLeft(2, '0')}:${transactionDate.minute.toString().padLeft(2, '0')}';
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
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'].toDouble(),
      total: map['total'].toDouble(),
    );
  }
}