import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../widgets/product_card.dart';

class POSTransaction extends StatefulWidget {
  const POSTransaction({super.key});

  @override
  State<POSTransaction> createState() => _POSTransactionState();
}

class _POSTransactionState extends State<POSTransaction> {
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'Whole Lechon (18-20kg)',
      categoryId: '5',
      description: 'Traditional roasted pig, serves 30-40 persons',
      price: 6000,
      unit: 'piece',
      stock: 5,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '2',
      name: 'Whole Lechon (21-23kg)',
      categoryId: '5',
      description: 'Traditional roasted pig, serves 40-50 persons',
      price: 7000,
      unit: 'piece',
      stock: 3,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '3',
      name: 'Lechon Belly (3kg)',
      categoryId: '6',
      description: 'Boneless lechon belly, serves 8-10 persons',
      price: 1800,
      unit: 'piece',
      stock: 10,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '4',
      name: 'Lechon Belly (5kg)',
      categoryId: '6',
      description: 'Boneless lechon belly, serves 12-15 persons',
      price: 2700,
      unit: 'piece',
      stock: 8,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '5',
      name: 'Pork BBQ (10 sticks)',
      categoryId: '7',
      description: 'Grilled pork barbecue sticks',
      price: 400,
      unit: 'pack',
      stock: 20,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '6',
      name: 'Dinakdakan',
      categoryId: '7',
      description: 'Pork appetizer with special sauce',
      price: 1200,
      unit: 'tray',
      stock: 6,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '7',
      name: 'Chicken BBQ (10 sticks)',
      categoryId: '7',
      description: 'Grilled chicken barbecue sticks',
      price: 350,
      unit: 'pack',
      stock: 15,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '8',
      name: 'Sisig (Family Size)',
      categoryId: '7',
      description: 'Sizzling pork sisig',
      price: 450,
      unit: 'plate',
      stock: 12,
      createdAt: DateTime.now(),
    ),
    // Desserts
    Product(
      id: '9',
      name: 'Leche Flan',
      categoryId: '8',
      description: 'Creamy caramel flan',
      price: 250,
      unit: 'slice',
      stock: 15,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '10',
      name: 'Halo-Halo',
      categoryId: '8',
      description: 'Mixed dessert with shaved ice',
      price: 120,
      unit: 'bowl',
      stock: 20,
      createdAt: DateTime.now(),
    ),
    // Pastas
    Product(
      id: '11',
      name: 'Carbonara Pasta',
      categoryId: '9',
      description: 'Creamy carbonara pasta',
      price: 300,
      unit: 'plate',
      stock: 12,
      createdAt: DateTime.now(),
    ),
    Product(
      id: '12',
      name: 'Spaghetti',
      categoryId: '9',
      description: 'Sweet Filipino-style spaghetti',
      price: 280,
      unit: 'plate',
      stock: 15,
      createdAt: DateTime.now(),
    ),
  ];

  final List<TransactionItem> _cartItems = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _paymentMethod = 'Cash';
  double _amountPaid = 0;
  bool _showCustomerForm = false;

  double get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.total);
  }

  double get _tax {
    return _subtotal * 0.12; // 12% VAT
  }

  double get _total {
    return _subtotal + _tax;
  }

  double get _change {
    return _amountPaid - _total;
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is out of stock'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id);
    
    if (existingIndex != -1) {
      setState(() {
        final item = _cartItems[existingIndex];
        _cartItems[existingIndex] = TransactionItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity + 1,
          unitPrice: item.unitPrice,
          total: item.unitPrice * (item.quantity + 1),
        );
      });
    } else {
      setState(() {
        _cartItems.add(TransactionItem(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitPrice: product.price,
          total: product.price,
        ));
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeFromCart(int index) {
    setState(() {
      final item = _cartItems[index];
      if (item.quantity > 1) {
        _cartItems[index] = TransactionItem(
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity - 1,
          unitPrice: item.unitPrice,
          total: item.unitPrice * (item.quantity - 1),
        );
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to clear all items from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _cartItems.clear();
                _customerNameController.clear();
                _customerPhoneController.clear();
                _notesController.clear();
                _paymentMethod = 'Cash';
                _amountPaid = 0;
                _showCustomerForm = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('CLEAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processTransaction() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to cart'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_customerNameController.text.isEmpty) {
      setState(() {
        _showCustomerForm = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_amountPaid < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Amount paid (₱${_amountPaid.toStringAsFixed(2)}) is less than total (₱${_total.toStringAsFixed(2)})'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final transaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      transactionNumber: 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      transactionDate: DateTime.now(),
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      paymentMethod: _paymentMethod,
      totalAmount: _total,
      amountPaid: _amountPaid,
      change: _change,
      status: 'Completed',
      items: List.from(_cartItems),
      notes: _notesController.text,
      createdAt: DateTime.now(),
    );

    // Show receipt dialog
    _showReceiptDialog(transaction);
  }

  void _showReceiptDialog(TransactionModel transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt, color: Colors.deepOrange),
            const SizedBox(width: 8),
            const Text('Transaction Receipt'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: () {
                // Print receipt functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt sent to printer'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "GENE'S LECHON",
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Receipt #: ${transaction.transactionNumber}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Center(
                child: Text(
                  'Date: ${transaction.formattedDate} ${transaction.formattedTime}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 12),
              Text('Customer: ${transaction.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (transaction.customerPhone.isNotEmpty)
                Text('Phone: ${transaction.customerPhone}'),
              const SizedBox(height: 16),
              const Text(
                'ITEMS PURCHASED',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...transaction.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text('${item.productName} x${item.quantity}'),
                    ),
                    Text('₱${item.total.toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const Divider(),
              _buildReceiptRow('Subtotal', _subtotal),
              _buildReceiptRow('Tax (12%)', _tax),
              _buildReceiptRow('Total', _total, isBold: true),
              const Divider(),
              _buildReceiptRow('Amount Paid', _amountPaid),
              _buildReceiptRow('Change', _change, color: _change >= 0 ? Colors.green : Colors.red, isBold: true),
              const SizedBox(height: 16),
              Text('Payment Method: ${transaction.paymentMethod}', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Notes: ${transaction.notes!}'),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: const Center(
                  child: Text(
                    '✅ TRANSACTION COMPLETED',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Thank you for your order!',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction completed! Receipt #${transaction.transactionNumber}'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
            ),
            child: const Text('COMPLETE SALE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, double amount, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: isBold ? 14 : 13,
            ),
          ),
        ],
      ),
    );
  }

  List<Product> get _filteredProducts {
    if (_searchController.text.isEmpty) {
      return _products;
    }
    return _products.where((product) {
      return product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
             product.categoryId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
             product.description.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
  }

  Widget _buildProductCard(Product product, bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: BoxConstraints(
            minHeight: Responsive.getCardHeight(context, multiplier: 0.9),
          ),
          padding: EdgeInsets.all(Responsive.getCardPadding(context).horizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Product Image/Icon Container with responsive sizing
              Container(
                height: Responsive.getCardHeight(context, multiplier: 0.4),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: product.categoryId == '5' // Whole Lechon
                        ? [Colors.deepOrange.shade50, Colors.orange.shade50]
                        : product.categoryId == '6' // Lechon Belly
                            ? [Colors.orange.shade50, Colors.amber.shade50]
                            : [Colors.blue.shade50, Colors.cyan.shade50],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        product.categoryId == '5' 
                            ? Icons.celebration 
                            : product.categoryId == '6'
                                ? Icons.restaurant_menu
                                : Icons.local_fire_department,
                        color: product.categoryId == '5'
                            ? Colors.deepOrange
                            : product.categoryId == '6'
                                ? Colors.orange
                                : Colors.blue,
                        size: Responsive.getIconSize(context, multiplier: 1.5),
                      ),
                    ),
                    if (product.stock < 5)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${product.stock} left',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.getFontSize(context, mobile: 8, tablet: 9, desktop: 10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              
              // Product Name
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              
              // Price
              Text(
                '₱${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              
              // Category and Stock Info
              Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: Responsive.getIconSize(context, multiplier: 0.6),
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.categoryId,
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.getSmallSpacing(context).height),
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: Responsive.getIconSize(context, multiplier: 0.6),
                        color: product.stock < 5 ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stock: ${product.stock}',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                          color: product.stock < 5 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItemCard(TransactionItem item, int index, bool isMobile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.shade50,
          child: Text(
            '${item.quantity}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepOrange,
            ),
          ),
        ),
        title: Text(
          item.productName,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '₱${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₱${item.total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
              onPressed: () => _removeFromCart(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: Column(
        children: [
          // Cart Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.deepOrange, Colors.orange],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CART: ${_cartItems.length} items',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₱${_total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCartModal(context);
                  },
                  icon: const Icon(Icons.shopping_cart, size: 18),
                  label: const Text('VIEW CART'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          
          // Category Filter Chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All', 'Whole Lechon', 'Lechon Belly', 'Appetizers'].map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _searchController.text == category,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _searchController.text = category == 'All' ? '' : category;
                        }
                      });
                    },
                    selectedColor: Colors.deepOrange,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Product Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ProductCard(
                  product: product,
                  onTap: () => _addToCart(product),
                  onAddToCart: () => _addToCart(product),
                  showAddButton: true,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _processTransaction,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle),
        label: const Text('PROCESS SALE'),
        elevation: 4,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel - Product Selection (60%)
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search products by name, category...',
                              prefixIcon: const Icon(Icons.search, color: Colors.deepOrange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_alt, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_filteredProducts.length} products',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildProductCard(product, false);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Panel - Cart & Transaction Details (40%)
          Expanded(
            flex: 2,
            child: _buildCartPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.deepOrange, Colors.orange],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'SHOPPING CART',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Badge(
                  label: Text('${_cartItems.length}'),
                  backgroundColor: Colors.white,
                  textColor: Colors.deepOrange,
                  largeSize: 24,
                ),
              ],
            ),
          ),

          // Cart Items - Made more flexible
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add products to get started',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            children: [
                              // Cart Items List
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight * 0.5,
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  shrinkWrap: true,
                                  itemCount: _cartItems.length,
                                  itemBuilder: (context, index) {
                                    final item = _cartItems[index];
                                    return _buildCartItemCard(item, index, false);
                                  },
                                ),
                              ),

                              // Customer Details Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'CUSTOMER DETAILS',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _showCustomerForm ? Icons.expand_less : Icons.expand_more,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _showCustomerForm = !_showCustomerForm;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    if (_showCustomerForm)
                                      Column(
                                        children: [
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _customerNameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Customer Name *',
                                              prefixIcon: Icon(Icons.person),
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _customerPhoneController,
                                            decoration: const InputDecoration(
                                              labelText: 'Phone Number',
                                              prefixIcon: Icon(Icons.phone),
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.phone,
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            initialValue: _paymentMethod,
                                            decoration: const InputDecoration(
                                              labelText: 'Payment Method',
                                              prefixIcon: Icon(Icons.payment),
                                              border: OutlineInputBorder(),
                                            ),
                                            items: ['Cash', 'GCash', 'Bank Transfer', 'Credit Card', 'PayMaya']
                                                .map((method) => DropdownMenuItem(
                                                      value: method,
                                                      child: Text(method),
                                                    ))
                                                .toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                _paymentMethod = value!;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            controller: _notesController,
                                            decoration: const InputDecoration(
                                              labelText: 'Order Notes (Optional)',
                                              prefixIcon: Icon(Icons.note),
                                              border: OutlineInputBorder(),
                                            ),
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),

                              // Totals Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  border: Border(
                                    top: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildTotalRow('Subtotal', _subtotal),
                                    _buildTotalRow('Tax (12%)', _tax),
                                    const Divider(thickness: 2),
                                    _buildTotalRow('Total', _total, isBold: true, fontSize: 18),
                                    const SizedBox(height: 16),
                                    TextField(
                                      onChanged: (value) {
                                        setState(() {
                                          _amountPaid = double.tryParse(value) ?? 0;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        labelText: 'Amount Paid *',
                                        border: OutlineInputBorder(),
                                        prefixText: '₱',
                                        prefixIcon: Icon(Icons.money),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 8),
                                    if (_amountPaid > 0)
                                      _buildTotalRow(
                                        'Change',
                                        _change,
                                        color: _change >= 0 ? Colors.green : Colors.red,
                                        isBold: true,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Action Buttons - Fixed at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clearCart,
                    icon: const Icon(Icons.clear_all, size: 20),
                    label: const Text('CLEAR CART'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processTransaction,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('PROCESS SALE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCartModal(BuildContext context) {
    bool localShowCustomerForm = _showCustomerForm;
    String localPaymentMethod = _paymentMethod;
    double localAmountPaid = _amountPaid;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Draggable handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SHOPPING CART',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Cart Items
                  Expanded(
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your cart is empty',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add products to get started',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Cart Items List
                                ..._cartItems.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return _buildCartItemCard(item, index, true);
                                }),
                                
                                const SizedBox(height: 16),
                                
                                // Customer Details Section
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'CUSTOMER DETAILS',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.deepOrange,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                localShowCustomerForm ? Icons.expand_less : Icons.expand_more,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setModalState(() {
                                                  localShowCustomerForm = !localShowCustomerForm;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        if (localShowCustomerForm || _customerNameController.text.isNotEmpty)
                                          Column(
                                            children: [
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: _customerNameController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Customer Name *',
                                                  prefixIcon: Icon(Icons.person),
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                controller: _customerPhoneController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Phone Number',
                                                  prefixIcon: Icon(Icons.phone),
                                                  border: OutlineInputBorder(),
                                                ),
                                                keyboardType: TextInputType.phone,
                                              ),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                initialValue: localPaymentMethod,
                                                decoration: const InputDecoration(
                                                  labelText: 'Payment Method',
                                                  prefixIcon: Icon(Icons.payment),
                                                  border: OutlineInputBorder(),
                                                ),
                                                items: ['Cash', 'GCash', 'Bank Transfer', 'Credit Card', 'PayMaya']
                                                    .map((method) => DropdownMenuItem(
                                                          value: method,
                                                          child: Text(method),
                                                        ))
                                                    .toList(),
                                                onChanged: (value) {
                                                  setModalState(() {
                                                    localPaymentMethod = value!;
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 8),
                                              TextField(
                                                controller: _notesController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Order Notes (Optional)',
                                                  prefixIcon: Icon(Icons.note),
                                                  border: OutlineInputBorder(),
                                                ),
                                                maxLines: 2,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Amount Paid Section
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PAYMENT',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          onChanged: (value) {
                                            setModalState(() {
                                              localAmountPaid = double.tryParse(value) ?? 0;
                                            });
                                          },
                                          decoration: const InputDecoration(
                                            labelText: 'Amount Paid *',
                                            border: OutlineInputBorder(),
                                            prefixText: '₱',
                                            prefixIcon: Icon(Icons.money),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  
                  // Footer with totals
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildTotalRow('Subtotal', _subtotal),
                        _buildTotalRow('Tax (12%)', _tax),
                        const Divider(),
                        _buildTotalRow('Total', _total, isBold: true, fontSize: 18),
                        const SizedBox(height: 8),
                        if (localAmountPaid > 0) ...[
                          _buildTotalRow('Amount Paid', localAmountPaid),
                          _buildTotalRow(
                            'Change',
                            localAmountPaid - _total,
                            color: (localAmountPaid - _total) >= 0 ? Colors.green : Colors.red,
                            isBold: true,
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Sync local state back to main state
                              setState(() {
                                _paymentMethod = localPaymentMethod;
                                _amountPaid = localAmountPaid;
                                _showCustomerForm = localShowCustomerForm;
                              });
                              
                              // Process transaction
                              if (_customerNameController.text.isEmpty) {
                                setState(() {
                                  _showCustomerForm = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter customer name'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              if (_amountPaid < _total) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Amount paid (₱${_amountPaid.toStringAsFixed(2)}) is less than total (₱${_total.toStringAsFixed(2)})'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              final transaction = TransactionModel(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                transactionNumber: 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                transactionDate: DateTime.now(),
                                customerName: _customerNameController.text,
                                customerPhone: _customerPhoneController.text,
                                paymentMethod: _paymentMethod,
                                totalAmount: _total,
                                amountPaid: _amountPaid,
                                change: _amountPaid - _total,
                                status: 'Completed',
                                items: List.from(_cartItems),
                                notes: _notesController.text,
                                createdAt: DateTime.now(),
                              );

                              Navigator.pop(context);
                              _showReceiptDialog(transaction);
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('PROCESS SALE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}