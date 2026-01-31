// pos_transaction.dart - FIXED VERSION
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

class POSTransaction extends StatefulWidget {
  const POSTransaction({super.key});

  @override
  State<POSTransaction> createState() => _POSTransactionState();
}

class _POSTransactionState extends State<POSTransaction> {
  // Settings integration
  AppSettings? _settings;
  bool _isLoadingSettings = true;
  
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
  bool _showCustomerForm = true; // Changed to true by default

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      _settings = await SettingsService.loadSettings();
    } catch (e) {
      print('Error loading settings in POS: $e');
      _settings = AppSettings();
    }
    setState(() => _isLoadingSettings = false);
  }

  Color _getPrimaryColor() {
    return _settings?.primaryColorValue ?? Colors.deepOrange;
  }

  double get _subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.total);
  }

  double get _tax {
    return _subtotal * (_settings?.taxRate ?? 0.12) / 100;
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
                _showCustomerForm = true;
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
                    color: _getPrimaryColor(),
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
              _buildReceiptRow('Tax (${_settings?.taxRate ?? 12}%)', _tax),
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
              backgroundColor: _getPrimaryColor(),
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
    final primaryColor = _getPrimaryColor();
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate font sizes based on screen size
    double getScaledFontSize(double mobile, double tablet, double desktop) {
      if (screenWidth < 600) {
        return mobile * 1.1; // Mobile: slightly larger
      } else if (screenWidth < 1024) {
        return tablet * 1.0; // Tablet: base size
      } else {
        return desktop * 0.9; // Desktop: slightly smaller
      }
    }
    
    double getIconScale() {
      if (screenWidth < 600) return 1.3; // Mobile: larger icons
      if (screenWidth < 1024) return 1.5; // Tablet: even larger icons
      return 1.2; // Desktop: normal icons
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(
            screenWidth < 600 ? 10 : 12, // Larger padding on mobile
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image/Icon - SCALED based on screen size
              Container(
                height: screenWidth < 600 
                  ? 100  // Mobile: taller
                  : screenWidth < 1024 
                    ? 120 // Tablet: even taller
                    : 80, // Desktop: normal
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getProductIcon(product.categoryId),
                        color: primaryColor,
                        size: screenWidth < 600 
                          ? 40  // Mobile: larger icon
                          : screenWidth < 1024 
                            ? 50  // Tablet: even larger icon
                            : 36, // Desktop: normal icon
                      ),
                    ),
                    if (product.stock < 5)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 600 ? 6 : 4,
                            vertical: screenWidth < 600 ? 3 : 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.stock} left',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth < 600 
                                ? 10  // Mobile: larger text
                                : screenWidth < 1024 
                                  ? 11  // Tablet: larger text
                                  : 9,  // Desktop: normal text
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              
              // Product Name - SCALED font size
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth < 600 
                    ? 14  // Mobile: larger text
                    : screenWidth < 1024 
                      ? 16  // Tablet: larger text
                      : 14, // Desktop: normal text
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              
              // Price - SCALED font size
              Text(
                '₱${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: screenWidth < 600 
                    ? 18  // Mobile: larger text
                    : screenWidth < 1024 
                      ? 20  // Tablet: larger text
                      : 16, // Desktop: normal text
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              
              SizedBox(height: Responsive.getSmallSpacing(context).height),
              
              // Category and Stock - SCALED icons and text
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category,
                        size: screenWidth < 600 
                          ? 16  // Mobile: larger icon
                          : screenWidth < 1024 
                            ? 18  // Tablet: larger icon
                            : 14, // Desktop: normal icon
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product.categoryId,
                        style: TextStyle(
                          fontSize: screenWidth < 600 
                            ? 11  // Mobile: larger text
                            : screenWidth < 1024 
                              ? 12  // Tablet: larger text
                              : 10, // Desktop: normal text
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory,
                        size: screenWidth < 600 
                          ? 16  // Mobile: larger icon
                          : screenWidth < 1024 
                            ? 18  // Tablet: larger icon
                            : 14, // Desktop: normal icon
                        color: product.stock < 5 ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${product.stock}',
                        style: TextStyle(
                          fontSize: screenWidth < 600 
                            ? 11  // Mobile: larger text
                            : screenWidth < 1024 
                              ? 12  // Tablet: larger text
                              : 10, // Desktop: normal text
                          color: product.stock < 5 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
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

  IconData _getProductIcon(String category) {
    switch (category) {
      case '5': return Icons.celebration; // Whole Lechon
      case '6': return Icons.restaurant_menu; // Lechon Belly
      default: return Icons.fastfood;
    }
  }

  Widget _buildCartItemCard(TransactionItem item, int index, bool isMobile) {
    final primaryColor = _getPrimaryColor();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Text(
            '${item.quantity}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryColor,
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
    if (_isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final primaryColor = _getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return _buildMobileLayout(primaryColor);
    } else {
      return _buildDesktopLayout(primaryColor);
    }
  }

  Widget _buildMobileLayout(Color primaryColor) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
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
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Colors.grey.shade100,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _buildProductCard(product, true);
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

  Widget _buildDesktopLayout(Color primaryColor) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products by name, category...',
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: MediaQuery.of(context).size.width < 1024 ? 0.85 : 0.8,
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

          Expanded(
            flex: 2,
            child: _buildCartPanel(primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPanel(Color primaryColor) {
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withOpacity(0.8)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
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
                  textColor: primaryColor,
                  largeSize: 24,
                ),
              ],
            ),
          ),

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
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add products to get started',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return _buildCartItemCard(item, index, false);
                          },
                        ),

                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'CUSTOMER DETAILS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
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
                                      decoration: InputDecoration(
                                        labelText: 'Customer Name *',
                                        prefixIcon: Icon(Icons.person, color: primaryColor),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _customerPhoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Phone Number',
                                        prefixIcon: Icon(Icons.phone, color: primaryColor),
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _paymentMethod,
                                      decoration: InputDecoration(
                                        labelText: 'Payment Method',
                                        prefixIcon: Icon(Icons.payment, color: primaryColor),
                                        border: const OutlineInputBorder(),
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
                                      decoration: InputDecoration(
                                        labelText: 'Order Notes (Optional)',
                                        prefixIcon: Icon(Icons.note, color: primaryColor),
                                        border: const OutlineInputBorder(),
                                      ),
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

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
                              _buildTotalRow('Tax (${_settings?.taxRate ?? 12}%)', _tax),
                              const Divider(thickness: 2),
                              _buildTotalRow('Total', _total, isBold: true, fontSize: 18),
                              const SizedBox(height: 16),
                              TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _amountPaid = double.tryParse(value) ?? 0;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Amount Paid *',
                                  border: const OutlineInputBorder(),
                                  prefixText: '₱',
                                  prefixIcon: Icon(Icons.money, color: primaryColor),
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
          ),

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
                      side: BorderSide(color: primaryColor),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final primaryColor = _getPrimaryColor();
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SHOPPING CART',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
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
                            Text(
                              'Your cart is empty',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
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
                            ..._cartItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return _buildCartItemCard(item, index, true);
                            }),
                            
                            const SizedBox(height: 16),
                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  _buildTotalRow('Subtotal', _subtotal),
                                  _buildTotalRow('Tax (${_settings?.taxRate ?? 12}%)', _tax),
                                  const Divider(),
                                  _buildTotalRow('Total', _total, isBold: true, fontSize: 18),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _customerNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Customer Name *',
                                      prefixIcon: Icon(Icons.person, color: primaryColor),
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _customerPhoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Phone Number',
                                      prefixIcon: Icon(Icons.phone, color: primaryColor),
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _paymentMethod,
                                    decoration: InputDecoration(
                                      labelText: 'Payment Method',
                                      prefixIcon: Icon(Icons.payment, color: primaryColor),
                                      border: const OutlineInputBorder(),
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
                                    onChanged: (value) {
                                      setState(() {
                                        _amountPaid = double.tryParse(value) ?? 0;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Amount Paid *',
                                      border: const OutlineInputBorder(),
                                      prefixText: '₱',
                                      prefixIcon: Icon(Icons.money, color: primaryColor),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _processTransaction,
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
  }
}