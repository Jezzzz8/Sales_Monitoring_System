import 'package:flutter/material.dart';
import 'package:transaction_sales_monitoring/services/auth_service.dart';
import '../models/user_model.dart';

class AdminSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final Function()? onToggle;
  final User currentUser;
  final Color primaryColor;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggle,
    required this.currentUser,
    required this.primaryColor,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return Container(
        width: 70,
        color: Colors.white,
        child: Column(
          children: [
            // Header (Collapsed)
            Container(
              padding: const EdgeInsets.all(16),
              color: widget.primaryColor,
              child: Icon(
                widget.currentUser.roleIcon,
                color: Colors.white,
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildCollapsedNavItem(
                    index: 0,
                    icon: Icons.dashboard,
                    isSelected: widget.selectedIndex == 0,
                  ),
                  _buildCollapsedNavItem(
                    index: 1,
                    icon: Icons.point_of_sale,
                    isSelected: widget.selectedIndex == 1,
                  ),
                  _buildCollapsedNavItem(
                    index: 2,
                    icon: Icons.receipt_long,
                    isSelected: widget.selectedIndex == 2,
                  ),
                  _buildCollapsedNavItem(
                    index: 3,
                    icon: Icons.trending_up,
                    isSelected: widget.selectedIndex == 3,
                  ),
                  _buildCollapsedNavItem(
                    index: 4,
                    icon: Icons.inventory,
                    isSelected: widget.selectedIndex == 4,
                  ),
                  _buildCollapsedNavItem(
                    index: 5,
                    icon: Icons.restaurant_menu,
                    isSelected: widget.selectedIndex == 5,
                  ),
                  const SizedBox(height: 16),
                  // Admin only items
                  if (widget.currentUser.role == UserRole.admin)
                    _buildCollapsedNavItem(
                      index: 8,
                      icon: Icons.people,
                      isSelected: widget.selectedIndex == 8,
                    ),
                  _buildCollapsedNavItem(
                    index: 6,
                    icon: Icons.settings,
                    isSelected: widget.selectedIndex == 6,
                  ),
                  _buildCollapsedNavItem(
                    index: 7,
                    icon: Icons.notifications,
                    isSelected: widget.selectedIndex == 7,
                  ),
                ],
              ),
            ),

            // Logout Button (Collapsed)
            Container(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            AuthService.logout();
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red, size: 24),
                tooltip: 'Logout',
              ),
            ),
          ],
        ),
      );
    }

    // Expanded sidebar for desktop
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          // Header with user info
          Container(
            padding: const EdgeInsets.all(20),
            color: widget.primaryColor,
            child: Column(
              children: [
                Icon(
                  widget.currentUser.roleIcon,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.currentUser.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.currentUser.roleDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: widget.selectedIndex == 0,
                ),
                const Divider(height: 1),
                
                // Sales & Transaction Section
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'SALES & TRANSACTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.point_of_sale,
                  label: 'POS Transaction',
                  isSelected: widget.selectedIndex == 1,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.receipt_long,
                  label: 'Transaction History',
                  isSelected: widget.selectedIndex == 2,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.trending_up,
                  label: 'Sales Monitoring',
                  isSelected: widget.selectedIndex == 3,
                ),
                const Divider(height: 1),

                // Product & Inventory Section
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'PRODUCT & INVENTORY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.inventory,
                  label: 'Inventory Monitoring',
                  isSelected: widget.selectedIndex == 4,
                ),
                _buildNavItem(
                  index: 5,
                  icon: Icons.restaurant_menu,
                  label: 'Product Management',
                  isSelected: widget.selectedIndex == 5,
                ),
                const Divider(height: 1),

                // Admin Only Section
                if (widget.currentUser.role == UserRole.admin) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      'ADMINISTRATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  _buildNavItem(
                    index: 8,
                    icon: Icons.people,
                    label: 'User Management',
                    isSelected: widget.selectedIndex == 8,
                  ),
                  const Divider(height: 1),
                ],

                // System Section
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildNavItem(
                  index: 6,
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: widget.selectedIndex == 6,
                ),
                _buildNavItem(
                  index: 7,
                  icon: Icons.notifications,
                  label: 'Notifications',
                  isSelected: widget.selectedIndex == 7,
                  showBadge: true,
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          AuthService.logout();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('LOGOUT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    bool showBadge = false,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          Icon(
            icon,
            color: isSelected ? widget.primaryColor : Colors.grey,
          ),
          if (showBadge && index == 7)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? widget.primaryColor : Colors.black87,
        ),
      ),
      tileColor: isSelected ? widget.primaryColor.withOpacity(0.1) : null,
      selected: isSelected,
      onTap: () => widget.onItemSelected(index),
    );
  }

  Widget _buildCollapsedNavItem({
    required int index,
    required IconData icon,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? widget.primaryColor.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? widget.primaryColor : Colors.grey,
        ),
        onPressed: () => widget.onItemSelected(index),
        tooltip: _getTooltip(index),
      ),
    );
  }

  String _getTooltip(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'POS Transaction';
      case 2: return 'Transaction History';
      case 3: return 'Sales Monitoring';
      case 4: return 'Inventory Monitoring';
      case 5: return 'Product Management';
      case 6: return 'Settings';
      case 7: return 'Notifications';
      case 8: return 'User Management';
      default: return '';
    }
  }
}