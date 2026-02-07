// lib/services/user_service.dart - UPDATED VERSION
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../firebase/firebase_config.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'firebase_auth_service.dart';

class UserService {
  static final CollectionReference<Map<String, dynamic>> _usersCollection =
      FirebaseConfig.usersCollection;
  // ignore: unused_field
  static final firebase_auth.FirebaseAuth _firebaseAuth = FirebaseConfig.auth;

  // Safe helper to convert dynamic firestore data to DateTime
  static DateTime _convertToDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static User _documentToUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return User(
      id: doc.id,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.clerk,
      ),
      isActive: data['isActive'] ?? true,
      
      // Use the helper for robust conversion
      createdAt: _convertToDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null 
          ? _convertToDateTime(data['updatedAt']) 
          : null,
          
      phone: data['phone'],
      address: data['address'],
    );
  }

  // Convert User model to Firebase document
  // ignore: unused_element
  static Map<String, dynamic> _userToMap(User user) {
    return {
      'username': user.username,
      'password': AuthService.hashPassword(user.password),
      'fullName': user.fullName,
      'email': user.email.toLowerCase(),
      'role': user.role.name,
      'isActive': user.isActive,
      'createdAt': Timestamp.fromDate(user.createdAt),
      'updatedAt': user.updatedAt != null
          ? Timestamp.fromDate(user.updatedAt!) 
          : FieldValue.serverTimestamp(),
      'phone': user.phone,
      'address': user.address,
    };
  }

  // Get all users
  static Future<List<User>> getUsers() async {
    try {
      final querySnapshot = await _usersCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) => _documentToUser(doc)).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  // Get user by ID
  static Future<User?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return _documentToUser(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Get user by email
  static Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return _documentToUser(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Create new user with Firebase Authentication
  static Future<Map<String, dynamic>> createUser(User user) async {
    try {
      // Check if user already exists
      final existingUser = await getUserByEmail(user.email);
      if (existingUser != null) {
        return {'error': 'User with this email already exists'};
      }

      // Create Firebase Auth user first
      try {
        final authResult = await FirebaseAuthService.createFirebaseUser(
          user.email,
          user.password,
          user.toFirestore(),
        );

        if (authResult['success'] == true) {
          return {
            'success': true,
            'userId': authResult['userId'],
            'user': user.copyWith(id: authResult['userId']),
          };
        } else {
          return {'error': authResult['message'] ?? 'Failed to create user in Firebase Auth'};
        }
      } on Exception catch (e) {
        return {'error': 'Firebase Auth error: ${e.toString()}'};
      }
    } catch (e) {
      print('Error creating user: $e');
      return {'error': 'Failed to create user: ${e.toString()}'};
    }
  }

  // Update existing user
  static Future<Map<String, dynamic>> updateUser(User user) async {
    try {
      final Map<String, dynamic> updateData = {
        'username': user.username,
        'fullName': user.fullName,
        'email': user.email.toLowerCase(),
        'role': user.role.name,
        'isActive': user.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'phone': user.phone,
        'address': user.address,
      };
      
      // Only update password if provided
      if (user.password.isNotEmpty) {
        updateData['password'] = AuthService.hashPassword(user.password);
      }
      
      await _usersCollection.doc(user.id).update(updateData);
      return {'success': true};
    } catch (e) {
      print('Error updating user: $e');
      return {'error': 'Failed to update user: ${e.toString()}'};
    }
  }

  // Delete user
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      return {'success': true};
    } catch (e) {
      print('Error deleting user: $e');
      return {'error': 'Failed to delete user: ${e.toString()}'};
    }
  }

  // Toggle user active status
  static Future<Map<String, dynamic>> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _usersCollection.doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return {'success': true};
    } catch (e) {
      print('Error toggling user status: $e');
      return {'error': 'Failed to update user status: ${e.toString()}'};
    }
  }

  // Search users
  static Future<List<User>> searchUsers(String query) async {
    try {
      final allUsers = await getUsers();
      if (query.isEmpty) return allUsers;
      
      final lowercaseQuery = query.toLowerCase();
      return allUsers.where((user) {
        return user.username.toLowerCase().contains(lowercaseQuery) ||
               user.fullName.toLowerCase().contains(lowercaseQuery) ||
               user.email.toLowerCase().contains(lowercaseQuery) ||
               user.roleDisplayName.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Stream users for real-time updates
  static Stream<List<User>> streamUsers() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _documentToUser(doc))
            .toList());
  }

  // Stream single user for real-time updates
  static Stream<User?> streamUser(String userId) {
    return _usersCollection
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? _documentToUser(doc) : null);
  }

  // Get user count
  static Future<int> getUserCount() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting user count: $e');
      return 0;
    }
  }
}