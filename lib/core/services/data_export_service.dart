import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'logger_service.dart';

/// GDPR/CCPA compliance - Data export service
/// Allows users to export all their personal data
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Export all user data to JSON format (GDPR Article 20 - Right to Data Portability)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      logger.info('Starting data export for user: $userId');

      final exportData = <String, dynamic>{
        'export_date': DateTime.now().toIso8601String(),
        'user_id': userId,
        'format_version': '1.0',
      };

      // 1. Export user profile data
      exportData['profile'] = await _exportProfile(userId);

      // 2. Export matches
      exportData['matches'] = await _exportMatches(userId);

      // 3. Export likes sent
      exportData['likes_sent'] = await _exportLikesSent(userId);

      // 4. Export likes received
      exportData['likes_received'] = await _exportLikesReceived(userId);

      // 5. Export messages
      exportData['messages'] = await _exportMessages(userId);

      // 6. Export reports (if user has reported anyone)
      exportData['reports_made'] = await _exportReportsMade(userId);

      // 7. Export subscriptions
      exportData['subscriptions'] = await _exportSubscriptions(userId);

      // 8. Export usage data
      exportData['usage_data'] = await _exportUsageData(userId);

      // 9. Export verification data
      exportData['verification'] = await _exportVerificationData(userId);

      // 10. Export gifts
      exportData['gifts'] = await _exportGifts(userId);

      // 11. Export blocks
      exportData['blocked_users'] = await _exportBlockedUsers(userId);

      logger.info('Data export completed for user: $userId');

      // Log export request for audit trail
      await _logExportRequest(userId);

      return exportData;
    } catch (e) {
      logger.error('Failed to export user data', error: e);
      rethrow;
    }
  }

  /// Export user data and save to file
  Future<File> exportUserDataToFile(String userId) async {
    try {
      final data = await exportUserData(userId);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/user_data_export_$userId.json');
      await file.writeAsString(jsonString);

      logger.info('User data exported to file: ${file.path}');
      return file;
    } catch (e) {
      logger.error('Failed to export user data to file', error: e);
      rethrow;
    }
  }

  /// Export user data and upload to Firebase Storage (for download via link)
  Future<String> exportUserDataToStorage(String userId) async {
    try {
      final file = await exportUserDataToFile(userId);

      // Upload to Firebase Storage
      final ref = _storage.ref().child('data_exports/$userId/${DateTime.now().millisecondsSinceEpoch}.json');
      await ref.putFile(file);

      // Generate download URL (valid for 7 days)
      final downloadUrl = await ref.getDownloadURL();

      // Store export record in Firestore
      await _firestore.collection('data_exports').add({
        'user_id': userId,
        'export_date': FieldValue.serverTimestamp(),
        'download_url': downloadUrl,
        'expires_at': DateTime.now().add(const Duration(days: 7)),
        'file_size': await file.length(),
      });

      logger.info('User data exported to storage with URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.error('Failed to export user data to storage', error: e);
      rethrow;
    }
  }

  // Private export methods for each data category

  Future<Map<String, dynamic>> _exportProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return {};

    final data = doc.data()!;
    // Remove sensitive fields that shouldn't be exported
    data.remove('fcm_token');
    data.remove('device_info');

    return data;
  }

  Future<List<Map<String, dynamic>>> _exportMatches(String userId) async {
    final matches = await _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .get();

    return matches.docs.map((doc) => {
      ...doc.data(),
      'match_id': doc.id,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _exportLikesSent(String userId) async {
    final likes = await _firestore
        .collection('likes')
        .where('likerId', isEqualTo: userId)
        .get();

    return likes.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportLikesReceived(String userId) async {
    final likes = await _firestore
        .collection('likes')
        .where('likedUserId', isEqualTo: userId)
        .get();

    return likes.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportMessages(String userId) async {
    // Export messages from all conversations
    final conversations = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    final allMessages = <Map<String, dynamic>>[];

    for (final conv in conversations.docs) {
      final messages = await conv.reference.collection('messages').get();

      for (final msg in messages.docs) {
        allMessages.add({
          ...msg.data(),
          'conversation_id': conv.id,
          'message_id': msg.id,
        });
      }
    }

    return allMessages;
  }

  Future<List<Map<String, dynamic>>> _exportReportsMade(String userId) async {
    final reports = await _firestore
        .collection('reports')
        .where('reporter_id', isEqualTo: userId)
        .get();

    return reports.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _exportSubscriptions(String userId) async {
    final subscriptions = await _firestore
        .collection('subscriptions')
        .where('user_id', isEqualTo: userId)
        .get();

    return subscriptions.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, dynamic>> _exportUsageData(String userId) async {
    final usageDoc = await _firestore
        .collection('usage_tracking')
        .doc(userId)
        .get();

    return usageDoc.data() ?? {};
  }

  Future<Map<String, dynamic>> _exportVerificationData(String userId) async {
    final verificationDoc = await _firestore
        .collection('verifications')
        .doc(userId)
        .get();

    if (!verificationDoc.exists) return {};

    final data = verificationDoc.data()!;
    // Remove verification images for privacy (just include status)
    data.remove('selfie_url');
    data.remove('id_photo_url');

    return data;
  }

  Future<List<Map<String, dynamic>>> _exportGifts(String userId) async {
    final giftsSent = await _firestore
        .collection('gifts')
        .where('sender_id', isEqualTo: userId)
        .get();

    final giftsReceived = await _firestore
        .collection('gifts')
        .where('receiver_id', isEqualTo: userId)
        .get();

    return [
      ...giftsSent.docs.map((doc) => {...doc.data(), 'type': 'sent'}),
      ...giftsReceived.docs.map((doc) => {...doc.data(), 'type': 'received'}),
    ];
  }

  Future<List<String>> _exportBlockedUsers(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();

    if (data == null) return [];

    final blocked = data['blockedUsers'] as List<dynamic>? ?? [];
    return blocked.map((id) => id.toString()).toList();
  }

  Future<void> _logExportRequest(String userId) async {
    await _firestore.collection('data_export_requests').add({
      'user_id': userId,
      'request_date': FieldValue.serverTimestamp(),
      'ip_address': 'not_tracked', // Add IP tracking if needed
      'status': 'completed',
    });
  }

  /// Get user's export history
  Future<List<Map<String, dynamic>>> getExportHistory(String userId) async {
    try {
      final exports = await _firestore
          .collection('data_exports')
          .where('user_id', isEqualTo: userId)
          .orderBy('export_date', descending: true)
          .limit(10)
          .get();

      return exports.docs.map((doc) => {
        ...doc.data(),
        'export_id': doc.id,
      }).toList();
    } catch (e) {
      logger.error('Failed to get export history', error: e);
      return [];
    }
  }

  /// Delete old export files (cleanup)
  Future<void> cleanupOldExports() async {
    try {
      final now = DateTime.now();
      final exports = await _firestore
          .collection('data_exports')
          .where('expires_at', isLessThan: now)
          .get();

      for (final doc in exports.docs) {
        final data = doc.data();
        final userId = data['user_id'] as String;

        // Delete from storage
        try {
          final ref = _storage.ref().child('data_exports/$userId/');
          await ref.delete();
        } catch (e) {
          logger.warning('Failed to delete export file from storage', error: e);
        }

        // Delete from Firestore
        await doc.reference.delete();
      }

      logger.info('Cleaned up ${exports.docs.length} old export files');
    } catch (e) {
      logger.error('Failed to cleanup old exports', error: e);
    }
  }

  /// Generate privacy report (summary of data we have)
  Future<Map<String, dynamic>> generatePrivacyReport(String userId) async {
    try {
      final profile = await _exportProfile(userId);
      final matches = await _exportMatches(userId);
      final messages = await _exportMessages(userId);

      return {
        'user_id': userId,
        'report_date': DateTime.now().toIso8601String(),
        'summary': {
          'profile_complete': profile.isNotEmpty,
          'total_matches': matches.length,
          'total_messages': messages.length,
          'account_age_days': _calculateAccountAge(profile),
          'verification_status': profile['verificationStatus'] ?? 'unverified',
          'subscription_status': profile['subscriptionTier'] ?? 'free',
        },
        'data_categories': {
          'profile_data': true,
          'messages': messages.isNotEmpty,
          'matches': matches.isNotEmpty,
          'usage_analytics': true,
        },
        'rights': {
          'right_to_access': 'You can export all your data',
          'right_to_erasure': 'You can delete your account at any time',
          'right_to_rectification': 'You can edit your profile information',
          'right_to_portability': 'You can download your data in JSON format',
          'right_to_object': 'You can opt-out of data processing',
        },
      };
    } catch (e) {
      logger.error('Failed to generate privacy report', error: e);
      rethrow;
    }
  }

  int _calculateAccountAge(Map<String, dynamic> profile) {
    final createdAt = profile['createdAt'] as Timestamp?;
    if (createdAt == null) return 0;

    final now = DateTime.now();
    final created = createdAt.toDate();
    return now.difference(created).inDays;
  }
}

// Global data export instance
final dataExport = DataExportService();
