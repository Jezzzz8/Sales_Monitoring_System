import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final Function()? onToggle;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isCollapsed) {
      return Container(
        width: 70,
        color: Colors.white,
        child: Column(
          children: [
            // Header (Collapsed)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.deepOrange,
              child: const Icon(
                Icons.restaurant,
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
                    isSelected: selectedIndex == 0,
                  ),
                  _buildCollapsedNavItem(
                    index: 1,
                    icon: Icons.point_of_sale,
                    isSelected: selectedIndex == 1,
                  ),
                  _buildCollapsedNavItem(
                    index: 2,
                    icon: Icons.receipt_long,
                    isSelected: selectedIndex == 2,
                  ),
                  _buildCollapsedNavItem(
                    index: 3,
                    icon: Icons.trending_up,
                    isSelected: selectedIndex == 3,
                  ),
                  _buildCollapsedNavItem(
                    index: 4,
                    icon: Icons.inventory,
                    isSelected: selectedIndex == 4,
                  ),
                  _buildCollapsedNavItem(
                    index: 5,
                    icon: Icons.restaurant_menu,
                    isSelected: selectedIndex == 5,
                  ),
                  const SizedBox(height: 16),
                  _buildCollapsedNavItem(
                    index: 6,
                    icon: Icons.settings,
                    isSelected: selectedIndex == 6,
                  ),
                  _buildCollapsedNavItem(
                    index: 7,
                    icon: Icons.notifications,
                    isSelected: selectedIndex == 7,
                  ),
                ],
              ),
            ),

            // Logout Button (Collapsed)
            Container(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
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
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.deepOrange,
            child: Column(
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Gene's Lechon",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "Admin System",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
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
                  isSelected: selectedIndex == 0,
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
                  isSelected: selectedIndex == 1,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.receipt_long,
                  label: 'Transaction History',
                  isSelected: selectedIndex == 2,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.trending_up,
                  label: 'Sales Monitoring',
                  isSelected: selectedIndex == 3,
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
                  isSelected: selectedIndex == 4,
                ),
                _buildNavItem(
                  index: 5,
                  icon: Icons.restaurant_menu,
                  label: 'Product Management',
                  isSelected: selectedIndex == 5,
                ),
                const Divider(height: 1),

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
                  isSelected: selectedIndex == 6,
                ),
                _buildNavItem(
                  index: 7,
                  icon: Icons.notifications,
                  label: 'Notifications',
                  isSelected: selectedIndex == 7,
                  showBadge: true,
                ),
              ],
            ),
          ),

          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
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
            color: isSelected ? Colors.deepOrange : Colors.grey,
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
          color: isSelected ? Colors.deepOrange : Colors.black87,
        ),
      ),
      tileColor: isSelected ? Colors.deepOrange.withOpacity(0.1) : null,
      selected: isSelected,
      onTap: () => onItemSelected(index),
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
        color: isSelected ? Colors.deepOrange.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? Colors.deepOrange : Colors.grey,
        ),
        onPressed: () => onItemSelected(index),
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
      default: return '';
    }
  }
}