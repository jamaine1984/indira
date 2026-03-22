const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onObjectFinalized} = require('firebase-functions/v2/storage');
const {onCall, onRequest, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

admin.initializeApp();

// ========== CONTENT GENERATOR (imported) ==========
const contentGenerator = require('./contentGenerator');
exports.generateText = contentGenerator.generateText;
exports.generateImage = contentGenerator.generateImage;

// ========== NOTIFICATION BATCHING (imported) ==========
const notificationBatching = require('./notificationBatching');
exports.queueNotification = notificationBatching.queueNotification;
exports.processBatchedNotifications = notificationBatching.processBatchedNotifications;
exports.cleanupProcessedNotifications = notificationBatching.cleanupProcessedNotifications;
exports.sendImmediateNotification = notificationBatching.sendImmediateNotification;

// ========== MATCHING OPTIMIZATION (imported) ==========
const matchingOptimized = require('./matchingOptimized');
exports.calculateMatchScore = matchingOptimized.calculateMatchScore;
exports.batchCalculateMatches = matchingOptimized.batchCalculateMatches;
exports.dailyMatchScoreUpdate = matchingOptimized.dailyMatchScoreUpdate;
exports.cleanupExpiredScores = matchingOptimized.cleanupExpiredScores;

// ========== LIKE CREATED - Match Detection ==========
exports.onLikeCreated = onDocumentCreated('likes/{likeId}', async (event) => {
  const snap = event.data;
  if (!snap) return null;
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

    const promises = [];
    if (likerToken) {
      promises.push(admin.messaging().send({
        token: likerToken,
        notification: {
          title: '🎉 It\'s a Match!',
          body: 'You have a new match! Start chatting now.',
        },
        data: { type: 'match', matchId: matchRef.id },
      }));
    }
    if (likedToken) {
      promises.push(admin.messaging().send({
        token: likedToken,
        notification: {
          title: '🎉 It\'s a Match!',
          body: 'You have a new match! Start chatting now.',
        },
        data: { type: 'match', matchId: matchRef.id },
      }));
    }

    await Promise.all(promises);
  } else {
    // No match yet — send "New Like" notification to liked user
    try {
      const likerDoc = await admin.firestore().collection('users').doc(likerId).get();
      const likerName = likerDoc.data()?.displayName || 'Someone';

      const likedDoc = await admin.firestore().collection('users').doc(likedId).get();
      const fcmToken = likedDoc.data()?.fcmToken;

      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: '❤️ New Like!',
            body: `${likerName} liked your profile!`,
          },
          data: { type: 'like', likerId },
        });
      }
    } catch (e) {
      console.error('Like notification error:', e);
    }
  }

  return null;
});

// ========== MESSAGE CREATED - Push Notification ==========
exports.onMessageCreated = onDocumentCreated('chats/{chatId}/messages/{messageId}', async (event) => {
  const snap = event.data;
  if (!snap) return null;
  const messageData = snap.data();
  const { senderId, text } = messageData;
  const chatId = event.params.chatId;

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

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: 'New Message',
      body: text || 'You received a new message',
    },
    data: { type: 'message', chatId, senderId },
  });

  return null;
});

// ========== CLEANUP EXPIRED DATA - Scheduled ==========
exports.cleanupExpiredData = onSchedule('every 24 hours', async (event) => {
  const now = admin.firestore.Timestamp.now();
  const oneWeekAgo = new admin.firestore.Timestamp(now.seconds - 7 * 24 * 60 * 60, 0);

  const expiredMatches = await admin.firestore()
    .collection('matches')
    .where('isActive', '==', false)
    .where('timestamp', '<', oneWeekAgo)
    .get();

  const batch = admin.firestore().batch();
  expiredMatches.docs.forEach(doc => batch.delete(doc.ref));
  if (expiredMatches.size > 0) await batch.commit();

  console.log(`Cleaned up ${expiredMatches.size} expired matches`);
  return null;
});

