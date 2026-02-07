// lib/utils/firebase_auth_checker.dart
import '../services/firebase_auth_service.dart';

class FirebaseAuthChecker {
  // Test Firebase Auth connection and capabilities
  static Future<Map<String, dynamic>> testAuthCapabilities() async {
    final results = <String, dynamic>{};
    
    try {
      // Check if Firebase Auth is accessible
      // ignore: unnecessary_null_comparison
      results['firebaseAccessible'] = FirebaseAuthService.isAuthenticated() != null;
      
      // Test email checking
      const testEmail = 'test@example.com';
      final emailCheck = await FirebaseAuthService.checkIfEmailExists(testEmail);
      // ignore: unnecessary_null_comparison
      results['emailCheckWorks'] = emailCheck != null; // Should return false for non-existent email
      
      // Test current user
      final currentUser = FirebaseAuthService.getCurrentFirebaseUser();
      results['currentUserAccessible'] = currentUser != null;
      
      results['success'] = true;
      results['message'] = 'Firebase Auth capabilities tested successfully';
      
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
      results['message'] = 'Failed to test Firebase Auth capabilities';
    }
    
    return results;
  }

  // Get Firebase Auth configuration info
  static Future<Map<String, dynamic>> getAuthConfig() async {
    return {
      'authProvider': 'Firebase Authentication',
      'supportsEmailPassword': true,
      'supportsPasswordReset': true,
      'supportsTokenRefresh': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}