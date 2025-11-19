const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Import optimization modules
const matchingOptimized = require('./matchingOptimized');
const notificationBatching = require('./notificationBatching');

// Cloud Firestore triggers
exports.onLikeCreated = functions.firestore
  .document('likes/{likeId}')
  .onCreate(async (snap, context) => {
    const likeData = snap.data();
    const { likerId, likedId } = likeData;

    // Check if there's a mutual like (match)
    const mutualLikeQuery = await admin.firestore()
      .collection('likes')
      .where('likerId', '==', likedId)
      .where('likedId', '==', likerId)
      .limit(1)
      .get();

    if (!mutualLikeQuery.empty) {
      // Create match document
      const matchRef = admin.firestore().collection('matches').doc();
      await matchRef.set({
        users: [likerId, likedId],
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
      });

      // Send match notifications to both users
      const [likerDoc, likedDoc] = await Promise.all([
        admin.firestore().collection('users').doc(likerId).get(),
        admin.firestore().collection('users').doc(likedId).get(),
      ]);

      const likerToken = likerDoc.data()?.fcmToken;
      const likedToken = likedDoc.data()?.fcmToken;

      const matchMessage = {
        notification: {
          title: '🎉 It\'s a Match!',
          body: 'You have a new match! Start chatting now.',
        },
        data: {
          type: 'match',
          matchId: matchRef.id,
        },
      };

      const promises = [];
      if (likerToken) {
        promises.push(admin.messaging().sendToDevice(likerToken, matchMessage));
      }
      if (likedToken) {
        promises.push(admin.messaging().sendToDevice(likedToken, matchMessage));
      }

      await Promise.all(promises);
    }

    return null;
  });

exports.onMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const { senderId, text } = messageData;
    const chatId = context.params.chatId;

    // Get chat participants
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return null;

    const participants = chatDoc.data()?.participants || [];
    const recipientId = participants.find(id => id !== senderId);

    if (!recipientId) return null;

    // Get recipient's FCM token
    const recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();
    const fcmToken = recipientDoc.data()?.fcmToken;

    if (!fcmToken) return null;

    // Send push notification
    const message = {
      notification: {
        title: 'New Message',
        body: text || 'You received a new message',
      },
      data: {
        type: 'message',
        chatId: chatId,
        senderId: senderId,
      },
    };

    await admin.messaging().sendToDevice(fcmToken, message);

    return null;
  });

exports.onVideoCallCreated = functions.firestore
  .document('video_calls/{callId}')
  .onCreate(async (snap, context) => {
    const callData = snap.data();
    const { callerId, calleeId } = callData;

    // Get callee's FCM token
    const calleeDoc = await admin.firestore().collection('users').doc(calleeId).get();
    const fcmToken = calleeDoc.data()?.fcmToken;

    if (!fcmToken) return null;

    // Send incoming call notification
    const message = {
      notification: {
        title: 'Incoming Video Call',
        body: 'Someone wants to video chat with you!',
      },
      data: {
        type: 'video_call',
        callId: context.params.callId,
        callerId: callerId,
      },
    };

    await admin.messaging().sendToDevice(fcmToken, message);

    return null;
  });

// Scheduled function to clean up expired matches and calls
exports.cleanupExpiredData = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const oneWeekAgo = new admin.firestore.Timestamp(now.seconds - 7 * 24 * 60 * 60, 0);

    // Clean up old inactive matches
    const expiredMatches = await admin.firestore()
      .collection('matches')
      .where('isActive', '==', false)
      .where('timestamp', '<', oneWeekAgo)
      .get();

    const batch = admin.firestore().batch();
    expiredMatches.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`Cleaned up ${expiredMatches.size} expired matches`);

    return null;
  });

// Function to update user online status
exports.updateUserOnlineStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const isOnline = data.isOnline || false;

  await admin.firestore().collection('users').doc(userId).update({
    isOnline: isOnline,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// Function to send gift
exports.sendGift = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { receiverId, giftId } = data;
  const senderId = context.auth.uid;

  // Verify sender has enough minutes
  const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
  const senderData = senderDoc.data();

  const giftDoc = await admin.firestore().collection('gifts').doc(giftId).get();
  const giftData = giftDoc.data();

  if (!giftData) {
    throw new functions.https.HttpsError('not-found', 'Gift not found');
  }

  const giftPrice = giftData.price || 0;

  if (senderData.minutesRemaining < giftPrice) {
    throw new functions.https.HttpsError('failed-precondition', 'Insufficient minutes');
  }

  // Send gift
  const giftRef = admin.firestore().collection('user_gifts').doc();
  await giftRef.set({
    senderId,
    receiverId,
    giftId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isOpened: false,
  });

  // Deduct minutes
  await admin.firestore().collection('users').doc(senderId).update({
    minutesRemaining: admin.firestore.FieldValue.increment(-giftPrice),
  });

  // Send notification to receiver
  const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
  const fcmToken = receiverDoc.data()?.fcmToken;

  if (fcmToken) {
    const message = {
      notification: {
        title: '🎁 New Gift!',
        body: 'Someone sent you a gift!',
      },
      data: {
        type: 'gift',
        giftId: giftRef.id,
      },
    };

    await admin.messaging().sendToDevice(fcmToken, message);
  }

  return { success: true, giftId: giftRef.id };
});

// ========== SCALABILITY OPTIMIZATION EXPORTS ==========

// Server-side matching optimization functions
exports.calculateMatchScore = matchingOptimized.calculateMatchScore;
exports.batchCalculateMatches = matchingOptimized.batchCalculateMatches;
exports.dailyMatchScoreUpdate = matchingOptimized.dailyMatchScoreUpdate;
exports.cleanupExpiredScores = matchingOptimized.cleanupExpiredScores;

// Notification batching functions
exports.queueNotification = notificationBatching.queueNotification;
exports.processBatchedNotifications = notificationBatching.processBatchedNotifications;
exports.cleanupProcessedNotifications = notificationBatching.cleanupProcessedNotifications;
exports.sendImmediateNotification = notificationBatching.sendImmediateNotification;
