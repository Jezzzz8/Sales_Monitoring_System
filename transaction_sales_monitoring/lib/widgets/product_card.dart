import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/responsive.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool showAddButton;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.showAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = Responsive.getCardPadding(context);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image/Icon
              Container(
                height: Responsive.getCardHeight(context, multiplier: 0.4),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _getCategoryGradient(product.categoryId),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getCategoryIcon(product.categoryId),
                        color: _getCategoryColor(product.categoryId),
                        size: Responsive.getIconSize(context, multiplier: 1.5),
                      ),
                    ),
                    if (product.needsReorder)
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
              Responsive.getSmallSpacing(context),
              
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
              
              // Product Price
              Text(
                '₱${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              
              Responsive.getSmallSpacing(context),
              
              // Category
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
              
              // Stock Information
              Row(
                children: [
                  Icon(
                    Icons.inventory,
                    size: Responsive.getIconSize(context, multiplier: 0.6),
                    color: product.needsReorder ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Stock: ${product.stock}',
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                      color: product.needsReorder ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              
              // Add to Cart Button (if applicable)
              if (showAddButton && onAddToCart != null) ...[
                Responsive.getSmallSpacing(context),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getCategoryGradient(String category) {
    switch (category) {
      case 'Whole Lechon':
        return [Colors.deepOrange.shade50, Colors.orange.shade50];
      case 'Lechon Belly':
        return [Colors.orange.shade50, Colors.amber.shade50];
      case 'Appetizers':
        return [Colors.blue.shade50, Colors.cyan.shade50];
      default:
        return [Colors.grey.shade50, Colors.grey.shade100];
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Whole Lechon':
        return Icons.celebration;
      case 'Lechon Belly':
        return Icons.restaurant_menu;
      case 'Appetizers':
        return Icons.local_fire_department;
      default:
        return Icons.fastfood;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Whole Lechon':
        return Colors.deepOrange;
      case 'Lechon Belly':
        return Colors.orange;
      case 'Appetizers':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}