// ========== UPDATE USER ONLINE STATUS ==========
exports.updateUserOnlineStatus = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = request.auth.uid;
  const isOnline = request.data.isOnline || false;

  await admin.firestore().collection('users').doc(userId).update({
    isOnline,
    lastSeen: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ========== SEND GIFT ==========
exports.sendGift = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { receiverId, giftId } = request.data;
  const senderId = request.auth.uid;

  const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
  const senderData = senderDoc.data();

  const giftDoc = await admin.firestore().collection('gifts').doc(giftId).get();
  const giftData = giftDoc.data();

  if (!giftData) {
    throw new HttpsError('not-found', 'Gift not found');
  }

  const giftPrice = giftData.price || 0;

  if (senderData.minutesRemaining < giftPrice) {
    throw new HttpsError('failed-precondition', 'Insufficient minutes');
  }

  const giftRef = admin.firestore().collection('user_gifts').doc();
  await giftRef.set({
    senderId, receiverId, giftId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isOpened: false,
  });

  await admin.firestore().collection('users').doc(senderId).update({
    minutesRemaining: admin.firestore.FieldValue.increment(-giftPrice),
  });

  const receiverDoc = await admin.firestore().collection('users').doc(receiverId).get();
  const fcmToken = receiverDoc.data()?.fcmToken;

  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title: '🎁 New Gift!', body: 'Someone sent you a gift!' },
      data: { type: 'gift', giftId: giftRef.id },
    });
  }

  return { success: true, giftId: giftRef.id };
});

