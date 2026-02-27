import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

class EndorsementService {
  static final EndorsementService _instance = EndorsementService._();
  factory EndorsementService() => _instance;
  EndorsementService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Categories for endorsements
  static const List<Map<String, String>> categories = [
    {'id': 'genuine', 'label': 'Genuine Person', 'emoji': '\u{2705}'},
    {'id': 'funny', 'label': 'Great Sense of Humor', 'emoji': '\u{1F602}'},
    {'id': 'kind', 'label': 'Kind & Caring', 'emoji': '\u{1F49B}'},
    {'id': 'respectful', 'label': 'Respectful', 'emoji': '\u{1F64F}'},
    {'id': 'good_conversationalist', 'label': 'Good Conversationalist', 'emoji': '\u{1F4AC}'},
    {'id': 'photos_accurate', 'label': 'Photos Are Accurate', 'emoji': '\u{1F4F8}'},
    {'id': 'family_oriented', 'label': 'Family Oriented', 'emoji': '\u{1F46A}'},
    {'id': 'ambitious', 'label': 'Ambitious & Driven', 'emoji': '\u{1F680}'},
  ];

  /// Submit an endorsement for a user
  Future<void> submitEndorsement({
    required String toUserId,
    required String categoryId,
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (user.uid == toUserId) throw Exception('Cannot endorse yourself');

    // Check for duplicate
    final existing = await _firestore
        .collection('endorsements')
        .where('fromUserId', isEqualTo: user.uid)
        .where('toUserId', isEqualTo: toUserId)
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You already endorsed this person for this category');
    }

    await _firestore.collection('endorsements').add({
      'fromUserId': user.uid,
      'toUserId': toUserId,
      'categoryId': categoryId,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update the user's endorsement count on their profile
    await _updateEndorsementCounts(toUserId);

    logger.info('Endorsement submitted for $toUserId: $categoryId');
  }

  /// Get endorsements for a specific user
  Future<List<Map<String, dynamic>>> getEndorsements(String userId) async {
    try {
      final snap = await _firestore
          .collection('endorsements')
          .where('toUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      logger.error('Error getting endorsements: $e');
      return [];
    }
  }

  /// Get aggregated endorsement counts by category for a user
  Future<Map<String, int>> getEndorsementCounts(String userId) async {
    final endorsements = await getEndorsements(userId);
    final counts = <String, int>{};
    for (final e in endorsements) {
      final cat = e['categoryId'] as String? ?? '';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts;
  }

  /// Update endorsement summary on user document
  Future<void> _updateEndorsementCounts(String userId) async {
    final counts = await getEndorsementCounts(userId);
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    await _firestore.collection('users').doc(userId).update({
      'endorsements': {
        'counts': counts,
        'total': total,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Check if current user has already endorsed a specific category
  Future<bool> hasEndorsed(String toUserId, String categoryId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snap = await _firestore
        .collection('endorsements')
        .where('fromUserId', isEqualTo: user.uid)
        .where('toUserId', isEqualTo: toUserId)
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }
}
