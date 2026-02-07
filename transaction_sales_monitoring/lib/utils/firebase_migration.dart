// lib/utils/firebase_migration.dart - FIXED VERSION
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../firebase/firebase_config.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/firebase_auth_service.dart';

class FirebaseMigration {
  // Hash password for migration
  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Migrate existing users to Firebase Auth
  static Future<void> migrateUsersToFirebase() async {
    try {
      final users = await UserService.getUsers();
      print('Found ${users.length} users to migrate');
      
      int migratedCount = 0;
      int skippedCount = 0;
      
      for (final user in users) {
        try {
          // Check if user exists in Firebase Auth using the updated method
          final emailExists = await FirebaseAuthService.checkIfEmailExists(user.email);
          
          if (!emailExists) {
            print('Migrating user: ${user.email}');
            
            // Create user in Firebase Auth with the same password hash
            // Note: We need to use a temporary password since we can't get the original
            final tempPassword = 'TempPass${DateTime.now().millisecondsSinceEpoch}';
            
            await FirebaseAuthService.createFirebaseUser(
              user.email,
              tempPassword,
              user.toFirestore(),
            );
            
            migratedCount++;
            print('Successfully migrated ${user.email}');
          } else {
            print('User ${user.email} already exists in Firebase Auth');
            skippedCount++;
          }
        } catch (e) {
          print('Error migrating user ${user.email}: $e');
        }
      }
      
      print('Migration completed: $migratedCount migrated, $skippedCount skipped');
    } catch (e) {
      print('Migration error: $e');
    }
  }

  // Create default admin user if none exists
  static Future<void> createDefaultAdmin() async {
    List<User> users = []; // Declare users variable at the beginning
    
    try {
      users = await UserService.getUsers(); // Initialize users
      
      if (users.isEmpty) {
        print('Creating default admin user...');
        
        const defaultPassword = 'admin123';
        final hashedPassword = hashPassword(defaultPassword);
        
        final defaultUser = User(
          id: 'admin_001',
          username: 'admin',
          password: hashedPassword,
          fullName: 'System Administrator',
          email: 'admin@geneslechon.com',
          role: UserRole.admin,
          isActive: true,
          createdAt: DateTime.now(),
          phone: '+1234567890',
          address: 'Main Office',
        );
        
        // Create in Firebase Auth first
        final authResult = await FirebaseAuthService.createFirebaseUser(
          'admin@geneslechon.com',
          defaultPassword,
          defaultUser.toFirestore(),
        );
        
        if (authResult['success'] == true) {
          print('Default admin user created successfully in Firebase Auth');
        } else {
          print('Warning: Could not create admin in Firebase Auth: ${authResult['message']}');
          
          // Try to create just in Firestore as fallback
          await FirebaseConfig.usersCollection.doc('admin_001').set(
            defaultUser.toFirestore(),
          );
          print('Default admin user created in Firestore only');
        }
      } else {
        print('Users already exist, skipping default admin creation');
      }
    } catch (e) {
      print('Error creating default admin: $e');
      
      // Try alternative approach - re-fetch users if needed
      try {
        print('Trying alternative admin creation...');
        
        // If users list is empty, fetch again
        if (users.isEmpty) {
          users = await UserService.getUsers();
        }
        
        // Check if any admin exists
        final adminExists = users.any((user) => user.role == UserRole.admin);
        if (!adminExists) {
          print('Creating emergency admin...');
          
          final emergencyUser = User(
            id: 'emergency_admin_${DateTime.now().millisecondsSinceEpoch}',
            username: 'emergency_admin',
            password: hashPassword('emergency123'),
            fullName: 'Emergency Administrator',
            email: 'emergency@geneslechon.com',
            role: UserRole.admin,
            isActive: true,
            createdAt: DateTime.now(),
          );
          
          await FirebaseConfig.usersCollection.add(emergencyUser.toFirestore());
          print('Emergency admin created');
        }
      } catch (e2) {
        print('Emergency admin creation also failed: $e2');
      }
    }
  }

  // Verify and fix user data consistency
  static Future<void> verifyUserDataConsistency() async {
    try {
      print('Verifying user data consistency...');
      
      final firestoreUsers = await UserService.getUsers();
      final firebaseUsers = <String>[];
      
      // Get all Firebase Auth users (limited approach)
      // Note: Firebase doesn't provide a direct way to list all users
      // We'll check consistency by verifying each Firestore user
      
      for (final user in firestoreUsers) {
        final emailExists = await FirebaseAuthService.checkIfEmailExists(user.email);
        
        if (!emailExists) {
          print('Warning: User ${user.email} exists in Firestore but not in Firebase Auth');
          print('Consider migrating this user to Firebase Auth');
        }
      }
      
      print('User data consistency check completed');
    } catch (e) {
      print('Error verifying user data consistency: $e');
    }
  }

  // Backup user data before migration
  static Future<Map<String, dynamic>> backupUserData() async {
    try {
      final users = await UserService.getUsers();
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'userCount': users.length,
        'users': users.map((user) => user.toMap()).toList(),
      };
      
      // Convert to JSON string for storage
      final jsonString = jsonEncode(backupData);
      
      // Save to Firestore as backup
      await FirebaseConfig.firestore
          .collection('backups')
          .doc('user_backup_${DateTime.now().millisecondsSinceEpoch}')
          .set({
            'data': jsonString,
            'createdAt': DateTime.now().toIso8601String(),
            'type': 'user_backup',
          });
      
      print('User backup created with ${users.length} users');
      
      return {
        'success': true,
        'message': 'Backup created successfully',
        'userCount': users.length,
      };
    } catch (e) {
      print('Error creating backup: $e');
      return {
        'success': false,
        'message': 'Failed to create backup: $e',
      };
    }
  }

  // Simple admin creation without dependencies
  static Future<void> createSimpleAdmin() async {
    try {
      print('Creating simple admin user...');
      
      final adminUser = User(
        id: 'simple_admin_${DateTime.now().millisecondsSinceEpoch}',
        username: 'admin',
        password: hashPassword('admin123'),
        fullName: 'Simple Administrator',
        email: 'simple_admin@geneslechon.com',
        role: UserRole.admin,
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      await FirebaseConfig.usersCollection.add(adminUser.toFirestore());
      print('Simple admin user created successfully');
    } catch (e) {
      print('Failed to create simple admin: $e');
    }
  }
}