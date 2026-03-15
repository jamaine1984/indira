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

  /// Submit multiple endorsements for a user at once
  Future<void> submitEndorsements({
    required String toUserId,
    required List<String> categoryIds,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (user.uid == toUserId) throw Exception('Cannot endorse yourself');
    if (categoryIds.isEmpty) throw Exception('No endorsements selected');

    final batch = _firestore.batch();
    int addedCount = 0;

    for (final categoryId in categoryIds) {
      // Use deterministic doc ID to prevent duplicates without compound query
      final docId = '${user.uid}_${toUserId}_$categoryId';
      final existingDoc = await _firestore.collection('endorsements').doc(docId).get();

      if (!existingDoc.exists) {
        batch.set(_firestore.collection('endorsements').doc(docId), {
          'fromUserId': user.uid,
          'toUserId': toUserId,
          'categoryId': categoryId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        addedCount++;
      }
    }

    if (addedCount > 0) {
      await batch.commit();
    }
    logger.info('Endorsements submitted for $toUserId: $categoryIds ($addedCount new)');
  }

  /// Submit a single endorsement for a user
  Future<void> submitEndorsement({
    required String toUserId,
    required String categoryId,
    String? comment,
  }) async {
    await submitEndorsements(toUserId: toUserId, categoryIds: [categoryId]);
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

  /// Get the set of category IDs that have been endorsed by ANY user
  /// for the given profile. Used to grey out / blur already-taken endorsements.
  Future<Set<String>> getEndorsedCategoryIds(String toUserId) async {
    final endorsements = await getEndorsements(toUserId);
    return endorsements
        .map((e) => e['categoryId'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toSet();
  }

  /// Get the set of category IDs that the CURRENT user has already endorsed
  /// for the given profile. Uses deterministic doc IDs for efficient lookup.
  Future<Set<String>> getMyEndorsedCategoryIds(String toUserId) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final myEndorsed = <String>{};
    try {
      for (final cat in categories) {
        final docId = '${user.uid}_${toUserId}_${cat['id']}';
        final doc = await _firestore.collection('endorsements').doc(docId).get();
        if (doc.exists) {
          myEndorsed.add(cat['id']!);
        }
      }
      return myEndorsed;
    } catch (e) {
      logger.error('Error getting my endorsements: $e');
      return {};
    }
  }

  /// Check if current user has already endorsed a specific category
  Future<bool> hasEndorsed(String toUserId, String categoryId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final docId = '${user.uid}_${toUserId}_$categoryId';
    final doc = await _firestore.collection('endorsements').doc(docId).get();
    return doc.exists;
  }

}
