// lib/services/firebase_auth_service.dart - UPDATED VERSION
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firebase_config.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;
  static final firebase_auth.FirebaseAuth _auth = FirebaseConfig.auth;

  // Sign in with email and password
  static Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      // First, try Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        final userDoc = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data();
          final user = User.fromFirestore(userData, userDoc.docs.first.id);
          
          // Check if user is active
          if (!user.isActive) {
            await _auth.signOut();
            return {
              'success': false,
              'message': 'Account is deactivated. Contact administrator.',
            };
          }

          return {
            'success': true,
            'user': user,
            'firebaseUser': userCredential.user,
          };
        } else {
          // User exists in Firebase Auth but not in Firestore
          return {
            'success': false,
            'message': 'User account not properly configured.',
          };
        }
      }

      return {
        'success': false,
        'message': 'Authentication failed.',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password sign-in is not enabled.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
      }

      return {
        'success': false,
        'message': errorMessage,
        'errorCode': e.code,
      };
    } catch (e) {
      print('Firebase sign-in error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current Firebase user
  static firebase_auth.User? getCurrentFirebaseUser() {
    return _auth.currentUser;
  }

  // Check if user is authenticated
  static bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  // Stream authentication state changes
  static Stream<firebase_auth.User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Send password reset email
  static Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email.';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send reset email.',
      };
    }
  }

  // Update user password
  static Future<Map<String, dynamic>> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'No user is currently signed in.',
        };
      }

      // Re-authenticate before changing password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return {
        'success': true,
        'message': 'Password updated successfully.',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to update password.';
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'New password is too weak.';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please sign in again to change your password.';
          break;
        case 'wrong-password':
          errorMessage = 'Current password is incorrect.';
          break;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update password.',
      };
    }
  }

  // Check if email exists in Firebase Auth - UPDATED METHOD
  static Future<bool> checkIfEmailExists(String email) async {
    try {
      // Try to create a user with the email to check if it exists
      // If it throws an error about email already in use, then it exists
      try {
        // Try to sign in with a dummy password to see if the user exists
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: 'dummyPassword123!@#', // Dummy password that will fail
        );
        // If this succeeds, the user exists but password is wrong
        return true;
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          return false; // User doesn't exist
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          return true; // User exists (wrong password)
        } else {
          // Other errors - try alternative method
          return await _alternativeEmailCheck(email);
        }
      }
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // Alternative method to check email existence
  static Future<bool> _alternativeEmailCheck(String email) async {
    try {
      // Try to send password reset email - will fail if user doesn't exist
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true; // If no error, email likely exists
    } on firebase_auth.FirebaseAuthException catch (e) {
      return e.code != 'user-not-found'; // Return false only if user not found
    } catch (e) {
      return false;
    }
  }

  // Create new user in Firebase Auth
  static Future<Map<String, dynamic>> createFirebaseUser(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Check if email already exists
      final emailExists = await checkIfEmailExists(email);
      if (emailExists) {
        return {
          'success': false,
          'message': 'Email already registered.',
        };
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Create user document in Firestore
        final userDocRef = _firestore.collection('users').doc(userCredential.user!.uid);
        
        await userDocRef.set({
          ...userData,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'firebaseUid': userCredential.user!.uid,
        });

        return {
          'success': true,
          'userId': userCredential.user!.uid,
          'user': userCredential.user,
        };
      }

      return {
        'success': false,
        'message': 'Failed to create user.',
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to create account.';
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak.';
          break;
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print('Create user error: $e');
      return {
        'success': false,
        'message': 'Failed to create account.',
      };
    }
  }

  // Get user by Firebase UID
  static Future<User?> getUserByFirebaseUid(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return User.fromFirestore(userData, userDoc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user by Firebase UID: $e');
      return null;
    }
  }

  // Verify current user token (for session validation)
  static Future<bool> verifyCurrentUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await user.getIdToken(true); // Force token refresh
      return true;
    } catch (e) {
      print('Token verification error: $e');
      return false;
    }
  }

  // Get user authentication token
  static Future<String?> getUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final token = await user.getIdToken();
      return token;
    } catch (e) {
      print('Error getting user token: $e');
      return null;
    }
  }
}