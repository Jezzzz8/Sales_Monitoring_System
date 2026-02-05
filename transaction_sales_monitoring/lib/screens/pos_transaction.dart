// pos_transaction.dart - COMPLETE FIXED VERSION
import 'package:flutter/material.dart';
import '../utils/settings_mixin.dart';
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

class _POSTransactionState extends State<POSTransaction> with SettingsMixin {
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
  bool _showCustomerForm = true;


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

  double get _total {
    // CHANGED: Total is now just the subtotal (no tax)
    return _subtotal;
  }

  double get _change {
    return _amountPaid - _total;
  }

  int get _totalItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
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

    // Clear any existing snackbars before showing new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
    
    // Clear any existing snackbars before showing new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${_cartItems[index].productName} from cart'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeItemFromCart(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    
    final itemName = _cartItems[index].productName;
    setState(() {
      _cartItems.removeAt(index);
    });
    
    // Clear any existing snackbars before showing new one
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed $itemName from cart'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _clearCart({VoidCallback? onAfterClear}) {
    if (_cartItems.isEmpty) {
      // Clear any existing snackbars before showing new one
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is already empty'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    
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
              
              // Call the modal update callback if provided
              onAfterClear?.call();
              
              // Clear any existing snackbars before showing new one
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared successfully'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('CLEAR CART', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _processTransaction() {
    if (_cartItems.isEmpty) {
      // Clear any existing snackbars before showing new one
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
      // Clear any existing snackbars before showing new one
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
      // Clear any existing snackbars before showing new one
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
              // REMOVED: Tax row from receipt
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

  int _getGridColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 2; // Mobile
    } else if (screenWidth < 960) {
      return 3; // Tablet
    } else if (screenWidth < 1280) {
      return 4; // Small desktop
    } else {
      return 5; // Large desktop
    }
  }

double _getCardAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 0.65; // Mobile: taller cards
    } else if (screenWidth < 960) {
      return 0.7; // Tablet
    } else if (screenWidth < 1280) {
      return 0.75; // Small desktop
    } else {
      return 0.8; // Large desktop
    }
  }

  Widget _buildProductCard(Product product, bool isMobile) {
    final primaryColor = getPrimaryColor();
    final isTablet = Responsive.isTablet(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate responsive values - FIXED: Reduced values for better fit
    final cardPadding = isMobile ? 6.0 : 8.0;
    final iconSize = isMobile ? 32.0 : (isTablet ? 36.0 : 28.0);
    final titleFontSize = isMobile ? 11.0 : (isTablet ? 13.0 : 11.0);
    final priceFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 13.0);
    
    // FIXED: Use container with fixed height to prevent overflow
    return SizedBox(
      height: isMobile ? 160 : (isTablet ? 180 : 150), // Fixed height for consistency
      child: Card(
        elevation: isDarkMode ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        child: InkWell(
          onTap: () => _addToCart(product),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : primaryColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image/Icon with fixed aspect ratio
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [
                                Colors.grey.shade700,
                                Colors.grey.shade800,
                              ]
                            : [
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
                            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                            size: iconSize,
                          ),
                        ),
                        if (product.stock < 5)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product.stock}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Product Name
                Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Price
                Text(
                  '₱${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: priceFontSize,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // Category and Stock info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 10,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              product.categoryId,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 10,
                          color: product.stock < 5 ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${product.stock}',
                          style: TextStyle(
                            fontSize: 9,
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
    final primaryColor = getPrimaryColor();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDarkMode 
              ? primaryColor.withOpacity(0.2)
              : primaryColor.withOpacity(0.1),
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
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '₱${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₱${item.total.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, 
                    color: Colors.orange, 
                    size: 20
                  ),
                  onPressed: () => _removeFromCart(index),
                  tooltip: 'Decrease quantity',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, 
                    color: Colors.red, 
                    size: 20
                  ),
                  onPressed: () => _removeItemFromCart(index),
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final primaryColor = getPrimaryColor();
    final isMobile = Responsive.isMobile(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Apply theme based on dark mode
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final cardColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final hintTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: backgroundColor,
        cardColor: cardColor,
        primaryColor: primaryColor,
        textTheme: Theme.of(context).textTheme.copyWith(
              bodyLarge: TextStyle(color: textColor),
              bodyMedium: TextStyle(color: textColor),
            ),
        colorScheme: isDarkMode
            ? const ColorScheme.dark(
                primary: Colors.deepOrange,
                surface: Colors.grey,
              )
            : ColorScheme.fromSwatch(
                primarySwatch: Colors.orange,
                backgroundColor: backgroundColor,
              ),
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: isMobile ? _buildMobileLayout(primaryColor, isDarkMode, backgroundColor, cardColor, textColor, hintTextColor) 
                     : _buildDesktopLayout(primaryColor, isDarkMode, backgroundColor, cardColor, textColor, hintTextColor),
      ),
    );
  }

  Widget _buildMobileLayout(
    Color primaryColor, 
    bool isDarkMode, 
    Color backgroundColor, 
    Color cardColor,
    Color textColor,
    Color hintTextColor
  ) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Header with cart info (unchanged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        Colors.grey.shade800,
                        Colors.grey.shade900,
                      ]
                    : [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.3)
                      : primaryColor.withOpacity(0.3),
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
                      'CART SUMMARY',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₱${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text( // ADDED: Show total items count
                      '${_totalItemCount} items',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCartModal(context, isDarkMode, primaryColor, cardColor, textColor, hintTextColor);
                  },
                  icon: Icon(Icons.shopping_cart, 
                    size: 18, 
                    color: isDarkMode ? primaryColor : primaryColor
                  ),
                  label: Text('$_totalItemCount Items', // CHANGED: Use totalItemCount
                    style: TextStyle(
                      color: isDarkMode ? primaryColor : primaryColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.white,
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
          
          // Search bar (unchanged)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: isDarkMode ? Colors.grey.shade800 : cardColor,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: hintTextColor),
                  prefixIcon: Icon(Icons.search, 
                    color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          
          // Products grid with consistent column distribution - UPDATED
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getGridColumnCount(context),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: _getCardAspectRatio(context),
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
        icon: const Icon(Icons.check_circle, color: Colors.white),
        label: const Text('PROCESS SALE', style: TextStyle(color: Colors.white)),
        elevation: 4,
      ),
    );
  }

Widget _buildDesktopLayout(
    Color primaryColor, 
    bool isDarkMode, 
    Color backgroundColor, 
    Color cardColor,
    Color textColor,
    Color hintTextColor
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeDesktop = screenWidth > 1440;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Products panel
          Expanded(
            flex: isLargeDesktop ? 4 : 3,
            child: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  // Search bar (unchanged)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: isDarkMode ? Colors.grey.shade800 : cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: isDarkMode 
                                ? Colors.black.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search products by name, category...',
                          hintStyle: TextStyle(color: hintTextColor),
                          prefixIcon: Icon(Icons.search, 
                            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),
                  
                  // Products grid with consistent column distribution - UPDATED
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getGridColumnCount(context),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: _getCardAspectRatio(context),
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

          // Cart panel (unchanged)
          Expanded(
            flex: isLargeDesktop ? 3 : 2,
            child: _buildCartPanel(primaryColor, isDarkMode, backgroundColor, cardColor, textColor, hintTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPanel(
    Color primaryColor, 
    bool isDarkMode, 
    Color backgroundColor, 
    Color cardColor,
    Color textColor,
    Color hintTextColor
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : cardColor,
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
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
                colors: isDarkMode
                    ? [
                        Colors.grey.shade800,
                        Colors.grey.shade900,
                      ]
                    : [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, 
                      color: isDarkMode ? primaryColor.withOpacity(0.8) : Colors.white, 
                      size: 24
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'SHOPPING CART',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? primaryColor.withOpacity(0.8) : Colors.white,
                      ),
                    ),
                  ],
                ),
                Badge(
                  label: Text('${_totalItemCount}', // CHANGED: Use totalItemCount
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : primaryColor,
                    ),
                  ),
                  backgroundColor: isDarkMode ? primaryColor : Colors.white,
                  textColor: isDarkMode ? Colors.white : primaryColor,
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
                          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add products to get started',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
                          ),
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
                                      color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _showCustomerForm ? Icons.expand_less : Icons.expand_more,
                                      size: 20,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
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
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        labelText: 'Customer Name *',
                                        labelStyle: TextStyle(color: hintTextColor),
                                        prefixIcon: Icon(Icons.person, 
                                          color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _customerPhoneController,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        labelText: 'Phone Number',
                                        labelStyle: TextStyle(color: hintTextColor),
                                        prefixIcon: Icon(Icons.phone, 
                                          color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _paymentMethod,
                                      dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        labelText: 'Payment Method',
                                        labelStyle: TextStyle(color: hintTextColor),
                                        prefixIcon: Icon(Icons.payment, 
                                          color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      items: ['Cash', 'GCash', 'Bank Transfer', 'Credit Card', 'PayMaya']
                                          .map((method) => DropdownMenuItem(
                                                value: method,
                                                child: Text(method,
                                                  style: TextStyle(
                                                    color: textColor,
                                                  ),
                                                ),
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
                                      style: TextStyle(color: textColor),
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        labelText: 'Order Notes (Optional)',
                                        labelStyle: TextStyle(color: hintTextColor),
                                        prefixIcon: Icon(Icons.note, 
                                          color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                            border: Border(
                              top: BorderSide(
                                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              // REMOVED: Subtotal display (not needed since total = subtotal)
                              // REMOVED: Tax display
                              _buildTotalRow('Total', _total, isDarkMode: isDarkMode, isBold: true, fontSize: 18),
                              const SizedBox(height: 16),
                              TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _amountPaid = double.tryParse(value) ?? 0;
                                  });
                                },
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Amount Paid *',
                                  labelStyle: TextStyle(color: hintTextColor),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: primaryColor,
                                    ),
                                  ),
                                  prefixText: '₱',
                                  prefixStyle: TextStyle(color: textColor),
                                  prefixIcon: Icon(Icons.money, 
                                    color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 8),
                              if (_amountPaid > 0)
                                _buildTotalRow(
                                  'Change',
                                  _change,
                                  isDarkMode: isDarkMode,
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
              color: isDarkMode ? Colors.grey.shade800 : cardColor,
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                ),
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
                    icon: const Icon(Icons.check_circle, size: 20, color: Colors.white),
                    label: const Text('PROCESS SALE', style: TextStyle(color: Colors.white)),
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

  Widget _buildTotalRow(String label, double amount, {
    bool isDarkMode = false,
    bool isBold = false, 
    Color? color, 
    double fontSize = 14
  }) {
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
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
 
  void _showCartModal(
    BuildContext context, 
    bool isDarkMode, 
    Color primaryColor, 
    Color cardColor,
    Color textColor,
    Color hintTextColor
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Helper function to update both parent and modal state
            void updateCartState(Function updateFunction) {
              // Update parent widget state
              setState(() {
                updateFunction();
              });
              // Also update the modal state to trigger rebuild
              setModalState(() {});
            }
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade900 : cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
                            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor,
                          ),
                        ),
                        // FIXED: Add a Key to force rebuild of the badge
                        ValueListenableBuilder<int>(
                          valueListenable: ValueNotifier<int>(_totalItemCount), // CHANGED: Use totalItemCount
                          builder: (context, count, child) {
                            return Badge(
                              label: Text('$count',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : primaryColor,
                                ),
                              ),
                              backgroundColor: isDarkMode ? primaryColor : Colors.white,
                              textColor: isDarkMode ? Colors.white : primaryColor,
                              largeSize: 24,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close, 
                            size: 24, 
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(height: 1, color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                  
                  Expanded(
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your cart is empty',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add products to get started',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // FIXED: Using ValueListenableBuilder to force rebuild of cart items
                                ValueListenableBuilder<List<TransactionItem>>(
                                  valueListenable: ValueNotifier<List<TransactionItem>>(_cartItems),
                                  builder: (context, cartItems, child) {
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: cartItems.length,
                                      itemBuilder: (context, index) {
                                        final item = cartItems[index];
                                        return _buildCartItemCardForModal(
                                          item, 
                                          index, 
                                          isDarkMode, 
                                          primaryColor,
                                          updateCartState
                                        );
                                      },
                                    );
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      // FIXED: Using ValueListenableBuilder for totals
                                      ValueListenableBuilder<double>(
                                        valueListenable: ValueNotifier<double>(_subtotal),
                                        builder: (context, subtotal, child) {
                                          return _buildTotalRowForModal('Subtotal', subtotal, isDarkMode: isDarkMode);
                                        },
                                      ),
                                      const Divider(),
                                      ValueListenableBuilder<double>(
                                        valueListenable: ValueNotifier<double>(_total),
                                        builder: (context, total, child) {
                                          return _buildTotalRowForModal('Total', total, isDarkMode: isDarkMode, isBold: true, fontSize: 18);
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: _customerNameController,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: 'Customer Name *',
                                          labelStyle: TextStyle(color: hintTextColor),
                                          prefixIcon: Icon(Icons.person, 
                                            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setModalState(() {});
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _customerPhoneController,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: 'Phone Number',
                                          labelStyle: TextStyle(color: hintTextColor),
                                          prefixIcon: Icon(Icons.phone, 
                                            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.phone,
                                        onChanged: (value) {
                                          setModalState(() {});
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        initialValue: _paymentMethod,
                                        dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: 'Payment Method',
                                          labelStyle: TextStyle(color: hintTextColor),
                                          prefixIcon: Icon(Icons.payment, 
                                            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                          ),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                        items: ['Cash', 'GCash', 'Bank Transfer', 'Credit Card', 'PayMaya']
                                            .map((method) => DropdownMenuItem(
                                                  value: method,
                                                  child: Text(method,
                                                    style: TextStyle(color: textColor),
                                                  ),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          setModalState(() {
                                            _paymentMethod = value!;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        onChanged: (value) {
                                          setModalState(() {
                                            _amountPaid = double.tryParse(value) ?? 0;
                                          });
                                        },
                                        style: TextStyle(color: textColor),
                                        decoration: InputDecoration(
                                          labelText: 'Amount Paid *',
                                          labelStyle: TextStyle(color: hintTextColor),
                                          border: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: primaryColor,
                                            ),
                                          ),
                                          prefixText: '₱',
                                          prefixStyle: TextStyle(color: textColor),
                                          prefixIcon: Icon(Icons.money, 
                                            color: isDarkMode ? primaryColor.withOpacity(0.8) : primaryColor
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        controller: TextEditingController(
                                          text: _amountPaid > 0 ? _amountPaid.toStringAsFixed(2) : '',
                                        ),
                                      ),
                                      if (_amountPaid > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: ValueListenableBuilder<double>(
                                            valueListenable: ValueNotifier<double>(_change),
                                            builder: (context, change, child) {
                                              return _buildTotalRowForModal(
                                                'Change',
                                                change,
                                                isDarkMode: isDarkMode,
                                                color: change >= 0 ? Colors.green : Colors.red,
                                                isBold: true,
                                              );
                                            },
                                          ),
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
                      color: isDarkMode ? Colors.grey.shade800 : cardColor,
                      border: Border(
                        top: BorderSide(
                          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // FIXED: Clear cart button with proper state management
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _clearCart(
                                onAfterClear: () {
                                  // This callback will be called after the cart is cleared
                                  setModalState(() {});
                                }
                              );
                            },
                            icon: const Icon(Icons.clear_all, size: 20),
                            label: const Text('CLEAR CART'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _processTransaction,
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text('PROCESS SALE', style: TextStyle(color: Colors.white)),
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

  Widget _buildCartItemCardForModal(
    TransactionItem item, 
    int index, 
    bool isDarkMode, 
    Color primaryColor,
    Function updateCartState  // This parameter must be defined
  ) {
    // Store the item name before any state changes
    final itemName = item.productName;
    
    return Card(
      key: ValueKey('${item.productId}-${item.quantity}'), // Key based on item state
      margin: const EdgeInsets.only(bottom: 8),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDarkMode 
              ? primaryColor.withOpacity(0.2)
              : primaryColor.withOpacity(0.1),
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
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '₱${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
          style: TextStyle(
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₱${item.total.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, 
                    color: Colors.orange, 
                    size: 20
                  ),
                  onPressed: () {
                    // Decrease quantity
                    if (item.quantity > 1) {
                      updateCartState(() {  // Using the updateCartState callback
                        _cartItems[index] = TransactionItem(
                          productId: item.productId,
                          productName: item.productName,
                          quantity: item.quantity - 1,
                          unitPrice: item.unitPrice,
                          total: item.unitPrice * (item.quantity - 1),
                        );
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Decreased ${item.productName} quantity'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      // Remove item if quantity is 1
                      updateCartState(() {  // Using the updateCartState callback
                        _cartItems.removeAt(index);
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed ${item.productName} from cart'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  tooltip: 'Decrease quantity',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, 
                    color: Colors.red, 
                    size: 20
                  ),
                  onPressed: () {
                    // Remove the entire item
                    updateCartState(() {
                      _cartItems.removeAt(index);
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed ${item.productName} from cart'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRowForModal(String label, double amount, {
    bool isDarkMode = false,
    bool isBold = false, 
    Color? color, 
    double fontSize = 14
  }) {
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
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: fontSize,
              color: color ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}