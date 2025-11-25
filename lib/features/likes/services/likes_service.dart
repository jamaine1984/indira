import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/features/likes/models/like_model.dart';

class LikesService {
  // Connect to the nam5 database instance where all users are stored
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all likes sent by current user
  Stream<List<LikeModel>> getLikesSent(String userId) {
    print('DEBUG LIKES SERVICE: Getting likes sent by user: $userId');
    return _firestore
        .collection('likes')
        .where('likerId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('DEBUG LIKES SERVICE: Found ${snapshot.docs.length} likes sent by user $userId');
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print('DEBUG LIKES SERVICE: Like doc ${doc.id}: likerId=${data['likerId']}, likedUserId=${data['likedUserId']}');
          }
          return snapshot.docs
              .map((doc) => LikeModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all likes received by current user (who liked you)
  Stream<List<LikeModel>> getLikesReceived(String userId) {
    return _firestore
        .collection('likes')
        .where('likedUserId', isEqualTo: userId)
        .where('isMutualMatch', isEqualTo: false) // Only non-matches
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LikeModel.fromFirestore(doc))
            .toList());
  }

  /// Reveal a like (after watching ads or with Gold subscription)
  Future<void> revealLike(String likeId) async {
    await _firestore.collection('likes').doc(likeId).update({
      'isRevealed': true,
      'revealedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if user can reveal likes (Gold subscription check)
  Future<bool> canRevealWithoutAds(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final subscriptionTier = userDoc.data()?['subscriptionTier'] as String? ?? 'free';
    return subscriptionTier == 'gold';
  }

  /// Get count of unrevealed likes
  Future<int> getUnrevealedLikesCount(String userId) async {
    final snapshot = await _firestore
        .collection('likes')
        .where('likedUserId', isEqualTo: userId)
        .where('isRevealed', isEqualTo: false)
        .where('isMutualMatch', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Record that user watched ads to reveal a like
  Future<void> recordAdWatchForReveal(String userId, int adsWatched) async {
    await _firestore.collection('analytics').add({
      'userId': userId,
      'action': 'watch_ad_reveal_like',
      'adsWatched': adsWatched,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
