// lib/services/database_init_service.dart - NEW FILE
import '../firebase/firebase_config.dart';

class DatabaseInitService {
  // Initialize database with default data
  static Future<void> initializeDatabase() async {
    try {
      print('Initializing database...');
      
      print('Database initialization complete');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }

  // Clear all data (for testing only)
  static Future<void> clearAllData() async {
    try {
      final collections = ['products', 'categories', 'inventory', 'transactions'];
      
      for (final collectionName in collections) {
        final snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .get();
        
        final batch = FirebaseConfig.firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
      
      print('All data cleared');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Export database backup
  static Future<Map<String, dynamic>> exportBackup() async {
    try {
      final collections = ['products', 'categories', 'inventory', 'transactions', 'users'];
      final backup = <String, dynamic>{
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {},
      };

      for (final collectionName in collections) {
        final snapshot = await FirebaseConfig.firestore
            .collection(collectionName)
            .get();
        
        backup['data'][collectionName] = snapshot.docs
            .map((doc) => doc.data())
            .toList();
      }

      return backup;
    } catch (e) {
      print('Error exporting backup: $e');
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'data': {},
        'error': e.toString(),
      };
    }
  }
}