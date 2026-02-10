// lib/widgets/transaction_card.dart - FIXED VERSION with Proper Payment Logic
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/responsive.dart';
import '../providers/theme_provider.dart';

class TransactionCard extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onPrintReceipt;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onUpdatePayment;
  final VoidCallback? onCancelOrder;
  final Function(double)? onPartialPayment;
  final bool showActions;
  final bool isExpanded;
  final Function(bool)? onExpansionChanged;
  final Color? primaryColor;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onPrintReceipt,
    this.onMarkComplete,
    this.onUpdatePayment,
    this.onCancelOrder,
    this.onPartialPayment,
    this.showActions = true,
    this.isExpanded = false,
    this.onExpansionChanged,
    this.primaryColor,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = false;
  final TextEditingController _partialPaymentController = TextEditingController();
  bool _isProcessingPartialPayment = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  void dispose() {
    _partialPaymentController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return widget.primaryColor ?? theme.primaryColor;
  }

  Color _getTextColor(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return theme.getTextColor();
  }

  Color _getSubtitleColor(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return theme.getSubtitleColor();
  }

  Color _getSurfaceColor(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return theme.surfaceColor;
  }

  Color _getIconColor(BuildContext context) {
    final theme = ThemeProvider.of(context);
    return theme.getIconColor();
  }

  // Helper method to append amount to the input field
  void _appendAmountToInput(int amount) {
    final currentText = _partialPaymentController.text;
    final currentAmount = double.tryParse(currentText) ?? 0;
    final newAmount = currentAmount + amount;
    
    // Check if new amount exceeds remaining balance
    final remainingBalance = widget.transaction.totalAmount - widget.transaction.amountPaid;
    if (newAmount > remainingBalance) {
      _showSnackbar('Cannot exceed remaining balance of ₱${remainingBalance.toStringAsFixed(2)}', Colors.red);
      return;
    }
    
    _partialPaymentController.text = newAmount.toStringAsFixed(2);
    
    // Move cursor to end
    _partialPaymentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _partialPaymentController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final theme = ThemeProvider.of(context);
    final isDarkMode = theme.isDarkMode;
    final primaryColor = _getPrimaryColor(context);
    final textColor = _getTextColor(context);
    final mutedTextColor = _getSubtitleColor(context);
    final cardColor = _getSurfaceColor(context);
    final iconColor = _getIconColor(context);
    final isPartialPayment = widget.transaction.status == 'Partial';
    final remainingBalance = widget.transaction.totalAmount - widget.transaction.amountPaid;
    
    // Use primary color for section titles in both light and dark modes
    final sectionTitleColor = primaryColor;
    
    // Background colors for sections
    final sectionBgColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final cardBorderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    
    // Define bill denominations - including 50 pesos
    final billDenominations = [50, 100, 200, 500, 1000];
    
    return Card(
      elevation: isDarkMode ? 1 : 2,
      margin: EdgeInsets.only(bottom: Responsive.getPaddingSize(context)),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardBorderColor,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        key: ValueKey(widget.transaction.id),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
          widget.onExpansionChanged?.call(expanded);
        },
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
          child: Icon(
            isPartialPayment ? Icons.payments : Icons.receipt,
            color: primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          widget.transaction.displayTransactionNumber,
          style: TextStyle(
            fontSize: Responsive.getSubtitleFontSize(context),
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.transaction.formattedDate} • ${widget.transaction.formattedTime}',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? primaryColor.withOpacity(0.7) : mutedTextColor,
              ),
            ),
            Text(
              widget.transaction.customerName,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusChip(
              widget.transaction.status, 
              primaryColor: primaryColor, 
              isDarkMode: isDarkMode
            ),
            const SizedBox(width: 8),
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isDarkMode ? primaryColor : mutedTextColor,
              size: 20,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add collapse button at the top
                if (widget.onExpansionChanged != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.unfold_less, 
                        size: 20,
                        color: _getIconColor(context),
                      ),
                      onPressed: () {
                        widget.onExpansionChanged?.call(false);
                      },
                      tooltip: 'Collapse',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                // Customer Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sectionBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOMER DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sectionTitleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: iconColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.transaction.customerName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.transaction.customerPhone.isNotEmpty && widget.transaction.customerPhone != '-')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 14,
                                color: iconColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.transaction.customerPhone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? textColor : mutedTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Payment Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sectionBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: cardBorderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAYMENT DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: sectionTitleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.payment,
                            size: 16,
                            color: iconColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.transaction.paymentMethod,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cash Received:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? primaryColor.withOpacity(0.8) : mutedTextColor,
                            ),
                          ),
                          Text(
                            '₱${widget.transaction.cashReceived.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? primaryColor.withOpacity(0.8) : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Amount Paid:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? primaryColor.withOpacity(0.8) : mutedTextColor,
                            ),
                          ),
                          Text(
                            '₱${widget.transaction.amountPaid.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cash Received:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? primaryColor.withOpacity(0.8) : mutedTextColor,
                            ),
                          ),
                          Text(
                            '₱${widget.transaction.cashReceived.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? primaryColor.withOpacity(0.8) : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Change:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? primaryColor.withOpacity(0.8) : mutedTextColor,
                            ),
                          ),
                          Text(
                            '₱${widget.transaction.change.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.transaction.change >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      
                      // For Partial Payments: Show remaining balance and update form
                      if (isPartialPayment) ...[
                        const SizedBox(height: 12),
                        Divider(color: isDarkMode ? primaryColor.withOpacity(0.3) : mutedTextColor.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'PARTIAL PAYMENT DETAILS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount Due:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                              ),
                            ),
                            Text(
                              '₱${widget.transaction.totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount Paid (Down Payment):',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? primaryColor.withOpacity(0.8) : mutedTextColor,
                              ),
                            ),
                            Text(
                              '₱${widget.transaction.amountPaid.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cash Received:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? primaryColor.withOpacity(0.8) : mutedTextColor,
                              ),
                            ),
                            Text(
                              '₱${widget.transaction.cashReceived.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? primaryColor.withOpacity(0.8) : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining Balance:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₱${remainingBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        
                        // Show message if transaction is fully paid
                        if (remainingBalance <= 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.green.shade900 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDarkMode ? Colors.green.shade300 : Colors.green.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: isDarkMode ? Colors.green.shade300 : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Transaction is fully paid! Status will be automatically updated to "Completed".',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDarkMode ? Colors.green.shade300 : Colors.green.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Partial Payment Update Form
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Payment',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sectionTitleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _partialPaymentController,
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(
                                      hintText: 'Enter amount',
                                      hintStyle: TextStyle(color: isDarkMode ? primaryColor.withOpacity(0.5) : mutedTextColor),
                                      prefixText: '₱',
                                      prefixStyle: TextStyle(color: textColor),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? primaryColor.withOpacity(0.3) : Colors.grey.shade400,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? primaryColor.withOpacity(0.3) : Colors.grey.shade400,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isProcessingPartialPayment
                                      ? null
                                      : _processPartialPayment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Colors.orange.shade800 : Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isProcessingPartialPayment
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text('Apply Payment'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quick amounts (Click to add):',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode ? primaryColor.withOpacity(0.7) : mutedTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: billDenominations.where((amount) => amount <= remainingBalance).map((amount) {
                                return ElevatedButton(
                                  onPressed: () => _appendAmountToInput(amount),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                    foregroundColor: isDarkMode ? Colors.orange.shade300 : Colors.orange,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    minimumSize: const Size(0, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text('+₱$amount'),
                                );
                              }).toList(),
                            ),
                            
                            // Clear button
                            if (_partialPaymentController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      _partialPaymentController.clear();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      minimumSize: const Size(0, 24),
                                    ),
                                    child: Text(
                                      'Clear input',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDarkMode ? Colors.red.shade300 : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Items List
                if (widget.transaction.items.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sectionBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cardBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ORDER ITEMS (${widget.transaction.items.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sectionTitleColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...widget.transaction.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.quantity} × ₱${item.unitPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDarkMode ? textColor : mutedTextColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₱${item.total.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Notes
                if (widget.transaction.notes != null && widget.transaction.notes!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sectionBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cardBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOTES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sectionTitleColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.transaction.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Action Buttons - REMOVED Complete button since it happens automatically
                if (widget.showActions)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onPrintReceipt,
                          icon: Icon(
                            Icons.picture_as_pdf, 
                            size: 16, 
                            color: primaryColor,
                          ),
                          label: Text(
                            'Generate PDF',
                            style: TextStyle(color: primaryColor),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isPartialPayment) ...[
                        if (widget.onCancelOrder != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onCancelOrder,
                              icon: Icon(
                                Icons.cancel, 
                                size: 16, 
                                color: isDarkMode ? Colors.red.shade300 : Colors.red,
                              ),
                              label: Text(
                                'Cancel',
                                style: TextStyle(color: isDarkMode ? Colors.red.shade300 : Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: isDarkMode ? Colors.red.shade300 : Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, {Color? primaryColor, bool isDarkMode = false}) {
    Color chipColor;
    Color textColor;
    IconData? icon;
    
    switch (status.toLowerCase()) {
      case 'completed':
        chipColor = isDarkMode ? Colors.green.shade900 : Colors.green.shade100;
        textColor = isDarkMode ? Colors.green.shade200 : Colors.green.shade800;
        icon = Icons.check_circle;
        break;
      case 'partial':
        chipColor = isDarkMode ? Colors.orange.shade900 : Colors.orange.shade100;
        textColor = isDarkMode ? Colors.orange.shade200 : Colors.orange.shade800;
        icon = Icons.payments;
        break;
      case 'cancelled':
        chipColor = isDarkMode ? Colors.red.shade900 : Colors.red.shade100;
        textColor = isDarkMode ? Colors.red.shade200 : Colors.red.shade800;
        icon = Icons.cancel;
        break;
      default:
        chipColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100;
        textColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800;
        icon = Icons.info;
    }
    
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: textColor.withOpacity(isDarkMode ? 0.3 : 0.2),
          width: 1,
        ),
      ),
    );
  }

  void _processPartialPayment() async {
    if (_partialPaymentController.text.isEmpty) {
      _showSnackbar('Please enter the payment amount', Colors.red);
      return;
    }

    final amount = double.tryParse(_partialPaymentController.text);
    if (amount == null || amount <= 0) {
      _showSnackbar('Please enter a valid payment amount', Colors.red);
      return;
    }

    final remainingBalance = widget.transaction.totalAmount - widget.transaction.amountPaid;
    if (amount > remainingBalance) {
      _showSnackbar('Amount exceeds remaining balance (₱${remainingBalance.toStringAsFixed(2)})', Colors.red);
      return;
    }

    setState(() {
      _isProcessingPartialPayment = true;
    });

    try {
      if (widget.onPartialPayment != null) {
        // Process the partial payment - this should update the transaction's amountPaid
        await widget.onPartialPayment!(amount);
        
        // Clear the input field after successful payment
        _partialPaymentController.clear();
        
        // Calculate new remaining balance (should be automatically updated by parent)
        final newRemainingBalance = remainingBalance - amount;
        
        _showSnackbar(
          'Payment of ₱${amount.toStringAsFixed(2)} recorded successfully.',
          Colors.green,
        );
        
        // If fully paid, show additional message
        if (newRemainingBalance <= 0) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _showSnackbar(
                'Transaction is now fully paid! Status updated to "Completed".',
                Colors.green,
              );
            }
          });
        }
      } else if (widget.onUpdatePayment != null) {
        widget.onUpdatePayment!();
        _partialPaymentController.clear();
      }
    } catch (e) {
      _showSnackbar('Error processing payment: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPartialPayment = false;
        });
      }
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    final theme = ThemeProvider.of(context);
    final isDarkMode = theme.isDarkMode;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}