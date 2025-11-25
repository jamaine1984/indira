import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Centralized Firebase configuration
/// Provides access to the nam5 database instance
class FirebaseConfig {
  static FirebaseFirestore get firestore {
    return FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'nam5',
    );
  }
}
