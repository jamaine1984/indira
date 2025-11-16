import 'package:cloud_firestore/cloud_firestore.dart';

class MatchesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if two users have mutually liked each other and create a match
  Future<bool> checkAndCreateMatch(String userId1, String userId2) async {
    try {
      // Check if user1 liked user2
      final user1LikesUser2 = await _firestore
          .collection('likes')
          .where('likerId', isEqualTo: userId1)
          .where('likedUserId', isEqualTo: userId2)
          .limit(1)
          .get();

      // Check if user2 liked user1
      final user2LikesUser1 = await _firestore
          .collection('likes')
          .where('likerId', isEqualTo: userId2)
          .where('likedUserId', isEqualTo: userId1)
          .limit(1)
          .get();

      // If both users liked each other
      if (user1LikesUser2.docs.isNotEmpty && user2LikesUser1.docs.isNotEmpty) {
        // Create match if it doesn't exist
        await _createMatch(userId1, userId2);

        // Update both like documents to mark as matched
        if (user1LikesUser2.docs.isNotEmpty) {
          await user1LikesUser2.docs.first.reference.update({'isMatched': true});
        }
        if (user2LikesUser1.docs.isNotEmpty) {
          await user2LikesUser1.docs.first.reference.update({'isMatched': true});
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Error checking/creating match: $e');
      return false;
    }
  }

  // Create a match between two users
  Future<void> _createMatch(String userId1, String userId2) async {
    // Create a deterministic match ID by sorting the user IDs
    final matchId = _getMatchId(userId1, userId2);

    // Check if match already exists
    final matchDoc = await _firestore.collection('matches').doc(matchId).get();

    if (!matchDoc.exists) {
      await _firestore.collection('matches').doc(matchId).set({
        'users': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': null,
        'user1Id': userId1,
        'user2Id': userId2,
      });
    }
  }

  // Get a deterministic match ID
  String _getMatchId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Get all matches for a user
  Stream<QuerySnapshot> getUserMatches(String userId) {
    return _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Unmatch (delete match)
  Future<void> unmatch(String userId1, String userId2) async {
    final matchId = _getMatchId(userId1, userId2);
    await _firestore.collection('matches').doc(matchId).delete();

    // Also update the like documents to mark as unmatched
    final likes = await _firestore
        .collection('likes')
        .where('likerId', whereIn: [userId1, userId2])
        .where('likedUserId', whereIn: [userId1, userId2])
        .get();

    for (final doc in likes.docs) {
      await doc.reference.update({'isMatched': false});
    }
  }
}
