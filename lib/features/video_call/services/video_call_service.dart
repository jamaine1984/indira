import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

class VideoCallService {
  VideoCallService._();
  static final VideoCallService _instance = VideoCallService._();
  factory VideoCallService() => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Check if user can call the target (must have mutual match or messaging history)
  Future<Map<String, dynamic>> canCall(String targetUserId) async {
    final caller = _auth.currentUser;
    if (caller == null) {
      return {'allowed': false, 'reason': 'Not authenticated'};
    }

    try {
      // Check 1: Is there a mutual match between these users?
      // matches doc ID can be either order of user IDs
      final matchQuery1 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: caller.uid)
          .where('user2Id', isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (matchQuery1.docs.isNotEmpty) {
        return {'allowed': true, 'reason': 'Mutual match found'};
      }

      final matchQuery2 = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: targetUserId)
          .where('user2Id', isEqualTo: caller.uid)
          .limit(1)
          .get();

      if (matchQuery2.docs.isNotEmpty) {
        return {'allowed': true, 'reason': 'Mutual match found'};
      }

      // Check 2: Do they have a match doc by composite ID patterns?
      // Some apps use sorted IDs as doc ID
      final ids = [caller.uid, targetUserId]..sort();
      final compositeId = '${ids[0]}_${ids[1]}';
      final compositeMatch = await _firestore
          .collection('matches')
          .doc(compositeId)
          .get();

      if (compositeMatch.exists) {
        return {'allowed': true, 'reason': 'Mutual match found'};
      }

      // Check 3: Have they exchanged messages? (check both users as sender)
      // Look through all match docs for any conversation between these users
      final allMatches = await _firestore
          .collection('matches')
          .where('users', arrayContains: caller.uid)
          .get();

      for (var matchDoc in allMatches.docs) {
        final data = matchDoc.data();
        final users = data['users'] as List<dynamic>?;
        if (users != null && users.contains(targetUserId)) {
          // Found a match containing both users
          return {'allowed': true, 'reason': 'Matched users'};
        }

        // Also check user1Id/user2Id pattern
        final u1 = data['user1Id'] as String?;
        final u2 = data['user2Id'] as String?;
        if ((u1 == caller.uid && u2 == targetUserId) ||
            (u1 == targetUserId && u2 == caller.uid)) {
          return {'allowed': true, 'reason': 'Matched users'};
        }
      }

      // Check 4: Direct message history check
      final sentMessages = await _firestore
          .collectionGroup('messages')
          .where('senderId', isEqualTo: caller.uid)
          .where('receiverId', isEqualTo: targetUserId)
          .limit(1)
          .get();

      if (sentMessages.docs.isNotEmpty) {
        return {'allowed': true, 'reason': 'Messaging history exists'};
      }

      final receivedMessages = await _firestore
          .collectionGroup('messages')
          .where('senderId', isEqualTo: targetUserId)
          .where('receiverId', isEqualTo: caller.uid)
          .limit(1)
          .get();

      if (receivedMessages.docs.isNotEmpty) {
        return {'allowed': true, 'reason': 'Messaging history exists'};
      }

      // No match or messaging history found
      return {
        'allowed': false,
        'reason': 'You can only call users you have matched with or messaged',
      };
    } catch (e) {
      logger.error('Error checking call permission: $e');
      // On error, block the call for security (fail closed)
      return {'allowed': false, 'reason': 'Unable to verify call permission. Please try again.'};
    }
  }

  /// Initiate a call to another user (checks permissions first)
  Future<Map<String, dynamic>> initiateCall({
    required String targetUserId,
    required String targetUserName,
    bool audioOnly = false,
  }) async {
    final caller = _auth.currentUser;
    if (caller == null) {
      throw StateError('No authenticated user');
    }

    // Check call permission
    final permission = await canCall(targetUserId);
    if (permission['allowed'] != true) {
      return {
        'success': false,
        'error': permission['reason'],
      };
    }

    final sessionId =
        '${caller.uid}_${targetUserId}_${DateTime.now().millisecondsSinceEpoch}';

    final callerName = caller.displayName?.isNotEmpty == true
        ? caller.displayName!
        : caller.email ?? caller.uid;

    // Get caller photo
    String? callerPhoto;
    try {
      final callerDoc = await _firestore.collection('users').doc(caller.uid).get();
      final photos = callerDoc.data()?['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) {
        callerPhoto = photos[0].toString();
      }
    } catch (_) {}

    try {
      // Store session in Firestore
      await _firestore.collection('video_sessions').doc(sessionId).set({
        'sessionId': sessionId,
        'callerId': caller.uid,
        'callerName': callerName,
        'callerPhoto': callerPhoto,
        'targetId': targetUserId,
        'targetName': targetUserName,
        'type': audioOnly ? 'audio' : 'video',
        'status': 'ringing',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create call notification for target user
      await _firestore.collection('call_notifications').doc(sessionId).set({
        'sessionId': sessionId,
        'callerId': caller.uid,
        'callerName': callerName,
        'callerPhoto': callerPhoto,
        'targetId': targetUserId,
        'targetName': targetUserName,
        'callType': audioOnly ? 'audio' : 'video',
        'status': 'ringing',
        'timestamp': FieldValue.serverTimestamp(),
      });

      logger.info('Call initiated: $sessionId');

      return {
        'success': true,
        'sessionId': sessionId,
        'callerId': caller.uid,
        'callerName': callerName,
        'targetUserId': targetUserId,
        'targetName': targetUserName,
        'callType': audioOnly ? 'audio' : 'video',
      };
    } catch (e) {
      logger.error('Error initiating call: $e');
      rethrow;
    }
  }

  /// Answer an incoming call
  Future<void> answerCall(String sessionId) async {
    try {
      await _firestore.collection('video_sessions').doc(sessionId).update({
        'status': 'active',
        'answeredAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('call_notifications').doc(sessionId).update({
        'status': 'answered',
      });

      logger.info('Call answered: $sessionId');
    } catch (e) {
      logger.error('Error answering call: $e');
    }
  }

  /// Reject an incoming call
  Future<void> rejectCall(String sessionId) async {
    try {
      await _firestore.collection('video_sessions').doc(sessionId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('call_notifications').doc(sessionId).update({
        'status': 'rejected',
      });

      logger.info('Call rejected: $sessionId');
    } catch (e) {
      logger.error('Error rejecting call: $e');
    }
  }

  /// End call and log duration
  Future<void> endCall(String sessionId, int durationSeconds) async {
    try {
      await _firestore.collection('video_sessions').doc(sessionId).update({
        'status': 'ended',
        'durationSeconds': durationSeconds,
        'endedAt': FieldValue.serverTimestamp(),
      });

      // Clean up notification
      await _firestore
          .collection('call_notifications')
          .doc(sessionId)
          .update({'status': 'ended'});

      logger.info('Call ended: $sessionId ($durationSeconds seconds)');
    } catch (e) {
      logger.error('Error ending call: $e');
    }
  }

  /// Cancel an outgoing call (caller hangs up before answer)
  Future<void> cancelCall(String sessionId) async {
    try {
      await _firestore.collection('video_sessions').doc(sessionId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('call_notifications').doc(sessionId).update({
        'status': 'cancelled',
      });

      logger.info('Call cancelled: $sessionId');
    } catch (e) {
      logger.error('Error cancelling call: $e');
    }
  }

  /// Stream incoming call notifications
  Stream<QuerySnapshot> streamCallNotifications(String userId) {
    return _firestore
        .collection('call_notifications')
        .where('targetId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }
}
