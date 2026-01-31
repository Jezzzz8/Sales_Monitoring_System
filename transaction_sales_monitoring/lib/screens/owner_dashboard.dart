// ignore_for_file: unused_field, unused_import

import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../utils/responsive.dart';
import '../models/notifications_data.dart';
import '../widgets/notifications_dialog.dart';
import 'pos_transaction.dart';
import 'transaction_monitoring.dart';
import 'sales_monitoring.dart';
import 'inventory_monitoring.dart';
import 'product_management.dart';
import 'settings.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/settings_service.dart';
import '../models/settings_model.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  String _selectedScreen = 'Dashboard';
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? _currentUser;
  AppSettings? _settings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadSettings();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      _settings = await SettingsService.loadSettings();
    } catch (e) {
      print('Error loading settings in owner dashboard: $e');
      _settings = AppSettings();
    }
    setState(() => _isLoadingSettings = false);
  }

  Color _getPrimaryColor() {
    return _settings!.primaryColorValue;
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const OwnerDashboardHome();
      case 1:
        return const POSTransaction();
      case 2:
        return const TransactionMonitoring();
      case 3:
        return const SalesMonitoring();
      case 4:
        return const InventoryMonitoring();
      case 5:
        return const ProductManagement();
      default:
        return const OwnerDashboardHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isMobile = Responsive.isMobile(context);
    final primaryColor = _getPrimaryColor();
    
    if (isMobile) {
      return _buildMobileLayout(primaryColor);
    } else {
      return _buildDesktopLayout(primaryColor);
    }
  }

  Widget _buildMobileLayout(Color primaryColor) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _selectedScreen,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  _showNotificationsDialog(context);
                },
                tooltip: 'Notifications',
              ),
              if (NotificationsData.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${NotificationsData.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: Drawer(
        child: OwnerSidebar(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            if (index == 6) { // Settings
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            } else if (index == 7) { // Notifications
              Navigator.pop(context);
              _showNotificationsDialog(context);
            } else {
              setState(() {
                _selectedIndex = index;
                _selectedScreen = _getScreenTitle(index);
              });
              Navigator.pop(context);
            }
          },
          isCollapsed: false,
          currentUser: _currentUser!,
          primaryColor: primaryColor,
        ),
      ),
      body: SafeArea(
        child: _getCurrentScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex < 6 ? _selectedIndex : 0,
        onTap: (index) {
          if (index < 6) {
            setState(() {
              _selectedIndex = index;
              _selectedScreen = _getScreenTitle(index);
            });
          }
        },
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Products',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Color primaryColor) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            OwnerSidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                if (index == 6) { // Settings
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                } else if (index == 7) { // Notifications
                  _showNotificationsDialog(context);
                } else {
                  setState(() {
                    _selectedIndex = index;
                    _selectedScreen = _getScreenTitle(index);
                  });
                }
              },
              isCollapsed: _isSidebarCollapsed,
              onToggle: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
              currentUser: _currentUser!,
              primaryColor: primaryColor,
            ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
                            color: primaryColor,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSidebarCollapsed = !_isSidebarCollapsed;
                            });
                          },
                          tooltip: _isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _selectedScreen,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _currentUser!.roleIcon,
                                color: primaryColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _currentUser!.roleDisplayName,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: Colors.grey),
                              onPressed: () {
                                _showNotificationsDialog(context);
                              },
                              tooltip: 'Notifications',
                            ),
                            if (NotificationsData.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${NotificationsData.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.grey),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          tooltip: 'Settings',
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentUser!.roleIcon,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _getCurrentScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScreenTitle(int index) {
    switch (index) {
      case 0: return 'Owner Dashboard';
      case 1: return 'POS Transaction';
      case 2: return 'Transaction History';
      case 3: return 'Sales Monitoring';
      case 4: return 'Inventory Monitoring';
      case 5: return 'Product Management';
      default: return 'Owner Dashboard';
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: const NotificationsDialog(),
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }
}

// Owner Dashboard Home Screen
class OwnerDashboardHome extends StatelessWidget {
  const OwnerDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: Responsive.getScreenPadding(context).top,
            bottom: Responsive.getScreenPadding(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Section
                Padding(
                  padding: Responsive.getSectionPadding(context),
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: Responsive.getCardPadding(context),
                      child: Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: Responsive.getIconSize(context, multiplier: 2.0),
                            color: primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome Business Owner",
                                  style: TextStyle(
                                    fontSize: Responsive.getTitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Complete Business Overview • Financial Monitoring",
                                  style: TextStyle(
                                    fontSize: Responsive.getBodyFontSize(context),
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // FINANCIAL OVERVIEW (Top Section - 4 items)
                Responsive.buildResponsiveCardGrid(
                  context: context,
                  title: "FINANCIAL OVERVIEW",
                  titleColor: primaryColor,
                  centerTitle: true,
                  cards: [
                    _buildOverviewCard(
                      "Total Revenue", "₱850,000", 
                      Icons.attach_money, Colors.green, context,
                    ),
                    _buildOverviewCard(
                      "Monthly Sales", "₱85,000", 
                      Icons.trending_up, Colors.blue, context,
                    ),
                    _buildOverviewCard(
                      "Net Profit", "₱255,000", 
                      Icons.account_balance_wallet, Colors.purple, context,
                    ),
                    _buildOverviewCard(
                      "Active Orders", "25", 
                      Icons.receipt, Colors.orange, context,
                    ),
                  ],
                ),

                // BUSINESS PERFORMANCE (Bottom Section - 3 items)
                Responsive.buildResponsiveCardGrid(
                  context: context,
                  title: "BUSINESS PERFORMANCE",
                  titleColor: primaryColor,
                  centerTitle: true,
                  cards: [
                    _buildActionCard(
                      "Customers", "+15% growth", 
                      Icons.people, Colors.green, context,
                    ),
                    _buildActionCard(
                      "Inventory", "₱150,000", 
                      Icons.inventory, Colors.blue, context,
                    ),
                    _buildActionCard(
                      "Fulfillment", "98.5%", 
                      Icons.check_circle, Colors.purple, context,
                    ),
                  ],
                ),

                SizedBox(height: Responsive.getLargeSpacing(context).height),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color, 
      BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: 100,
        maxHeight: 120,
      ),
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 8, tablet: 10, desktop: 12)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: color, 
            size: Responsive.getIconSize(context, multiplier: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 11, desktop: 12),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, 
      BuildContext context, {VoidCallback? onTap}) {
    final cardContent = Container(
      constraints: BoxConstraints(
        minHeight: 80,
        maxHeight: 100,
      ),
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 6, tablet: 8, desktop: 10)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: color, 
            size: Responsive.getIconSize(context, multiplier: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 8, tablet: 9, desktop: 10),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: cardContent,
      );
    }
    
    return cardContent;
  }
}