// ========== IMAGE MODERATION ==========
exports.moderateUserImage = onObjectFinalized(async (event) => {
  const filePath = event.data.name;
  if (!filePath) return null;

  const isProfileImage = filePath.startsWith('profile_images/') ||
                         filePath.startsWith('user_photos/');
  const isVerificationImage = filePath.startsWith('verification_selfies/') ||
                              filePath.startsWith('verification/');
  const isChatImage = filePath.startsWith('chat_images/');

  if (!isProfileImage && !isVerificationImage && !isChatImage) return null;

  console.log(`Moderating image: ${filePath}`);

  try {
    const vision = require('@google-cloud/vision');
    const client = new vision.ImageAnnotatorClient();

    const bucket = admin.storage().bucket(event.data.bucket);
    const file = bucket.file(filePath);

    await file.makePublic();
    const publicUrl = `https://storage.googleapis.com/${event.data.bucket}/${filePath}`;

    const [safeSearchResult, faceResult] = await Promise.all([
      client.safeSearchDetection(publicUrl),
      isVerificationImage ? client.faceDetection(publicUrl) : Promise.resolve([null]),
    ]);

    const safeSearch = safeSearchResult[0]?.safeSearchAnnotation || safeSearchResult.safeSearchAnnotation;
    await file.makePrivate();

    // Extract userId from path
    const pathParts = filePath.split('/');
    let userId = null;
    if (isChatImage && pathParts.length >= 3) {
      // chat_images/{matchId}/{timestamp}.jpg — extract sender from metadata or matchId
      // We log the matchId for tracing
      userId = pathParts[1]; // matchId as identifier
    } else if (pathParts.length >= 2) {
      const fileName = pathParts[pathParts.length - 1];
      userId = fileName.split('_')[0];
    }

    // SafeSearch Check
    if (safeSearch) {
      console.log('SafeSearch results:', JSON.stringify(safeSearch));

      const blocked = ['LIKELY', 'VERY_LIKELY'];
      const isNSFW = blocked.includes(safeSearch.adult) ||
                      blocked.includes(safeSearch.violence) ||
                      blocked.includes(safeSearch.racy);

      if (isNSFW) {
        console.log(`BLOCKED: Image ${filePath} flagged as inappropriate`);
        await file.delete();

        await admin.firestore().collection('moderation_log').add({
          filePath, userId, safeSearch,
          action: 'deleted',
          reason: 'NSFW content detected',
          imageType: isChatImage ? 'chat' : isVerificationImage ? 'verification' : 'profile',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (isVerificationImage && userId) {
          await admin.firestore().collection('users').doc(userId).update({
            'verificationStatus': 'rejected',
            'verificationRejectedReason': 'Inappropriate image detected. Please upload an appropriate photo.',
            'verificationRejectedAt': admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        return { blocked: true, reason: 'nsfw' };
      }
    }

    // Face Detection for Verification Images
    if (isVerificationImage && faceResult && faceResult[0]) {
      const faces = faceResult[0].faceAnnotations || [];
      console.log(`Face detection: ${faces.length} face(s) found in ${filePath}`);

      if (faces.length === 0) {
        console.log(`REJECTED: No face detected in verification image ${filePath}`);
        await file.delete();

        await admin.firestore().collection('moderation_log').add({
          filePath, userId,
          action: 'rejected',
          reason: 'No face detected in verification selfie',
          facesFound: 0,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        if (userId) {
          await admin.firestore().collection('users').doc(userId).update({
            'verificationStatus': 'rejected',
            'verificationRejectedReason': 'No face detected. Please take a clear selfie with your face visible.',
            'verificationRejectedAt': admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        return { blocked: true, reason: 'no_face' };
      }

      if (faces.length > 1) {
        console.log(`REJECTED: Multiple faces (${faces.length}) in verification image ${filePath}`);
        await file.delete();

        if (userId) {
          await admin.firestore().collection('users').doc(userId).update({
            'verificationStatus': 'rejected',
            'verificationRejectedReason': 'Multiple faces detected. Please take a selfie with only your face visible.',
            'verificationRejectedAt': admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        return { blocked: true, reason: 'multiple_faces' };
      }

      const face = faces[0];
      const confidence = face.detectionConfidence || 0;
      console.log(`Face confidence: ${confidence} for ${filePath}`);

      await admin.firestore().collection('moderation_log').add({
        filePath, userId,
        action: 'approved',
        facesFound: 1,
        faceConfidence: confidence,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    console.log(`APPROVED: Image ${filePath} passed moderation`);
    return { blocked: false };
  } catch (error) {
    console.error('Image moderation error:', error);
    return null;
  }
});

// ========== FCM NOTIFICATION SENDER ==========
exports.sendFCMNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const snap = event.data;
  if (!snap) return null;
  const data = snap.data();
  const { recipientId, title, body, type, sent } = data;

  if (sent) return null;

  try {
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${recipientId}`);
      return null;
    }

    await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: {
        type: type || 'general',
        notificationId: event.params.notificationId,
      },
    });

    await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
    console.log(`Notification sent to ${recipientId}: ${title}`);
    return null;
  } catch (error) {
    console.error('FCM send error:', error);
    return null;
  }
});

// Note: Like notification is handled inside onLikeCreated above to avoid
// duplicate triggers on the same document path (v2 limitation)

// ========== DAILY ENGAGEMENT TASKS ==========
exports.dailyEngagementTasks = onSchedule('every 24 hours', async (event) => {
  console.log('Running daily engagement tasks...');

  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const threeDaysAgo = new admin.firestore.Timestamp(now.seconds - 3 * 24 * 60 * 60, 0);
  const sevenDaysAgo = new admin.firestore.Timestamp(now.seconds - 7 * 24 * 60 * 60, 0);

  try {
    // Send re-engagement notifications to inactive users (3+ days)
    const inactiveUsers = await db.collection('users')
      .where('lastSeen', '<', threeDaysAgo)
      .where('lastSeen', '>', sevenDaysAgo)
      .limit(100)
      .get();

    let notificationsSent = 0;
    for (const userDoc of inactiveUsers.docs) {
      const fcmToken = userDoc.data().fcmToken;
      if (fcmToken) {
        try {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: '💕 People are waiting!',
              body: 'Open Indira Love to see who liked your profile!',
            },
            data: { type: 're_engagement' },
          });
          notificationsSent++;
        } catch (e) {
          if (e.code === 'messaging/invalid-registration-token' ||
              e.code === 'messaging/registration-token-not-registered') {
            await userDoc.ref.update({ fcmToken: null });
          }
        }
      }
    }

    // Clean up old swipes (older than 30 days)
    const thirtyDaysAgo = new admin.firestore.Timestamp(now.seconds - 30 * 24 * 60 * 60, 0);
    const oldSwipes = await db.collection('swipes')
      .where('timestamp', '<', thirtyDaysAgo)
      .limit(500)
      .get();

    const batch = db.batch();
    oldSwipes.docs.forEach(doc => batch.delete(doc.ref));
    if (oldSwipes.size > 0) await batch.commit();

    console.log(`Daily tasks complete: ${notificationsSent} re-engagement notifications, ${oldSwipes.size} old swipes cleaned`);
    return null;
  } catch (error) {
    console.error('Daily engagement error:', error);
    return null;
  }
});

// ========== REVENUECAT WEBHOOK ==========
// Set this URL in RevenueCat Dashboard → Integrations → Webhooks
// URL: https://<region>-<project-id>.cloudfunctions.net/revenueCatWebhook
exports.revenueCatWebhook = onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).send('Method Not Allowed');
    return;
  }

  const event = req.body;
  if (!event || !event.event) {
    res.status(400).send('Invalid payload');
    return;
  }

  const eventType = event.event.type;
  const appUserId = event.event.app_user_id;

  console.log(`RevenueCat webhook: ${eventType} for user ${appUserId}`);

  try {
    const db = admin.firestore();

    // Map RevenueCat entitlements to subscription tier
    const entitlements = event.event.entitlement_ids || [];
    let tier = 'free';
    let isActive = false;

    if (entitlements.includes('indira_gold')) {
      tier = 'gold';
      isActive = true;
    } else if (entitlements.includes('indira_silver')) {
      tier = 'silver';
      isActive = true;
    }

    // Determine tier from product_id as fallback
    const productId = event.event.product_id || '';
    if (tier === 'free' && productId) {
      if (productId.includes('gold')) {
        tier = 'gold';
        isActive = true;
      } else if (productId.includes('silver')) {
        tier = 'silver';
        isActive = true;
      }
    }

    switch (eventType) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'PRODUCT_CHANGE':
      case 'UNCANCELLATION': {
        const expiresAt = event.event.expiration_at_ms
          ? new Date(event.event.expiration_at_ms)
          : null;

        await db.collection('users').doc(appUserId).update({
          subscriptionTier: tier,
          subscriptionActive: isActive,
          subscriptionProductId: productId,
          subscriptionExpiryDate: expiresAt
            ? admin.firestore.Timestamp.fromDate(expiresAt)
            : null,
          lastSubscriptionSync: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Subscription activated: ${tier} for ${appUserId}`);
        break;
      }

      case 'CANCELLATION':
      case 'EXPIRATION': {
        await db.collection('users').doc(appUserId).update({
          subscriptionTier: 'free',
          subscriptionActive: false,
          lastSubscriptionSync: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Subscription ended for ${appUserId}`);
        break;
      }

      case 'BILLING_ISSUE': {
        await db.collection('users').doc(appUserId).update({
          subscriptionBillingIssue: true,
          lastSubscriptionSync: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Notify user about billing issue
        const userDoc = await db.collection('users').doc(appUserId).get();
        const fcmToken = userDoc.data()?.fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: 'Billing Issue',
              body: 'There was a problem with your subscription payment. Please update your payment method.',
            },
            data: { type: 'billing_issue' },
          });
        }
        break;
      }

      default:
        console.log(`Unhandled RevenueCat event: ${eventType}`);
    }

    // Log webhook event for audit
    await db.collection('subscription_events').add({
      userId: appUserId,
      eventType,
      productId,
      tier,
      entitlements,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      rawEvent: event.event,
    });

    res.status(200).send('OK');
  } catch (error) {
    console.error('RevenueCat webhook error:', error);
    res.status(500).send('Internal error');
  }
});

// ========== CHECK EXPIRED SUBSCRIPTIONS (RevenueCat fallback) ==========
exports.checkExpiredSubscriptions = onSchedule('every 24 hours', async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const expiredUsers = await db.collection('users')
    .where('subscriptionActive', '==', true)
    .where('subscriptionExpiryDate', '<=', now)
    .get();

  const batch = db.batch();
  let count = 0;

  expiredUsers.docs.forEach(doc => {
    batch.update(doc.ref, {
      subscriptionTier: 'free',
      subscriptionActive: false,
      subscriptionExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    count++;
  });

  if (count > 0) await batch.commit();
  console.log(`Expired ${count} subscriptions`);
  return null;
});
