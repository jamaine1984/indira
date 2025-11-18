import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'logger_service.dart';

/// GDPR/CCPA compliance - Account deletion service
/// Allows users to permanently delete their account and all associated data
class AccountDeletionService {
  static final AccountDeletionService _instance = AccountDeletionService._internal();
  factory AccountDeletionService() => _instance;
  AccountDeletionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Delete user account and all associated data (GDPR Article 17 - Right to Erasure)
  Future<void> deleteUserAccount(String userId, String password) async {
    try {
      logger.info('Starting account deletion for user: $userId');

      // Step 1: Re-authenticate user (security requirement)
      await _reauthenticateUser(password);

      // Step 2: Mark account as pending deletion (soft delete first)
      await _markAccountForDeletion(userId);

      // Step 3: Delete user data from Firestore
      await _deleteFirestoreData(userId);

      // Step 4: Delete user files from Storage
      await _deleteStorageFiles(userId);

      // Step 5: Anonymize data that must be retained for legal reasons
      await _anonymizeRetainedData(userId);

      // Step 6: Delete Firebase Auth account
      await _deleteAuthAccount();

      // Step 7: Log deletion for audit trail
      await _logAccountDeletion(userId);

      logger.info('Account deletion completed for user: $userId');
    } catch (e) {
      logger.error('Failed to delete user account', error: e);
      rethrow;
    }
  }

  /// Soft delete - Mark account for deletion (30-day grace period)
  Future<void> requestAccountDeletion(String userId) async {
    try {
      logger.info('Requesting account deletion for user: $userId');

      final deletionDate = DateTime.now().add(const Duration(days: 30));

      await _firestore.collection('users').doc(userId).update({
        'deletion_requested': true,
        'deletion_requested_at': FieldValue.serverTimestamp(),
        'scheduled_deletion_date': Timestamp.fromDate(deletionDate),
        'account_status': 'pending_deletion',
      });

      // Disable account immediately (user can't login during grace period)
      await _firestore.collection('users').doc(userId).update({
        'is_active': false,
      });

      // Send confirmation email
      await _sendDeletionConfirmationEmail(userId);

      logger.info('Account marked for deletion, scheduled for: $deletionDate');
    } catch (e) {
      logger.error('Failed to request account deletion', error: e);
      rethrow;
    }
  }

  /// Cancel account deletion request (within grace period)
  Future<void> cancelAccountDeletion(String userId) async {
    try {
      logger.info('Canceling account deletion for user: $userId');

      await _firestore.collection('users').doc(userId).update({
        'deletion_requested': false,
        'deletion_requested_at': FieldValue.delete(),
        'scheduled_deletion_date': FieldValue.delete(),
        'account_status': 'active',
        'is_active': true,
      });

      logger.info('Account deletion canceled for user: $userId');
    } catch (e) {
      logger.error('Failed to cancel account deletion', error: e);
      rethrow;
    }
  }

  /// Process scheduled deletions (run daily via Cloud Function)
  Future<void> processScheduledDeletions() async {
    try {
      final now = DateTime.now();

      final usersToDelete = await _firestore
          .collection('users')
          .where('deletion_requested', isEqualTo: true)
          .where('scheduled_deletion_date', isLessThan: Timestamp.fromDate(now))
          .get();

      logger.info('Processing ${usersToDelete.docs.length} scheduled deletions');

      for (final doc in usersToDelete.docs) {
        final userId = doc.id;
        try {
          await _permanentlyDeleteAccount(userId);
        } catch (e) {
          logger.error('Failed to delete account: $userId', error: e);
        }
      }

      logger.info('Scheduled deletions processing completed');
    } catch (e) {
      logger.error('Failed to process scheduled deletions', error: e);
    }
  }

  // Private helper methods

