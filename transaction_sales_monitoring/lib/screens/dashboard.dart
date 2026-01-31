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

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  String _selectedScreen = 'Dashboard';
  bool _isSidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Define screens
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardHome();
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
        return const DashboardHome();
    }
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
        backgroundColor: Colors.deepOrange,
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
        child: Sidebar(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            if (index == 6) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            } else if (index == 7) {
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
        selectedItemColor: Colors.deepOrange,
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

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                if (index == 6) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                } else if (index == 7) {
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
            ),
            Expanded(
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            color: Colors.deepOrange,
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const Spacer(),
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
                            color: Colors.deepOrange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.deepOrange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                  // Main Content Area
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
      case 0: return 'Dashboard';
      case 1: return 'POS Transaction';
      case 2: return 'Transaction History';
      case 3: return 'Sales Monitoring';
      case 4: return 'Inventory Monitoring';
      case 5: return 'Product Management';
      default: return 'Dashboard';
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

// Dashboard Home Screen
class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getScreenPadding(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                    minHeight: 100,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepOrange,
                        Colors.orange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome to Gene's Lechon Admin System",
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(
                                    context, mobile: 16, tablet: 18, desktop: 20),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Transaction & Sales Monitoring Dashboard",
                              style: TextStyle(
                                fontSize: Responsive.getFontSize(
                                    context, mobile: 12, tablet: 14, desktop: 16),
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Stats
                Text(
                  "QUICK STATS",
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                        context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.1 : 1.0,
                  children: [
                    _buildStatCard("Total Sales", "₱85,000", 
                        Icons.attach_money, Colors.green, context),
                    _buildStatCard("Today's Transactions", "25", 
                        Icons.receipt, Colors.blue, context),
                    _buildStatCard("Active Products", "12", 
                        Icons.restaurant_menu, Colors.orange, context),
                    _buildStatCard("Low Stock Items", "3", 
                        Icons.warning, Colors.red, context),
                    _buildStatCard("Today's Customers", "8", 
                        Icons.people, Colors.purple, context),
                    _buildStatCard("Inventory Items", "15", 
                        Icons.inventory, Colors.teal, context),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick Actions
                Text(
                  "QUICK ACTIONS",
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                        context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isMobile ? 1.1 : 1.0,
                  children: [
                    _buildActionCard("Record Sale", Icons.add_circle, Colors.deepOrange, () {
                      // Change screen to POS within the dashboard
                      final state = context.findAncestorStateOfType<_DashboardState>();
                      state?.setState(() {
                        state._selectedIndex = 1;
                        state._selectedScreen = 'POS Transaction';
                      });
                    }, context),
                    _buildActionCard("View Reports", Icons.assessment, Colors.green, () {
                      // Change screen to Sales Monitoring within the dashboard
                      final state = context.findAncestorStateOfType<_DashboardState>();
                      state?.setState(() {
                        state._selectedIndex = 3;
                        state._selectedScreen = 'Sales Monitoring';
                      });
                    }, context),
                    _buildActionCard("Check Inventory", Icons.inventory, Colors.blue, () {
                      // Change screen to Inventory Monitoring within the dashboard
                      final state = context.findAncestorStateOfType<_DashboardState>();
                      state?.setState(() {
                        state._selectedIndex = 4;
                        state._selectedScreen = 'Inventory Monitoring';
                      });
                    }, context),
                    _buildActionCard("Manage Products", Icons.restaurant_menu, Colors.orange, () {
                      // Change screen to Product Management within the dashboard
                      final state = context.findAncestorStateOfType<_DashboardState>();
                      state?.setState(() {
                        state._selectedIndex = 5;
                        state._selectedScreen = 'Product Management';
                      });
                    }, context),
                    _buildActionCard("View Transactions", Icons.history, Colors.purple, () {
                      // Change screen to Transaction History within the dashboard
                      final state = context.findAncestorStateOfType<_DashboardState>();
                      state?.setState(() {
                        state._selectedIndex = 2;
                        state._selectedScreen = 'Transaction History';
                      });
                    }, context),
                    _buildActionCard("Settings", Icons.settings, Colors.teal, () {
                      // Settings needs to be navigated separately since it's not in the main screens
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    }, context),
                  ],
                ),

                const SizedBox(height: 32),

                Container(
                  constraints: const BoxConstraints(minHeight: 150),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SYSTEM MANAGEMENT",
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                              context, mobile: 14, tablet: 16, desktop: 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildManagementCard(
                              "Inventory Categories",
                              "Manage livestock & raw materials",
                              Icons.inventory,
                              Colors.deepOrange,
                              () {
                                Navigator.pushNamed(context, '/inventory-categories');
                              },
                              context,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildManagementCard(
                              "Product Categories",
                              "Manage menu items for POS",
                              Icons.restaurant_menu,
                              Colors.blue,
                              () {
                                Navigator.pushNamed(context, '/product-categories');
                              },
                              context,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Recent Transactions
                Container(
                  constraints: BoxConstraints(
                    minHeight: 200,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "RECENT TRANSACTIONS",
                            style: TextStyle(
                              fontSize: Responsive.getFontSize(
                                  context, mobile: 14, tablet: 16, desktop: 18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Change screen to Transaction History
                              final state = context.findAncestorStateOfType<_DashboardState>();
                              state?.setState(() {
                                state._selectedIndex = 2;
                                state._selectedScreen = 'Transaction History';
                              });
                            },
                            child: const Text(
                              "View All",
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 150,
                        child: _buildRecentTransactionsTable(isMobile),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // System Reminders
                Container(
                  constraints: BoxConstraints(
                    minHeight: 150,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SYSTEM REMINDERS",
                        style: TextStyle(
                          fontSize: Responsive.getFontSize(
                              context, mobile: 14, tablet: 16, desktop: 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildReminderItem(Icons.check_circle, Colors.green,
                          "Record all sales transactions daily", context),
                      _buildReminderItem(Icons.check_circle, Colors.green,
                          "Update product prices regularly", context),
                      _buildReminderItem(Icons.warning, Colors.red,
                          "Do not share login credentials", context),
                      _buildReminderItem(Icons.warning, Colors.red,
                          "Do not skip transaction recording", context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsTable(bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 500,
          ),
          child: DataTable(
            columnSpacing: 20,
            horizontalMargin: 12,
            headingRowHeight: 40,
            dataRowHeight: 40,
            columns: const [
              DataColumn(label: Text("Time")),
              DataColumn(label: Text("Customer")),
              DataColumn(label: Text("Amount")),
              DataColumn(label: Text("Status")),
            ],
            rows: [
              DataRow(cells: [
                DataCell(const Text("10:30 AM")),
                DataCell(const Text("Juan D.")),
                DataCell(const Text("₱2,700")),
                DataCell(const Chip(
                  label: Text("Paid"),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                )),
              ]),
              DataRow(cells: [
                DataCell(const Text("11:45 AM")),
                DataCell(const Text("Maria S.")),
                DataCell(const Text("₱8,000")),
                DataCell(const Chip(
                  label: Text("Paid"),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                )),
              ]),
              DataRow(cells: [
                DataCell(const Text("2:15 PM")),
                DataCell(const Text("Pedro G.")),
                DataCell(const Text("₱900")),
                DataCell(const Chip(
                  label: Text("Pending"),
                  backgroundColor: Colors.orange,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                )),
              ]),
            ],
          ),
        ),
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 700,
          ),
          child: DataTable(
            columnSpacing: 20,
            headingRowHeight: 40,
            dataRowHeight: 40,
            columns: const [
              DataColumn(label: Text("Time")),
              DataColumn(label: Text("Customer")),
              DataColumn(label: Text("Items")),
              DataColumn(label: Text("Amount")),
              DataColumn(label: Text("Status")),
            ],
            rows: [
              DataRow(cells: [
                DataCell(const Text("10:30 AM")),
                DataCell(const Text("Juan Dela Cruz")),
                DataCell(const Text("Lechon Belly")),
                DataCell(const Text("₱2,700")),
                DataCell(const Chip(
                  label: Text("Completed"),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                )),
              ]),
              DataRow(cells: [
                DataCell(const Text("11:45 AM")),
                DataCell(const Text("Maria Santos")),
                DataCell(const Text("Whole Lechon")),
                DataCell(const Text("₱8,000")),
                DataCell(const Chip(
                  label: Text("Completed"),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                )),
              ]),
              DataRow(cells: [
                DataCell(const Text("2:15 PM")),
                DataCell(const Text("Pedro Gomez")),
                DataCell(const Text("Pork BBQ")),
                DataCell(const Text("₱900")),
                DataCell(const Chip(
                  label: Text("Pending"),
                  backgroundColor: Colors.orange,
                  labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                )),
              ]),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color,
      BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: color,
                size: Responsive.getFontSize(context, mobile: 24, tablet: 28, desktop: 32)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap,
      BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: color,
                  size: Responsive.getFontSize(context, mobile: 28, tablet: 32, desktop: 36)),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderItem(IconData icon, Color color, String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: color,
              size: Responsive.getFontSize(context, mobile: 18, tablet: 20, desktop: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: Responsive.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
              ),
            ),
          ),
        ],
      )
    );
  }

  Widget _buildManagementCard(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap, BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}