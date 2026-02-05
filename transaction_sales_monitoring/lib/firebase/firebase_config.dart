// lib/firebase/firebase_config.dart - UPDATED VERSION
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static bool _initialized = false;
  static FirebaseApp? _firebaseApp;

  static Future<void> initialize() async {
    try {
      if (!_initialized) {
        // Initialize Firebase with web options
        _firebaseApp = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _initialized = true;
        print('Firebase initialized successfully: ${_firebaseApp?.name}');
      }
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
  
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  static FirebaseStorage get storage => FirebaseStorage.instance;
  
  static bool get isInitialized => _initialized;
  
  static CollectionReference<Map<String, dynamic>> get usersCollection {
    return firestore.collection('users');
  }
  
  static Future<void> signOut() async {
    await auth.signOut();
  }
}