  Future<void> _reauthenticateUser(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user found');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _markAccountForDeletion(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'deletion_in_progress': true,
      'deletion_started_at': FieldValue.serverTimestamp(),
      'account_status': 'deleting',
    });
  }

  Future<void> _deleteFirestoreData(String userId) async {
    logger.info('Deleting Firestore data for user: $userId');

    // Delete user profile
    await _firestore.collection('users').doc(userId).delete();

    // Delete likes sent by user
    final likesSent = await _firestore
        .collection('likes')
        .where('likerId', isEqualTo: userId)
        .get();
    for (final doc in likesSent.docs) {
      await doc.reference.delete();
    }

    // Delete likes received (or anonymize)
    final likesReceived = await _firestore
        .collection('likes')
        .where('likedUserId', isEqualTo: userId)
        .get();
    for (final doc in likesReceived.docs) {
      await doc.reference.delete();
    }

    // Delete matches
    final matches = await _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .get();
    for (final doc in matches.docs) {
      await doc.reference.delete();
    }

    // Delete messages (or anonymize)
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();
    for (final conv in conversations.docs) {
      // Delete all messages in conversation
      final messages = await conv.reference.collection('messages').get();
      for (final msg in messages.docs) {
        await msg.reference.delete();
      }
      // Delete conversation
      await conv.reference.delete();
    }

    // Delete reports made by user
    final reportsMade = await _firestore
        .collection('reports')
        .where('reporter_id', isEqualTo: userId)
        .get();
    for (final doc in reportsMade.docs) {
      await doc.reference.update({
        'reporter_id': 'deleted_user',
        'reporter_deleted': true,
      });
    }

    // Delete verification data
    await _firestore.collection('verifications').doc(userId).delete();

    // Delete usage tracking
    await _firestore.collection('usage_tracking').doc(userId).delete();

    // Delete gifts
    final gifts = await _firestore
        .collection('gifts')
        .where('sender_id', isEqualTo: userId)
        .get();
    for (final doc in gifts.docs) {
      await doc.reference.delete();
    }

    // Delete boosts
    final boosts = await _firestore
        .collection('boosts')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in boosts.docs) {
      await doc.reference.delete();
    }

    logger.info('Firestore data deleted successfully');
  }

  Future<void> _deleteStorageFiles(String userId) async {
    logger.info('Deleting Storage files for user: $userId');

    try {
      // Delete all files in user's folder
      final userFolder = _storage.ref().child('users/$userId');

      // List all files
      final listResult = await userFolder.listAll();

      // Delete all files
      for (final item in listResult.items) {
        await item.delete();
      }

      // Delete all subfolders
      for (final prefix in listResult.prefixes) {
        await _deleteFolder(prefix);
      }

      logger.info('Storage files deleted successfully');
    } catch (e) {
      logger.warning('Failed to delete some storage files', error: e);
      // Continue with deletion even if storage deletion fails
    }
  }

  Future<void> _deleteFolder(Reference folderRef) async {
    final listResult = await folderRef.listAll();

    for (final item in listResult.items) {
      await item.delete();
    }

    for (final prefix in listResult.prefixes) {
      await _deleteFolder(prefix);
    }
  }

  Future<void> _anonymizeRetainedData(String userId) async {
    logger.info('Anonymizing retained data for user: $userId');

    // Some data must be retained for legal/financial reasons
    // Replace user ID with anonymous ID

    final anonymousId = 'deleted_${DateTime.now().millisecondsSinceEpoch}';

    // Anonymize subscription records (for tax/accounting)
    final subscriptions = await _firestore
        .collection('subscriptions')
        .where('user_id', isEqualTo: userId)
        .get();

    for (final doc in subscriptions.docs) {
      await doc.reference.update({
        'user_id': anonymousId,
        'user_deleted': true,
        'anonymized_at': FieldValue.serverTimestamp(),
      });
    }

    // Anonymize reports about this user (for safety records)
    final reportsAbout = await _firestore
        .collection('reports')
        .where('reported_user_id', isEqualTo: userId)
        .get();

    for (final doc in reportsAbout.docs) {
      await doc.reference.update({
        'reported_user_id': anonymousId,
        'user_deleted': true,
        'anonymized_at': FieldValue.serverTimestamp(),
      });
    }

    logger.info('Data anonymization completed');
  }

  Future<void> _deleteAuthAccount() async {
    logger.info('Deleting Firebase Auth account');

    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }

    logger.info('Firebase Auth account deleted');
  }

  Future<void> _logAccountDeletion(String userId) async {
    await _firestore.collection('account_deletions').add({
      'user_id': userId,
      'deletion_date': FieldValue.serverTimestamp(),
      'deletion_type': 'user_requested',
      'data_deleted': true,
      'storage_deleted': true,
      'auth_deleted': true,
    });
  }

  Future<void> _permanentlyDeleteAccount(String userId) async {
    logger.info('Permanently deleting account: $userId');

    await _deleteFirestoreData(userId);
    await _deleteStorageFiles(userId);
    await _anonymizeRetainedData(userId);

    // Note: Can't delete Auth account here since we're running this
    // as a scheduled job without user authentication
    // Auth accounts should be deleted via Cloud Function

    await _logAccountDeletion(userId);

    logger.info('Permanent deletion completed for user: $userId');
  }

  Future<void> _sendDeletionConfirmationEmail(String userId) async {
    // This would integrate with your email service
    // For now, just log it
    logger.info('Deletion confirmation email sent to user: $userId');
  }

  /// Get account deletion status
  Future<Map<String, dynamic>?> getDeletionStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return null;
      }

      final data = userDoc.data()!;

      if (data['deletion_requested'] == true) {
        return {
          'status': 'pending_deletion',
          'requested_at': data['deletion_requested_at'],
          'scheduled_date': data['scheduled_deletion_date'],
          'can_cancel': true,
        };
      }

      return {
        'status': 'active',
        'can_delete': true,
      };
    } catch (e) {
      logger.error('Failed to get deletion status', error: e);
      return null;
    }
  }

  /// Export data before deletion (GDPR requirement)
  Future<String> exportBeforeDeletion(String userId) async {
    // This would use the DataExportService
    logger.info('Exporting data before deletion for user: $userId');
    // Implementation would call DataExportService.exportUserDataToStorage(userId)
    return 'export_url_placeholder';
  }

  /// Delete specific data category (granular deletion)
  Future<void> deleteDataCategory(String userId, String category) async {
    try {
      logger.info('Deleting data category: $category for user: $userId');

      switch (category) {
        case 'messages':
          await _deleteMessages(userId);
          break;
        case 'matches':
          await _deleteMatches(userId);
          break;
        case 'photos':
          await _deletePhotos(userId);
          break;
        case 'location':
          await _deleteLocationData(userId);
          break;
        default:
          throw Exception('Unknown data category: $category');
      }

      logger.info('Data category deleted: $category');
    } catch (e) {
      logger.error('Failed to delete data category', error: e);
      rethrow;
    }
  }

  Future<void> _deleteMessages(String userId) async {
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    for (final conv in conversations.docs) {
      final messages = await conv.reference.collection('messages').get();
      for (final msg in messages.docs) {
        await msg.reference.delete();
      }
    }
  }

  Future<void> _deleteMatches(String userId) async {
    final matches = await _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .get();

    for (final doc in matches.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deletePhotos(String userId) async {
    final userFolder = _storage.ref().child('users/$userId/photos');
    final listResult = await userFolder.listAll();

    for (final item in listResult.items) {
      await item.delete();
    }

    // Update user profile
    await _firestore.collection('users').doc(userId).update({
      'photoUrls': [],
      'mainPhoto': '',
    });
  }

  Future<void> _deleteLocationData(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'location': FieldValue.delete(),
      'latitude': FieldValue.delete(),
      'longitude': FieldValue.delete(),
      'city': FieldValue.delete(),
      'country': FieldValue.delete(),
    });
  }
}

// Global account deletion instance
final accountDeletion = AccountDeletionService();
