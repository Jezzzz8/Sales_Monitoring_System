import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final VoidCallback? onPrintReceipt;
  final VoidCallback? onMarkComplete;
  final bool showActions;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onPrintReceipt,
    this.onMarkComplete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: Responsive.getPaddingSize(context)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: Responsive.getCardPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.transactionNumber,
                      style: TextStyle(
                        fontSize: Responsive.getSubtitleFontSize(context),
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  _buildStatusChip(transaction.status),
                ],
              ),
              
              Responsive.getSmallSpacing(context),
              
              // Customer Info
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: Responsive.getIconSize(context, multiplier: 0.8),
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.customerName,
                          style: TextStyle(
                            fontSize: Responsive.getBodyFontSize(context),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (transaction.customerPhone.isNotEmpty)
                          Text(
                            transaction.customerPhone,
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              Responsive.getSmallSpacing(context),
              
              // Date and Payment Info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: Responsive.getIconSize(context, multiplier: 0.7),
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    transaction.formattedDate,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.payment,
                    size: Responsive.getIconSize(context, multiplier: 0.7),
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    transaction.paymentMethod,
                    style: TextStyle(
                      fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              Responsive.getSpacing(context),
              
              // Items Summary
              if (transaction.items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            size: Responsive.getIconSize(context, multiplier: 0.7),
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${transaction.items.length} item${transaction.items.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...transaction.items.take(2).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const SizedBox(width: 24),
                            Expanded(
                              child: Text(
                                '• ${item.productName} x${item.quantity}',
                                style: TextStyle(
                                  fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '₱${item.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                      if (transaction.items.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '+${transaction.items.length - 2} more items',
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Responsive.getSpacing(context),
              ],
              
              // Amount and Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(context, mobile: 11, tablet: 12, desktop: 13),
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₱${transaction.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: Responsive.getSubtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  
                  if (showActions && !isMobile) ...[
                    Row(
                      children: [
                        if (onPrintReceipt != null)
                          IconButton(
                            icon: const Icon(Icons.receipt, size: 20),
                            color: Colors.deepOrange,
                            onPressed: onPrintReceipt,
                            tooltip: 'Print Receipt',
                          ),
                        if (onMarkComplete != null && transaction.status == 'Pending')
                          IconButton(
                            icon: const Icon(Icons.check_circle, size: 20),
                            color: Colors.green,
                            onPressed: onMarkComplete,
                            tooltip: 'Mark as Complete',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              
              // Action Buttons for Mobile
              if (showActions && isMobile) ...[
                Responsive.getSpacing(context),
                const Divider(height: 1),
                Responsive.getSmallSpacing(context),
                Row(
                  children: [
                    if (onPrintReceipt != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPrintReceipt,
                          icon: const Icon(Icons.receipt, size: 16),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (onPrintReceipt != null && onMarkComplete != null)
                      const SizedBox(width: 8),
                    if (onMarkComplete != null && transaction.status == 'Pending')
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMarkComplete,
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Complete'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              
              // Notes (if available)
              if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                Responsive.getSpacing(context),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: Responsive.getIconSize(context, multiplier: 0.7),
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.notes!,
                          style: TextStyle(
                            fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData? icon;
    
    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'pending':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.pending;
        break;
      case 'cancelled':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        icon = Icons.info;
    }
    
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...[
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
        ],
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}