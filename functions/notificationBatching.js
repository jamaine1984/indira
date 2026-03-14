const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

/**
 * NOTIFICATION BATCHING OPTIMIZATION FOR INDIRA LOVE
 *
 * Batches notifications together and sends at intervals to reduce costs.
 */

// Queue a notification for batching
exports.queueNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, type, title, body, customData } = request.data;

  if (!userId || !type || !title || !body) {
    throw new HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const db = admin.firestore();

    await db.collection('notification_queue').add({
      userId, type, title, body,
      data: customData || {},
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      scheduledFor: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 5 * 60 * 1000)
      )
    });

    console.log(`Notification queued for user ${userId}`);
    return { success: true, message: 'Notification queued' };
  } catch (error) {
    console.error('Error queuing notification:', error);
    throw new HttpsError('internal', `Failed to queue notification: ${error.message}`);
  }
});

// Process batched notifications (runs every 5 minutes)
exports.processBatchedNotifications = onSchedule('every 5 minutes', async (event) => {
  console.log('Processing batched notifications');

  const db = admin.firestore();

  try {
    const now = admin.firestore.Timestamp.now();

    const pendingNotifications = await db.collection('notification_queue')
      .where('status', '==', 'pending')
      .where('scheduledFor', '<=', now)
      .limit(500)
      .get();

    if (pendingNotifications.empty) {
      console.log('No pending notifications to process');
      return null;
    }

    console.log(`Found ${pendingNotifications.size} pending notifications`);

    // Group by user and type
    const userNotifications = {};

    pendingNotifications.docs.forEach(doc => {
      const data = doc.data();
      const key = `${data.userId}_${data.type}`;

      if (!userNotifications[key]) {
        userNotifications[key] = {
          userId: data.userId,
          type: data.type,
          notifications: [],
          docRefs: []
        };
      }

      userNotifications[key].notifications.push(data);
      userNotifications[key].docRefs.push(doc.ref);
    });

    let sentCount = 0;

    for (const key in userNotifications) {
      const group = userNotifications[key];

      try {
        const userDoc = await db.collection('users').doc(group.userId).get();
        if (!userDoc.exists) continue;

        const fcmToken = userDoc.data().fcmToken;
        if (!fcmToken) continue;

        const aggregated = aggregateNotifications(group.notifications);

        const message = {
          token: fcmToken,
          notification: { title: aggregated.title, body: aggregated.body },
          data: {
            type: group.type,
            count: group.notifications.length.toString(),
            ...aggregated.data
          },
          android: {
            notification: {
              channelId: group.type,
              priority: 'default',
              defaultSound: true,
            },
          },
          apns: {
            payload: { aps: { sound: 'default', badge: 1 } },
          },
        };

        await admin.messaging().send(message);
        sentCount++;

        const batch = db.batch();
        group.docRefs.forEach(ref => {
          batch.update(ref, {
            status: 'sent',
            sentAt: admin.firestore.FieldValue.serverTimestamp()
          });
        });
        await batch.commit();
      } catch (error) {
        console.error(`Error sending notification to ${group.userId}:`, error);
      }
    }

    console.log(`Batch processing complete: ${sentCount} notifications sent`);
    return null;
  } catch (error) {
    console.error('Error processing batched notifications:', error);
    return null;
  }
});

// Helper: Aggregate multiple notifications into one
function aggregateNotifications(notifications) {
  if (notifications.length === 1) {
    return {
      title: notifications[0].title,
      body: notifications[0].body,
      data: notifications[0].data
    };
  }

  const type = notifications[0].type;
  const count = notifications.length;

  let title = '';
  let body = '';
  const data = {};

  switch (type) {
    case 'like':
      title = `${count} New Likes!`;
      body = `${count} people liked your profile`;
      break;
    case 'message':
      title = `${count} New Messages`;
      const senders = notifications.map(n => n.data.senderName || 'Someone').slice(0, 3);
      body = senders.length === count
        ? `From ${senders.join(', ')}`
        : `From ${senders.join(', ')} and ${count - senders.length} others`;
      break;
    case 'match':
      title = `${count} New Matches!`;
      body = `You have ${count} new matches`;
      break;
    case 'gift':
      title = `${count} Gifts Received!`;
      body = `You received ${count} new gifts`;
      break;
    default:
      title = `${count} New Notifications`;
      body = `You have ${count} new updates`;
  }

  return { title, body, data };
}

// Clean up old processed notifications (runs daily)
exports.cleanupProcessedNotifications = onSchedule('every 24 hours', async (event) => {
  console.log('Cleaning up processed notifications');

  const db = admin.firestore();

  try {
    const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );

    const oldNotifications = await db.collection('notification_queue')
      .where('status', '==', 'sent')
      .where('sentAt', '<=', sevenDaysAgo)
      .limit(500)
      .get();

    if (oldNotifications.empty) {
      console.log('No old notifications to clean up');
      return null;
    }

    const batch = db.batch();
    oldNotifications.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`Cleaned up ${oldNotifications.size} old notifications`);
    return null;
  } catch (error) {
    console.error('Error cleaning up notifications:', error);
    return null;
  }
});

// Send immediate notification (bypass batching for urgent ones)
exports.sendImmediateNotification = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { userId, title, body, type, customData } = request.data;

  if (!userId || !title || !body) {
    throw new HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const db = admin.firestore();

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }

    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) {
      throw new HttpsError('failed-precondition', 'No FCM token');
    }

    const message = {
      token: fcmToken,
      notification: { title, body },
      data: customData || {},
      android: {
        notification: {
          channelId: type || 'general',
          priority: 'high',
          defaultSound: true,
        },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    };

    await admin.messaging().send(message);

    console.log(`Immediate notification sent to ${userId}`);
    return { success: true, message: 'Notification sent' };
  } catch (error) {
    console.error('Error sending immediate notification:', error);
    throw new HttpsError('internal', `Failed to send notification: ${error.message}`);
  }
});
