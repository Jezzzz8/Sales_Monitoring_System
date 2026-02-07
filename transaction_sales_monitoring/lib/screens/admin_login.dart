// lib/screens/admin_login.dart - FIXED VERSION
import 'package:flutter/material.dart';
import '../widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart' as app_user;
import '../utils/responsive.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await AuthService.getSavedCredentials();
    if (mounted) {
      setState(() {
        _emailController.text = credentials['email'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
        _rememberMe = credentials['rememberMe'] ?? false;
      });
    }
  }
  
  void _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    LoadingOverlay.show(context, message: 'Authenticating...');

    try {
      final result = await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      LoadingOverlay.hide();

      if (result['success'] == true) {
        await AuthService.saveCredentials(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _rememberMe,
        );

        final user = result['user'] as app_user.User;
        _redirectToDashboard(user.role);
      } else {
        _showErrorSnackbar(result['message'] ?? 'Login failed');
      }
    } catch (e) {
      LoadingOverlay.hide();
      _showErrorSnackbar('Login error: ${e.toString()}');
    }
  }

  void _redirectToDashboard(app_user.UserRole role) {
    String route;
    switch (role) {
      case app_user.UserRole.owner:
        route = '/owner-dashboard';
        break;
      case app_user.UserRole.admin:
        route = '/dashboard';
        break;
      case app_user.UserRole.cashier:
        route = '/cashier-dashboard';
        break;
      case app_user.UserRole.clerk:
        route = '/staff-dashboard';
        break;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, route);
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper methods to safely get responsive values
  double _safeSpacing(BuildContext context) => Responsive.getSpacing(context).height ?? 20.0;
  double _safeSmallSpacing(BuildContext context) => Responsive.getSmallSpacing(context).height ?? 8.0;
  double _safeLargeSpacing(BuildContext context) => Responsive.getLargeSpacing(context).height ?? 32.0;
  // ignore: unused_element
  double _safeHorizontalSpacing(BuildContext context) => Responsive.getHorizontalSpacing(context).width ?? 16.0;

  Widget _buildDesktopTabletUI(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTablet = Responsive.isTablet(context);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final inputBgColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final cardBgColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade800,
              Colors.deepOrange.shade400,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 500 : 600,
                    ),
                    margin: EdgeInsets.all(_safeSpacing(context)),
                    child: Card(
                      elevation: 20,
                      color: cardBgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 30.0 : 40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo and Title Section
                            Container(
                              width: isTablet ? 80 : 100,
                              height: isTablet ? 80 : 100,
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.deepOrange.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                size: isTablet ? 50 : 60,
                                color: Colors.deepOrange,
                              ),
                            ),
                            SizedBox(height: _safeLargeSpacing(context)),
                            
                            Text(
                              "Gene's Lechon System",
                              style: TextStyle(
                                fontSize: isTablet ? 26 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: _safeSmallSpacing(context)),
                            
                            Text(
                              "Secure Role-Based Access System",
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 16,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: _safeLargeSpacing(context) * 1.5),
                            
                            // Login Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 16,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: const TextStyle(color: Colors.deepOrange),
                                      prefixIcon: const Icon(Icons.email, color: Colors.deepOrange),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      filled: true,
                                      fillColor: inputBgColor,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: isTablet ? 16 : 18,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: _safeLargeSpacing(context)),
                                  
                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      fontSize: isTablet ? 14 : 16,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(color: Colors.deepOrange),
                                      prefixIcon: const Icon(Icons.lock, color: Colors.deepOrange),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.deepOrange,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      filled: true,
                                      fillColor: inputBgColor,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: isTablet ? 16 : 18,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: _safeSpacing(context)),
                                  
                                  // Remember Me Checkbox
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 1.2,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: Colors.deepOrange,
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: _safeSmallSpacing(context)),
                                      Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 15,
                                          color: subtitleColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {},
                                        child: Text(
                                          'Need help?',
                                          style: TextStyle(
                                            color: Colors.deepOrange,
                                            fontSize: isTablet ? 14 : 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: _safeLargeSpacing(context) * 1.5),
                                  
                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: isTablet ? 50 : 56,
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                        shadowColor: Colors.deepOrange.withOpacity(0.3),
                                      ),
                                      child: Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontSize: isTablet ? 15 : 17,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: _safeLargeSpacing(context) * 1.5),
                            
                            // Security Footer
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: borderColor,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.security,
                                    size: isTablet ? 16 : 18,
                                    color: Colors.deepOrange.shade600,
                                  ),
                                  SizedBox(width: _safeSmallSpacing(context)),
                                  Text(
                                    'Secure Authentication System',
                                    style: TextStyle(
                                      fontSize: isTablet ? 12 : 14,
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            SizedBox(height: _safeSpacing(context)),
                            
                            // Footer Text
                            Text(
                              'Version 1.0.0 • © 2024 Gene\'s Lechon',
                              style: TextStyle(
                                fontSize: isTablet ? 10 : 12,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileUI(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final inputBgColor = isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final cardBgColor = isDarkMode ? Colors.grey.shade800 : Colors.white;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade800,
              Colors.deepOrange.shade400,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(_safeSpacing(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Section
                        SizedBox(height: _safeLargeSpacing(context) * 2),
                        
                        Container(
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: _safeSpacing(context)),
                              
                              const Text(
                                "Gene's Lechon",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: _safeSmallSpacing(context)),
                              
                              const Text(
                                "Secure Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: _safeLargeSpacing(context) * 2),
                        
                        // Login Card
                        Card(
                          elevation: 8,
                          color: cardBgColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(_safeLargeSpacing(context)),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    "Welcome Back",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  
                                  SizedBox(height: _safeSmallSpacing(context)),
                                  
                                  Text(
                                    "Please sign in to continue",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subtitleColor,
                                    ),
                                  ),
                                  
                                  SizedBox(height: _safeLargeSpacing(context)),
                                  
                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: const TextStyle(color: Colors.deepOrange),
                                      prefixIcon: const Icon(Icons.email, color: Colors.deepOrange),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: inputBgColor,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  SizedBox(height: _safeSpacing(context)),
                                  
                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: textColor,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: const TextStyle(color: Colors.deepOrange),
                                      prefixIcon: const Icon(Icons.lock, color: Colors.deepOrange),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.deepOrange,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: inputBgColor,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  SizedBox(height: _safeSpacing(context)),
                                  
                                  // Remember Me Row
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        activeColor: Colors.deepOrange,
                                        checkColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Need help?',
                                          style: TextStyle(
                                            color: Colors.deepOrange,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  SizedBox(height: _safeLargeSpacing(context) * 1.5),
                                  
                                  // Login Button
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: const Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Footer Section
                        SizedBox(height: _safeLargeSpacing(context) * 2),
                        
                        Container(
                          padding: EdgeInsets.all(_safeSpacing(context)),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.security,
                                size: 16,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              SizedBox(width: _safeSmallSpacing(context)),
                              Text(
                                'Secure Login System',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: _safeSpacing(context)),
                        
                        Text(
                          'For assistance, contact: admin@geneslechon.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: _safeSpacing(context)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if mobile, otherwise show desktop/tablet layout
    if (Responsive.isMobile(context)) {
      return _buildMobileUI(context);
    } else {
      return _buildDesktopTabletUI(context);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}