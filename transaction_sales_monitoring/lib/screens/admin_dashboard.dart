// ignore_for_file: unused_field, unused_import

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/theme_provider.dart';
import '../models/user_model.dart';
import 'cashier_dashboard.dart';
import 'owner_dashboard.dart';
import 'staff_dashboard.dart';
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
import '../services/settings_service.dart';
import '../models/settings_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
    
    // Listen for settings changes
    SettingsService.notifier.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    SettingsService.notifier.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {
        _settings = SettingsService.notifier.currentSettings;
      });
    }
  }

Future<void> _loadSettings() async {
  setState(() => _isLoadingSettings = true);
  try {
    // Get initial settings
    _settings = await SettingsService.loadSettings();
  } catch (e) {
    print('Error loading settings: $e');
    _settings = AppSettings();
  }
  setState(() => _isLoadingSettings = false);
}

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  // Define screens based on selected index (FIXED: Now returns actual screens)
  Widget _getCurrentScreen() {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Based on selected index, return appropriate screen
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboardHome();
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
        return const AdminDashboardHome();
    }
  }

  Color _getPrimaryColor() {
    final themeProvider = ThemeProvider.watch(context);
    return _settings?.primaryColorValue ?? themeProvider.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Redirect to role-specific dashboard if trying to access wrong one
    if (_currentUser!.role != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        switch (_currentUser!.role) {
          case UserRole.owner:
            Navigator.pushReplacementNamed(context, '/owner-dashboard');
            break;
          case UserRole.cashier:
            Navigator.pushReplacementNamed(context, '/cashier-dashboard');
            break;
          case UserRole.staff:
            Navigator.pushReplacementNamed(context, '/staff-dashboard');
            break;
          default:
            break;
        }
      });
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
          _selectedScreen, // Use the selected screen title
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
        child: AdminSidebar(
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
            } else if (index == 8) { // User Management
              Navigator.pop(context);
              Navigator.pushNamed(context, '/users');
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
        child: _getCurrentScreen(), // This now returns the correct screen based on selected index
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
            AdminSidebar(
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
                } else if (index == 8) { // User Management
                  Navigator.pushNamed(context, '/users');
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
                          _selectedScreen, // Use the selected screen title
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const Spacer(),
                        // User Role Badge with primary color
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
                        // Notification Icon with Badge
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
                  // Main Content Area
                  Expanded(
                    child: _getCurrentScreen(), // This now returns the correct screen based on selected index
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
      case 0: return 'Admin Dashboard';
      case 1: return 'POS Transaction';
      case 2: return 'Transaction History';
      case 3: return 'Sales Monitoring';
      case 4: return 'Inventory Monitoring';
      case 5: return 'Product Management';
      default: return 'Admin Dashboard';
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

// Admin Dashboard Home Screen
class AdminDashboardHome extends StatelessWidget {
  const AdminDashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    final primaryColor = theme.primaryColor;
    
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
                // Welcome Section with improved design - USING THEME COLOR
                Padding(
                  padding: Responsive.getSectionPadding(context),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: Responsive.getCardPadding(context),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.admin_panel_settings,
                              size: Responsive.getIconSize(context, multiplier: 1.8),
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Welcome Administrator",
                                  style: TextStyle(
                                    fontSize: Responsive.getTitleFontSize(context),
                                    fontWeight: FontWeight.bold,
                                    color: theme.getTextColor(emphasized: true), // USING THEME TEXT COLOR
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Full System Access • User Management • Business Oversight",
                                  style: TextStyle(
                                    fontSize: Responsive.getBodyFontSize(context),
                                    color: theme.getSubtitleColor(), // USING THEME SUBTITLE COLOR
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified, size: 14, color: primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // SYSTEM OVERVIEW - Update titles to use theme color
                Responsive.buildResponsiveCardGrid(
                  context: context,
                  title: "SYSTEM OVERVIEW",
                  titleColor: primaryColor,
                  centerTitle: true,
                  cards: [
                    _buildStatCard(
                      "Total Users", "4", 
                      Icons.people, Colors.purple, context,
                    ),
                    _buildStatCard(
                      "Active Sessions", "1", 
                      Icons.security, Colors.green, context,
                    ),
                    _buildStatCard(
                      "System Uptime", "99.9%", 
                      Icons.timer, Colors.blue, context,
                    ),
                    _buildStatCard(
                      "Today's Logins", "1", 
                      Icons.login, Colors.orange, context,
                    ),
                  ],
                ),

                // USER MANAGEMENT - Update titles to use theme color
                Responsive.buildResponsiveCardGrid(
                  context: context,
                  title: "USER MANAGEMENT",
                  titleColor: primaryColor,
                  centerTitle: true,
                  cards: [
                    _buildActionCard(
                      "Add New User", "Create new account", 
                      Icons.person_add, Colors.green, context,
                      onTap: () => Navigator.pushNamed(context, '/users'),
                    ),
                    _buildActionCard(
                      "View All Users", "Manage permissions", 
                      Icons.list, Colors.blue, context,
                      onTap: () => Navigator.pushNamed(context, '/users'),
                    ),
                    _buildActionCard(
                      "Role Management", "Assign roles", 
                      Icons.manage_accounts, Colors.purple, context,
                      onTap: () => Navigator.pushNamed(context, '/users'),
                    ),
                  ],
                ),

                // SYSTEM MANAGEMENT - Update titles to use theme color
                Responsive.buildResponsiveCardGrid(
                  context: context,
                  title: "SYSTEM MANAGEMENT",
                  titleColor: primaryColor,
                  centerTitle: true,
                  cards: [
                    _buildActionCard(
                      "Inventory", "Monitor stock", 
                      Icons.inventory, Colors.deepOrange, context,
                      onTap: () => Navigator.pushNamed(context, '/inventory-categories'),
                    ),
                    _buildActionCard(
                      "Products", "Manage menu", 
                      Icons.restaurant_menu, Colors.blue, context,
                      onTap: () => Navigator.pushNamed(context, '/product-categories'),
                    ),
                    _buildActionCard(
                      "Settings", "Configure system", 
                      Icons.settings, Colors.purple, context,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      "Reports", "View analytics", 
                      Icons.analytics, Colors.teal, context,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reports feature coming soon'),
                          backgroundColor: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                // Quick Stats Row - Update to use theme color
                Padding(
                  padding: Responsive.getSectionPadding(context),
                  child: Card(
                    elevation: 3,
                    child: Padding(
                      padding: Responsive.getCardPadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "QUICK STATS",
                            style: TextStyle(
                              fontSize: Responsive.getSubtitleFontSize(context),
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickStatItem("Total Sales", "₱850,000", Icons.attach_money, Colors.green, context),
                              _buildQuickStatItem("Active Orders", "25", Icons.receipt, Colors.orange, context),
                              _buildQuickStatItem("Inventory Value", "₱150,000", Icons.inventory, Colors.blue, context),
                              _buildQuickStatItem("Customers", "45", Icons.people, Colors.purple, context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.getLargeSpacing(context).height),
              ],
            ),
          ),
        );
      },
    );
  }

    Widget _buildStatCard(String title, String value, IconData icon, Color color, 
      BuildContext context) {
    final theme = ThemeProvider.of(context);
    
    return Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 8, tablet: 10, desktop: 12)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: Responsive.getIconSize(context, multiplier: 1.2)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14) * 0.9,
              color: theme.getSubtitleColor(), // USING THEME SUBTITLE COLOR
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 14, tablet: 16, desktop: 18) * 0.9,
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
    final theme = ThemeProvider.of(context);
    
    final cardContent = Container(
      padding: EdgeInsets.all(Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14) * 0.8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: Responsive.getIconSize(context, multiplier: 1.2)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16) * 0.9,
              fontWeight: FontWeight.bold,
              color: theme.getTextColor(emphasized: true), // USING THEME TEXT COLOR
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14) * 0.9,
                color: theme.getSubtitleColor(), // USING THEME SUBTITLE COLOR
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
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    }
    
    return cardContent;
  }

  Widget _buildQuickStatItem(String title, String value, IconData icon, Color color, BuildContext context) {
    final theme = ThemeProvider.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: theme.getSubtitleColor(), // USING THEME SUBTITLE COLOR
          ),
        ),
      ],
    );
  }
}