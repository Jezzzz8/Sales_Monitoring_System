import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../utils/theme_provider.dart';
import '../utils/responsive.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  List<User> _users = [];
  final List<User> _selectedUsers = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  UserRole _selectedRole = UserRole.staff;
  bool _isActive = true;
  bool _isEditing = false;
  String _editingUserId = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Custom roles management
  final List<CustomRole> _customRoles = [
    CustomRole(
      id: '1',
      name: 'Manager',
      permissions: ['view_reports', 'edit_products', 'manage_inventory'],
    ),
    CustomRole(
      id: '2',
      name: 'Supervisor',
      permissions: ['view_reports', 'approve_orders'],
    ),
    CustomRole(
      id: '3',
      name: 'Helpdesk',
      permissions: ['view_users', 'reset_passwords'],
    ),
  ];
  
  // Groups management
  final List<UserGroup> _groups = [
    UserGroup(
      id: '1',
      name: 'Administrators',
      description: 'Full system access',
      memberCount: 2,
    ),
    UserGroup(
      id: '2',
      name: 'Sales Team',
      description: 'POS and transaction access',
      memberCount: 3,
    ),
    UserGroup(
      id: '3',
      name: 'Inventory Team',
      description: 'Stock and supply management',
      memberCount: 2,
    ),
  ];
  
  // For bulk role assignment
  UserRole? _bulkRoleSelection;
  String? _bulkCustomRoleSelection;
  String? _bulkGroupSelection;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final users = AuthService.getUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelectionMode(bool enabled) {
    setState(() {
      _isSelectionMode = enabled;
      if (!enabled) {
        _selectedUsers.clear();
      }
    });
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
        if (_selectedUsers.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedUsers.add(user);
        if (!_isSelectionMode) {
          _isSelectionMode = true;
        }
      }
    });
  }

  void _selectAllUsers() {
    setState(() {
      _selectedUsers.clear();
      _selectedUsers.addAll(_filteredUsers);
      _isSelectionMode = true;
    });
  }

  void _deselectAllUsers() {
    setState(() {
      _selectedUsers.clear();
      _isSelectionMode = false;
    });
  }

  void _showAddUserDialog() {
    _resetForm();
    _isEditing = false;
    showDialog(
      context: context,
      builder: (context) => _buildUserFormDialog(),
    ).then((_) => _resetForm());
  }

  void _showEditUserDialog(User user) {
    _usernameController.text = user.username;
    _fullNameController.text = user.fullName;
    _emailController.text = user.email;
    _phoneController.text = user.phone ?? '';
    _addressController.text = user.address ?? '';
    _selectedRole = user.role;
    _isActive = user.isActive;
    _isEditing = true;
    _editingUserId = user.id;

    showDialog(
      context: context,
      builder: (context) => _buildUserFormDialog(),
    ).then((_) => _resetForm());
  }

  Widget _buildUserFormDialog() {
    final theme = ThemeProvider.of(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * (isMobile ? 0.9 : 0.8),
          maxWidth: isMobile ? double.infinity : 600,
        ),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.person_add_alt_1,
                    color: Colors.white,
                    size: isMobile ? 24 : 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit User Profile' : 'Create New User',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () {
                      Navigator.pop(context);
                      _resetForm();
                    },
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionHeader('Basic Information', Icons.person_outline),
                      const SizedBox(height: 12),
                      
                      // Mobile layout - full width fields stacked
                      if (isMobile)
                        Column(
                          children: [
                            _buildFormField(
                              controller: _usernameController,
                              label: 'Username',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (_users.any((u) => u.username == value && u.id != _editingUserId)) {
                                  return 'Username already exists';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            if (!_isEditing)
                              Column(
                                children: [
                                  _buildFormField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    validator: (value) {
                                      if (!_isEditing && (value == null || value.isEmpty)) {
                                        return 'Please enter a password';
                                      }
                                      if (value != null && value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            _buildFormField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              icon: Icons.badge_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              controller: _emailController,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                if (_users.any((u) => u.email == value && u.id != _editingUserId)) {
                                  return 'Email already exists';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            _buildFormField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                            ),
                          ],
                        )
                      else
                        // Tablet/Desktop layout - grid with consistent widths
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            // First row: Username and Password (if creating)
                            SizedBox(
                              width: isTablet ? (MediaQuery.of(context).size.width * 0.5) - 30 : 280,
                              child: _buildFormField(
                                controller: _usernameController,
                                label: 'Username',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  if (_users.any((u) => u.username == value && u.id != _editingUserId)) {
                                    return 'Username already exists';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (!_isEditing)
                              SizedBox(
                                width: isTablet ? (MediaQuery.of(context).size.width * 0.5) - 30 : 280,
                                child: _buildFormField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                  validator: (value) {
                                    if (!_isEditing && (value == null || value.isEmpty)) {
                                      return 'Please enter a password';
                                    }
                                    if (value != null && value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            // Full width fields
                            SizedBox(
                              width: double.infinity,
                              child: _buildFormField(
                                controller: _fullNameController,
                                label: 'Full Name',
                                icon: Icons.badge_outlined,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter full name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: _buildFormField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  if (_users.any((u) => u.email == value && u.id != _editingUserId)) {
                                    return 'Email already exists';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            // Half width fields for phone and address
                            SizedBox(
                              width: (MediaQuery.of(context).size.width * 0.5) - 30,
                              child: _buildFormField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            SizedBox(
                              width: (MediaQuery.of(context).size.width * 0.5) - 30,
                              child: _buildFormField(
                                controller: _addressController,
                                label: 'Address',
                                icon: Icons.location_on_outlined,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Role Assignment Section
                      _buildSectionHeader('Role & Permissions', Icons.security),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.getSubtitleColor().withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.getSubtitleColor().withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Role',
                              style: theme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.getTextColor(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // System Roles - Wrap with flexible width
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: UserRole.values.map((role) {
                                final isSelected = _selectedRole == role;
                                final roleColor = _getRoleColor(role);
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isMobile ? (MediaQuery.of(context).size.width - 48) / 2 : 150,
                                  ),
                                  child: ChoiceChip(
                                    label: Text(
                                      _getRoleDisplayName(role),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : roleColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    selected: isSelected,
                                    selectedColor: roleColor,
                                    backgroundColor: roleColor.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: roleColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedRole = role;
                                        }
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Custom Roles
                            Text(
                              'Custom Roles',
                              style: theme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.getTextColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _customRoles.map((role) {
                                return ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: isMobile ? (MediaQuery.of(context).size.width - 48) / 2 : 120,
                                  ),
                                  child: FilterChip(
                                    label: Text(
                                      role.name,
                                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    selected: false,
                                    onSelected: (selected) {
                                      _showCustomRoleDetails(role);
                                    },
                                    backgroundColor: Colors.grey.withOpacity(0.1),
                                    selectedColor: theme.primaryColor.withOpacity(0.2),
                                    checkmarkColor: theme.primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Center(
                              child: TextButton.icon(
                                onPressed: _showCreateCustomRoleDialog,
                                icon: Icon(Icons.add, color: theme.primaryColor, size: 20),
                                label: Text(
                                  'Create Custom Role',
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Group Assignment Section
                      _buildSectionHeader('Group Assignment', Icons.group),
                      const SizedBox(height: 12),
                      
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _groups.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _groups.length) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 0 : 8,
                                  right: 8,
                                ),
                                child: _buildAddGroupCard(),
                              );
                            }
                            final group = _groups[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                left: index == 0 ? 0 : 8,
                                right: index == _groups.length - 1 ? 8 : 0,
                              ),
                              child: _buildGroupCard(group),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Account Status Section
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _isActive 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isActive ? Icons.check_circle : Icons.remove_circle,
                              color: _isActive ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            'Account Status',
                            style: theme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _isActive 
                                ? 'User can login and access the system'
                                : 'User account is suspended',
                            style: theme.bodySmall,
                          ),
                          trailing: Switch.adaptive(
                            value: _isActive,
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            setState(() {
                              _isActive = !_isActive;
                            });
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action Buttons - Responsive layout
                      isMobile
                          ? Column(
                              children: [
                                if (_isEditing)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _showResetPasswordDialog,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.orange,
                                        side: const BorderSide(color: Colors.orange),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      icon: const Icon(Icons.lock_reset, size: 20),
                                      label: const Text('Reset Password'),
                                    ),
                                  ),
                                if (_isEditing) const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _saveUser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    icon: Icon(
                                      _isEditing ? Icons.save : Icons.person_add,
                                      size: 20,
                                    ),
                                    label: Text(
                                      _isEditing ? 'Save Changes' : 'Create User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_isEditing)
                                  OutlinedButton.icon(
                                    onPressed: _showResetPasswordDialog,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.lock_reset, size: 18),
                                    label: const Text('Reset Password'),
                                  ),
                                if (_isEditing) const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _saveUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: Icon(
                                    _isEditing ? Icons.save : Icons.person_add,
                                    size: 20,
                                  ),
                                  label: Text(
                                    _isEditing ? 'Save Changes' : 'Create User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = ThemeProvider.of(context);
    final isMobile = Responsive.isMobile(context);
    
    return Row(
      children: [
        Icon(icon, size: isMobile ? 18 : 20, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.getTextColor(),
            fontSize: isMobile ? 16 : theme.titleMedium.fontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    final theme = ThemeProvider.of(context);
    final isMobile = Responsive.isMobile(context);
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: isMobile ? 18 : 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        ),
        filled: true,
        fillColor: theme.getSubtitleColor().withOpacity(0.05),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 16,
          vertical: isMobile ? 12 : 14,
        ),
        isDense: isMobile,
      ),
      style: theme.bodyMedium.copyWith(
        fontSize: isMobile ? 14 : 16,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildGroupCard(UserGroup group) {
    final theme = ThemeProvider.of(context);
    final isMobile = Responsive.isMobile(context);
    
    return SizedBox(
      width: isMobile ? 130 : 140,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
        ),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.group, size: isMobile ? 16 : 18, color: theme.primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.name,
                      style: theme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 13 : 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                group.description,
                style: theme.bodySmall.copyWith(
                  fontSize: isMobile ? 11 : 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${group.memberCount} members',
                style: theme.bodySmall.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 11 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddGroupCard() {
    final theme = ThemeProvider.of(context);
    final isMobile = Responsive.isMobile(context);
    
    return SizedBox(
      width: isMobile ? 130 : 140,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
          side: BorderSide(
            color: theme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        color: theme.primaryColor.withOpacity(0.05),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: theme.primaryColor,
                size: isMobile ? 28 : 32,
              ),
              const SizedBox(height: 6),
              Text(
                'Create Group',
                style: theme.bodyMedium.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 13 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Colors.deepPurple;
      case UserRole.admin:
        return Colors.blue;
      case UserRole.cashier:
        return Colors.green;
      case UserRole.staff:
        return Colors.orange;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.staff:
        return 'Staff';
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final user = User(
        id: _editingUserId,
        username: _usernameController.text,
        password: _isEditing ? '' : _passwordController.text,
        fullName: _fullNameController.text,
        email: _emailController.text,
        role: _selectedRole,
        isActive: _isActive,
        createdAt: DateTime.now(),
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        address: _addressController.text.isEmpty ? null : _addressController.text,
      );

      try {
        if (_isEditing) {
          AuthService.updateUser(user);
        } else {
          AuthService.addUser(user);
        }
        
        Navigator.pop(context);
        await _loadUsers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'User updated successfully!' : 'User added successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    _fullNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedRole = UserRole.staff;
    _isActive = true;
    _isEditing = false;
    _editingUserId = '';
  }

  void _showResetPasswordDialog() {
    final theme = ThemeProvider.of(context);
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: theme.primaryColor),
            const SizedBox(width: 12),
            const Text('Reset Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter new password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value != newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text.isNotEmpty) {
                // Update user with new password
                final updatedUser = User(
                  id: _editingUserId,
                  username: _usernameController.text,
                  password: newPasswordController.text,
                  fullName: _fullNameController.text,
                  email: _emailController.text,
                  role: _selectedRole,
                  isActive: _isActive,
                  createdAt: DateTime.now(),
                  phone: _phoneController.text.isEmpty ? null : _phoneController.text,
                  address: _addressController.text.isEmpty ? null : _addressController.text,
                );
                
                AuthService.updateUser(updatedUser);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password reset successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _showCustomRoleDetails(CustomRole role) {
    final theme = ThemeProvider.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Role: ${role.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Permissions:'),
              const SizedBox(height: 8),
              ...role.permissions.map((permission) => 
                ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green, size: 20),
                  title: Text(permission.replaceAll('_', ' ').toUpperCase()),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement role assignment
            },
            child: Text(
              'Assign Role',
              style: TextStyle(color: theme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCustomRoleDialog() {
    final theme = ThemeProvider.of(context);
    final roleNameController = TextEditingController();
    final List<String> selectedPermissions = [];
    final List<String> availablePermissions = [
      'view_dashboard',
      'manage_users',
      'manage_products',
      'manage_inventory',
      'view_reports',
      'edit_settings',
      'approve_orders',
      'reset_passwords',
    ];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.isMobile(context) 
                  ? MediaQuery.of(context).size.width * 0.9
                  : 500,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Custom Role',
                    style: theme.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: roleNameController,
                    decoration: const InputDecoration(
                      labelText: 'Role Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Select Permissions',
                    style: theme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.getSubtitleColor().withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availablePermissions.length,
                        itemBuilder: (context, index) {
                          final permission = availablePermissions[index];
                          final isSelected = selectedPermissions.contains(permission);
                          return CheckboxListTile(
                            title: Text(permission.replaceAll('_', ' ').toUpperCase()),
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedPermissions.add(permission);
                                } else {
                                  selectedPermissions.remove(permission);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (roleNameController.text.isNotEmpty && selectedPermissions.isNotEmpty) {
                            final newRole = CustomRole(
                              id: (_customRoles.length + 1).toString(),
                              name: roleNameController.text,
                              permissions: selectedPermissions,
                            );
                            _customRoles.add(newRole);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create Role'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBulkActionDialog() {
    final theme = ThemeProvider.of(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.isMobile(context) 
                  ? MediaQuery.of(context).size.width * 0.9
                  : 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bulk Actions (${_selectedUsers.length} users selected)',
                    style: theme.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  
                  // Role Assignment
                  ExpansionTile(
                    title: const Text('Change Roles'),
                    leading: Icon(Icons.security, color: theme.primaryColor),
                    initiallyExpanded: true,
                    children: [
                      Column(
                        children: UserRole.values.map((role) {
                          return RadioListTile<UserRole>(
                            title: Text(
                              _getRoleDisplayName(role),
                              style: TextStyle(color: _getRoleColor(role)),
                            ),
                            value: role,
                            groupValue: _bulkRoleSelection,
                            onChanged: (value) {
                              setState(() {
                                _bulkRoleSelection = value;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (_bulkRoleSelection != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: ElevatedButton(
                            onPressed: () {
                              // Update selected users with new role
                              for (final user in _selectedUsers) {
                                final updatedUser = user.copyWith(role: _bulkRoleSelection!);
                                AuthService.updateUser(updatedUser);
                              }
                              Navigator.pop(context);
                              _loadUsers();
                              _toggleSelectionMode(false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Apply Role to Selected Users'),
                          ),
                        ),
                    ],
                  ),
                  
                  // Status Change
                  ExpansionTile(
                    title: const Text('Change Status'),
                    leading: Icon(Icons.person_outline, color: theme.primaryColor),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Responsive.getOrientationFlexLayout(
                          context,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  for (final user in _selectedUsers) {
                                    AuthService.toggleUserStatus(user.id);
                                  }
                                  Navigator.pop(context);
                                  _loadUsers();
                                  _toggleSelectionMode(false);
                                },
                                icon: Icon(Icons.person_off, color: Colors.white, size: 20),
                                label: const Text('Deactivate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12, height: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  for (final user in _selectedUsers) {
                                    final updatedUser = user.copyWith(isActive: true);
                                    AuthService.updateUser(updatedUser);
                                  }
                                  Navigator.pop(context);
                                  _loadUsers();
                                  _toggleSelectionMode(false);
                                },
                                icon: Icon(Icons.person_add, color: Colors.white, size: 20),
                                label: const Text('Activate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Delete Users
                  ExpansionTile(
                    title: const Text('Delete Users'),
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warning: This will permanently delete ${_selectedUsers.length} user(s)',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text(
                                      'Are you sure you want to delete ${_selectedUsers.length} user(s)? This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  for (final user in _selectedUsers) {
                                    AuthService.deleteUser(user.id);
                                  }
                                  Navigator.pop(context);
                                  _loadUsers();
                                  _toggleSelectionMode(false);
                                }
                              },
                              icon: const Icon(Icons.delete_forever, color: Colors.white, size: 20),
                              label: const Text('Delete Selected Users'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(String userId) async {
    try {
      AuthService.toggleUserStatus(userId);
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete user "$username"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone. All user data will be permanently removed.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        AuthService.deleteUser(userId);
        await _loadUsers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('User deleted successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) {
      return user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             user.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeProvider.of(context);
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        centerTitle: true,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _toggleSelectionMode(false),
              tooltip: 'Cancel selection',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add User'),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.primaryColor),
                  const SizedBox(height: 16),
                  Text('Loading users...', style: theme.bodyMedium),
                ],
              ),
            )
          : Column(
              children: [
                // Header with search and bulk actions
                Container(
                  padding: EdgeInsets.all(Responsive.getPaddingSize(context)),
                  decoration: BoxDecoration(
                    color: theme.getSubtitleColor().withOpacity(0.05),
                    border: Border(bottom: BorderSide(color: theme.getSubtitleColor().withOpacity(0.1))),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'System Users',
                            style: theme.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_users.length} users',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Search and bulk actions row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search users...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: theme.surfaceColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          if (isMobile)
                            const SizedBox(width: 8),
                          if (_isSelectionMode && _selectedUsers.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _showBulkActionDialog,
                              icon: const Icon(Icons.settings, size: 20),
                              label: Text('Bulk (${_selectedUsers.length})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: isMobile 
                                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Users List
                Expanded(
                  child: _filteredUsers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchQuery.isEmpty 
                                      ? Icons.people_outline
                                      : Icons.search_off,
                                  size: 80,
                                  color: theme.getSubtitleColor(),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No users found'
                                      : 'No users match your search',
                                  style: theme.bodyLarge,
                                  textAlign: TextAlign.center,
                                ),
                                if (_searchQuery.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: ElevatedButton.icon(
                                      onPressed: _showAddUserDialog,
                                      icon: const Icon(Icons.person_add),
                                      label: const Text('Add First User'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(Responsive.getPaddingSize(context)),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final isSelected = _selectedUsers.contains(user);
                            return GestureDetector(
                              onLongPress: () {
                                if (!_isSelectionMode) {
                                  _toggleSelectionMode(true);
                                }
                                _toggleUserSelection(user);
                              },
                              child: _buildUserCard(user, isSelected, theme),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserCard(User user, bool isSelected, AppTheme theme) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: isSelected
            ? Border.all(color: theme.primaryColor, width: 2)
            : null,
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? theme.primaryColor.withOpacity(0.05)
            : theme.surfaceColor,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (_isSelectionMode) {
              _toggleUserSelection(user);
            } else {
              _showEditUserDialog(user);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Row(
              children: [
                // Selection checkbox
                if (_isSelectionMode)
                  Padding(
                    padding: EdgeInsets.only(right: isMobile ? 8 : 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleUserSelection(user),
                      activeColor: theme.primaryColor,
                    ),
                  ),
                
                // Avatar
                Container(
                  width: isMobile ? 42 : 48,
                  height: isMobile ? 42 : 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        user.roleColor,
                        user.roleColor.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user.roleIcon,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.fullName,
                              style: theme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 15 : 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isActive 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: user.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username} • ${user.email}',
                        style: theme.bodySmall.copyWith(
                          fontSize: isMobile ? 12 : 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              user.roleDisplayName,
                              style: TextStyle(
                                color: user.roleColor,
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: user.roleColor.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                if (!_isSelectionMode)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: theme.primaryColor,
                          size: isMobile ? 20 : 24,
                        ),
                        onPressed: () => _showEditUserDialog(user),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(
                          user.isActive ? Icons.person_off : Icons.person_add,
                          color: user.isActive ? Colors.red : Colors.green,
                          size: isMobile ? 20 : 24,
                        ),
                        onPressed: () => _toggleUserStatus(user.id),
                        tooltip: user.isActive ? 'Deactivate' : 'Activate',
                      ),
                      if (user.role != UserRole.owner)
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: isMobile ? 20 : 24,
                          ),
                          onPressed: () => _deleteUser(user.id, user.username),
                          tooltip: 'Delete',
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Custom Role Model
class CustomRole {
  final String id;
  final String name;
  final List<String> permissions;
  
  CustomRole({
    required this.id,
    required this.name,
    required this.permissions,
  });
}

// User Group Model
class UserGroup {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  
  UserGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
  });
}