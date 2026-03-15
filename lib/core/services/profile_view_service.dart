import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Service to track profile views ("Who Viewed You" feature).
/// When a user views another user's profile, a record is created.
/// Free/Silver users see blurred profiles (unlock with 1 ad).
/// Gold users see all viewers unblurred.
class ProfileViewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Record a profile view when current user views another profile
  Future<void> recordProfileView(String viewedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    if (currentUser.uid == viewedUserId) return; // Don't track self-views

    try {
      // Use a deterministic ID to prevent duplicate views per day
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final viewId = '${currentUser.uid}_${viewedUserId}_$dateKey';

      await _firestore.collection('profile_views').doc(viewId).set({
        'viewerId': currentUser.uid,
        'viewedUserId': viewedUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'dateKey': dateKey,
        'isRevealed': false,
      }, SetOptions(merge: true)); // merge to not overwrite isRevealed if already set
    } catch (e) {
      logger.error('Error recording profile view: $e');
    }
  }

  /// Get stream of users who viewed the current user's profile
  Stream<List<Map<String, dynamic>>> getProfileViewers(String userId) {
    return _firestore
        .collection('profile_views')
        .where('viewedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'viewerId': data['viewerId'] ?? '',
                'timestamp': data['timestamp'],
                'isRevealed': data['isRevealed'] ?? false,
              };
            }).toList());
  }

  /// Get count of unrevealed profile viewers
  Future<int> getUnrevealedViewsCount(String userId) async {
    final snapshot = await _firestore
        .collection('profile_views')
        .where('viewedUserId', isEqualTo: userId)
        .where('isRevealed', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Reveal a profile viewer (after watching ad or with Gold subscription)
  Future<void> revealViewer(String viewId) async {
    await _firestore.collection('profile_views').doc(viewId).update({
      'isRevealed': true,
      'revealedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if user has Gold subscription (unlimited reveals)
  Future<bool> canRevealWithoutAds(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final tier = userDoc.data()?['subscriptionTier'] as String? ?? 'free';
    return tier == 'gold';
  }
}