// Owner Sidebar
class OwnerSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isCollapsed;
  final Function()? onToggle;
  final User currentUser;
  final Color primaryColor;

  const OwnerSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.onToggle,
    required this.currentUser,
    required this.primaryColor,
  });

  @override
  State<OwnerSidebar> createState() => _OwnerSidebarState();
}

class _OwnerSidebarState extends State<OwnerSidebar> {
  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return Container(
        width: 70,
        color: Colors.white,
        child: Column(
          children: [
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
                  _buildCollapsedNavItem(index: 0, icon: Icons.dashboard, isSelected: widget.selectedIndex == 0),
                  _buildCollapsedNavItem(index: 1, icon: Icons.point_of_sale, isSelected: widget.selectedIndex == 1),
                  _buildCollapsedNavItem(index: 2, icon: Icons.receipt_long, isSelected: widget.selectedIndex == 2),
                  _buildCollapsedNavItem(index: 3, icon: Icons.trending_up, isSelected: widget.selectedIndex == 3),
                  _buildCollapsedNavItem(index: 4, icon: Icons.inventory, isSelected: widget.selectedIndex == 4),
                  _buildCollapsedNavItem(index: 5, icon: Icons.restaurant_menu, isSelected: widget.selectedIndex == 5),
                  const SizedBox(height: 16),
                  _buildCollapsedNavItem(index: 6, icon: Icons.settings, isSelected: widget.selectedIndex == 6),
                  _buildCollapsedNavItem(index: 7, icon: Icons.notifications, isSelected: widget.selectedIndex == 7),
                ],
              ),
            ),
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

    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(index: 0, icon: Icons.dashboard, label: 'Dashboard', isSelected: widget.selectedIndex == 0),
                const Divider(height: 1),
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
                _buildNavItem(index: 1, icon: Icons.point_of_sale, label: 'POS Transaction', isSelected: widget.selectedIndex == 1),
                _buildNavItem(index: 2, icon: Icons.receipt_long, label: 'Transaction History', isSelected: widget.selectedIndex == 2),
                _buildNavItem(index: 3, icon: Icons.trending_up, label: 'Sales Monitoring', isSelected: widget.selectedIndex == 3),
                const Divider(height: 1),
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
                _buildNavItem(index: 4, icon: Icons.inventory, label: 'Inventory Monitoring', isSelected: widget.selectedIndex == 4),
                _buildNavItem(index: 5, icon: Icons.restaurant_menu, label: 'Product Management', isSelected: widget.selectedIndex == 5),
                const Divider(height: 1),
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
                _buildNavItem(index: 6, icon: Icons.settings, label: 'Settings', isSelected: widget.selectedIndex == 6),
                _buildNavItem(index: 7, icon: Icons.notifications, label: 'Notifications', isSelected: widget.selectedIndex == 7, showBadge: true),
              ],
            ),
          ),
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
          Icon(icon, color: isSelected ? widget.primaryColor : Colors.grey),
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
      default: return '';
    }
  }
}