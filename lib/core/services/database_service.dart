import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Connect to the nam5 database instance where all users are stored
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Operations
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Stream<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<DocumentSnapshot> getUserProfileOnce(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Discover - Get potential matches
  Stream<QuerySnapshot> getPotentialMatches(String currentUserId,
      {int limit = 1000}) {
    // Get ALL users (no limit) - we'll filter client-side
    // This ensures users always see everyone available
    print('DEBUG DATABASE: Fetching users from Firestore (limit: $limit)');
    return _firestore
        .collection('users')
        .limit(limit) // Get up to 1000 users
        .snapshots();
  }

  // Get all user IDs that current user has already interacted with
  Future<Set<String>> getAllInteractedUserIds(String userId) async {
    try {
      final Set<String> interactedIds = {};

      // Get all likes by this user
      final likesQuery = await _firestore
          .collection('likes')
          .where('likerId', isEqualTo: userId)
          .get();

      for (var doc in likesQuery.docs) {
        final data = doc.data();
        // FIXED: Changed from 'likedId' to 'likedUserId' to match new field name
        if (data['likedUserId'] != null) {
          interactedIds.add(data['likedUserId']);
        }
      }

      // Get all swipes by this user
      final swipesQuery = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in swipesQuery.docs) {
        final data = doc.data();
        if (data['targetUserId'] != null) {
          interactedIds.add(data['targetUserId']);
        }
      }

      return interactedIds;
    } catch (e) {
      print('Error getting interacted user IDs: $e');
      return {};
    }
  }

  // Check if user has already liked/swiped on another user
  Future<bool> hasAlreadyInteracted(String userId, String targetUserId) async {
    try {
      // Check likes collection
      final likeDoc = await _firestore
          .collection('likes')
          .doc('${userId}_$targetUserId')
          .get();

      if (likeDoc.exists) return true;

      // Check swipes collection
      final swipeDoc = await _firestore
          .collection('swipes')
          .doc('${userId}_$targetUserId')
          .get();

      return swipeDoc.exists;
    } catch (e) {
      // If there's an error checking, assume no interaction
      print('Error checking interaction: $e');
      return false;
    }
  }

  // Record a swipe (left or right)
  Future<void> recordSwipe(String userId, String targetUserId, String direction) async {
    await _firestore.collection('swipes').doc('${userId}_$targetUserId').set({
      'userId': userId,
      'targetUserId': targetUserId,
      'direction': direction,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Likes and Matches
  Future<void> likeUser(String likerId, String likedId) async {
    print('DEBUG LIKE: Creating like from $likerId to $likedId');
    final batch = _firestore.batch();

    // Add like with correct field names for likes page
    final likeRef = _firestore.collection('likes').doc('${likerId}_$likedId');
    print('DEBUG LIKE: Setting like document with ID: ${likerId}_$likedId');
    batch.set(likeRef, {
      'likerId': likerId,
      'likedUserId': likedId, // Changed from 'likedId' to match likes service
      'timestamp': FieldValue.serverTimestamp(),
      'isRevealed': false, // For blur feature
      'isMutualMatch': false, // Will be updated if match occurs
    });
    print('DEBUG LIKE: Like document prepared with fields: likerId=$likerId, likedUserId=$likedId');

    // Check for mutual like (match)
    final mutualLikeRef =
        _firestore.collection('likes').doc('${likedId}_$likerId');
    final mutualLikeDoc = await mutualLikeRef.get();

    if (mutualLikeDoc.exists) {
      // Update both likes to mark as mutual match
      batch.update(likeRef, {'isMutualMatch': true});
      batch.update(mutualLikeRef, {'isMutualMatch': true});

      // Create match
      final matchRef = _firestore.collection('matches').doc();
      batch.set(matchRef, {
        'users': [likerId, likedId],
        'timestamp': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Send match notification
      await _sendMatchNotification(likedId, likerId);
    }

    await batch.commit();
    print('DEBUG LIKE: Batch committed successfully! Like should now be in Firestore');
  }

  Future<void> _sendMatchNotification(String userId, String matchedUserId) async {
    // This will be handled by Cloud Functions in production
    // For now, we'll store the notification in Firestore
    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'match',
      'message': 'You have a new match!',
      'matchedUserId': matchedUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // Messages
  Stream<QuerySnapshot> getMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> sendMessage(String chatId, Map<String, dynamic> message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      ...message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update chat metadata
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message['text'] ?? 'Sent a gift',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': message['senderId'],
    });
  }

  // Social Feed (Lovers Anonymous)
  Stream<QuerySnapshot> getPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<void> createPost(Map<String, dynamic> postData) async {
    await _firestore.collection('posts').add({
      ...postData,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
    });
  }

  Future<void> likePost(String postId, String userId) async {
    final batch = _firestore.batch();

    // Add like
    batch.set(
        _firestore.collection('post_likes').doc('${postId}_$userId'), {
      'postId': postId,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update post like count
    batch.update(_firestore.collection('posts').doc(postId), {
      'likes': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> addComment(String postId, Map<String, dynamic> commentData) async {
    final batch = _firestore.batch();

    // Add comment
    batch.set(
        _firestore.collection('post_comments').doc(), {
      ...commentData,
      'postId': postId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update post comment count
    batch.update(_firestore.collection('posts').doc(postId), {
      'comments': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Gifts
  Stream<QuerySnapshot> getGifts() {
    return _firestore.collection('gifts').orderBy('price').snapshots();
  }

  Future<void> sendGift(String senderId, String receiverId, String giftId) async {
    final batch = _firestore.batch();

    // Add gift to receiver's inventory
    batch.set(_firestore.collection('user_gifts').doc(), {
      'senderId': senderId,
      'receiverId': receiverId,
      'giftId': giftId,
      'timestamp': FieldValue.serverTimestamp(),
      'isOpened': false,
    });

    // Deduct from sender's minutes if applicable
    final giftDoc = await _firestore.collection('gifts').doc(giftId).get();
    final giftData = giftDoc.data();
    if (giftData?['price'] != null) {
      batch.update(_firestore.collection('users').doc(senderId), {
        'minutesRemaining': FieldValue.increment(-(giftData!['price'] as int)),
      });
    }

    await batch.commit();
  }

  // Video Calls
  Future<void> createVideoCall(String callerId, String calleeId) async {
    await _firestore.collection('video_calls').add({
      'callerId': callerId,
      'calleeId': calleeId,
      'status': 'calling',
      'startTime': FieldValue.serverTimestamp(),
      'duration': 0,
    });
  }

  Future<void> updateVideoCall(String callId, Map<String, dynamic> updates) async {
    await _firestore.collection('video_calls').doc(callId).update(updates);
  }

  // Minutes and Subscription
  Future<void> addFreeMinutes(String userId, int minutes) async {
    await _firestore.collection('users').doc(userId).update({
      'minutesRemaining': FieldValue.increment(minutes),
      'totalMinutesEarned': FieldValue.increment(minutes),
    });
  }

  Future<void> useMinutes(String userId, int minutes) async {
    await _firestore.collection('users').doc(userId).update({
      'minutesRemaining': FieldValue.increment(-minutes),
    });
  }

  // Analytics
  Future<void> logUserAction(String userId, String action, Map<String, dynamic> data) async {
    await _firestore.collection('analytics').add({
      'userId': userId,
      'action': action,
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Blocking
  Future<void> blockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to block');
    }

    // Add to blocked_users collection
    await _firestore.collection('blocked_users').doc('${currentUser.uid}_$blockedUserId').set({
      'blockerId': currentUser.uid,
      'blockedUserId': blockedUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String blockedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to unblock');
    }

    // Remove from blocked_users collection
    await _firestore.collection('blocked_users').doc('${currentUser.uid}_$blockedUserId').delete();
  }

  Future<bool> isUserBlocked(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // Check if current user blocked this user
    final doc = await _firestore
        .collection('blocked_users')
        .doc('${currentUser.uid}_$userId')
        .get();

    return doc.exists;
  }

  Future<bool> hasUserBlockedMe(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    // Check if this user blocked current user
    final doc = await _firestore
        .collection('blocked_users')
        .doc('${userId}_${currentUser.uid}')
        .get();

    return doc.exists;
  }

  Stream<QuerySnapshot> getBlockedUsers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in');
    }

    return _firestore
        .collection('blocked_users')
        .where('blockerId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<Set<String>> getAllBlockedUserIds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return {};

    try {
      final Set<String> blockedIds = {};

      // Get users I blocked
      final blockedQuery = await _firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: currentUser.uid)
          .get();

      for (var doc in blockedQuery.docs) {
        final data = doc.data();
        if (data['blockedUserId'] != null) {
          blockedIds.add(data['blockedUserId']);
        }
      }

      // Get users who blocked me
      final blockedByQuery = await _firestore
          .collection('blocked_users')
          .where('blockedUserId', isEqualTo: currentUser.uid)
          .get();

      for (var doc in blockedByQuery.docs) {
        final data = doc.data();
        if (data['blockerId'] != null) {
          blockedIds.add(data['blockerId']);
        }
      }

      return blockedIds;
    } catch (e) {
      print('Error getting blocked user IDs: $e');
      return {};
    }
  }
}
