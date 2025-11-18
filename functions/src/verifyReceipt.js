/**
 * Cloud Function for server-side IAP receipt verification
 * Supports both iOS App Store and Google Play Store receipts
 *
 * PRODUCTION REQUIREMENTS:
 * 1. Set up Google Play Developer API credentials
 * 2. Set up App Store Connect API credentials
 * 3. Store API keys in Firebase Functions config or Secret Manager
 * 4. Enable billing for the Firebase project
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');
const axios = require('axios');

// Initialize Firebase Admin (only once)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Verify iOS App Store receipt
 * @param {string} receipt - Base64 encoded receipt data
 * @param {string} productId - Product ID to verify
 * @returns {Promise<Object>} Verification result
 */
async function verifyAppleReceipt(receipt, productId) {
  const APPLE_VERIFY_RECEIPT_URL_PRODUCTION = 'https://buy.itunes.apple.com/verifyReceipt';
  const APPLE_VERIFY_RECEIPT_URL_SANDBOX = 'https://sandbox.itunes.apple.com/verifyReceipt';

  // Get shared secret from Firebase config
  // Set via: firebase functions:config:set apple.shared_secret="your_shared_secret"
  const sharedSecret = functions.config().apple?.shared_secret || '';

  const requestBody = {
    'receipt-data': receipt,
    'password': sharedSecret,
    'exclude-old-transactions': true,
  };

  try {
    // Try production first
    let response = await axios.post(APPLE_VERIFY_RECEIPT_URL_PRODUCTION, requestBody);

    // If status is 21007, receipt is from sandbox, try sandbox URL
    if (response.data.status === 21007) {
      console.log('Receipt is from sandbox, retrying with sandbox URL');
      response = await axios.post(APPLE_VERIFY_RECEIPT_URL_SANDBOX, requestBody);
    }

    const { status, receipt: receiptData } = response.data;

    // Status 0 = valid receipt
    if (status !== 0) {
      console.error('Apple receipt verification failed:', status);
      return {
        valid: false,
        reason: `Apple verification failed with status ${status}`,
        rawResponse: response.data,
      };
    }

    // Check if product ID matches
    const inAppPurchases = receiptData.in_app || [];
    const matchingPurchase = inAppPurchases.find(
      purchase => purchase.product_id === productId
    );

    if (!matchingPurchase) {
      return {
        valid: false,
        reason: 'Product ID not found in receipt',
      };
    }

    // Check if subscription is active (for subscriptions)
    const latestReceiptInfo = response.data.latest_receipt_info || [];
    const latestPurchase = latestReceiptInfo.find(
      purchase => purchase.product_id === productId
    );

    if (latestPurchase) {
      const expiresDate = new Date(parseInt(latestPurchase.expires_date_ms));
      const now = new Date();

      if (expiresDate < now) {
        return {
          valid: false,
          reason: 'Subscription expired',
          expiresDate: expiresDate.toISOString(),
        };
      }
    }

    return {
      valid: true,
      transactionId: matchingPurchase.transaction_id,
      purchaseDate: matchingPurchase.purchase_date,
      productId: matchingPurchase.product_id,
      expiresDate: latestPurchase?.expires_date_ms
        ? new Date(parseInt(latestPurchase.expires_date_ms)).toISOString()
        : null,
    };
  } catch (error) {
    console.error('Error verifying Apple receipt:', error);
    return {
      valid: false,
      reason: 'Error contacting Apple servers',
      error: error.message,
    };
  }
}

/**
 * Verify Google Play receipt
 * @param {string} packageName - App package name
 * @param {string} productId - Product ID
 * @param {string} purchaseToken - Purchase token from receipt
 * @returns {Promise<Object>} Verification result
 */
async function verifyGoogleReceipt(packageName, productId, purchaseToken) {
  try {
    // Get service account credentials from Firebase config
    // You need to upload your Google Play service account JSON file
    const serviceAccount = functions.config().google?.service_account;

    if (!serviceAccount) {
      throw new Error('Google service account not configured');
    }

    // Initialize Google Play Developer API
    const auth = new google.auth.GoogleAuth({
      credentials: JSON.parse(serviceAccount),
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const androidPublisher = google.androidpublisher({
      version: 'v3',
      auth: await auth.getClient(),
    });

    // Verify the purchase
    const result = await androidPublisher.purchases.subscriptions.get({
      packageName: packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });

    const purchase = result.data;

    // Check if purchase is valid
    if (!purchase) {
      return {
        valid: false,
        reason: 'Purchase not found',
      };
    }

    // Check payment state (0 = payment pending, 1 = payment received)
    if (purchase.paymentState !== 1) {
      return {
        valid: false,
        reason: 'Payment not received',
        paymentState: purchase.paymentState,
      };
    }

    // Check if subscription is active
    const expiryTimeMillis = parseInt(purchase.expiryTimeMillis);
    const now = Date.now();

    if (expiryTimeMillis < now) {
      return {
        valid: false,
        reason: 'Subscription expired',
        expiresDate: new Date(expiryTimeMillis).toISOString(),
      };
    }

    // Check if purchase was cancelled
    if (purchase.cancelReason !== undefined) {
      return {
        valid: false,
        reason: 'Purchase was cancelled',
        cancelReason: purchase.cancelReason,
      };
    }

    return {
      valid: true,
      orderId: purchase.orderId,
      purchaseTime: new Date(parseInt(purchase.startTimeMillis)).toISOString(),
      expiresDate: new Date(expiryTimeMillis).toISOString(),
      autoRenewing: purchase.autoRenewing,
    };
  } catch (error) {
    console.error('Error verifying Google receipt:', error);
    return {
      valid: false,
      reason: 'Error contacting Google Play servers',
      error: error.message,
    };
  }
}

/**
 * Main Cloud Function - Verify receipt
 */
exports.verifyReceipt = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to verify receipt'
    );
  }

  const userId = context.auth.uid;
  const { receipt, productId, purchaseId, platform } = data;

  // Validate input
  if (!receipt || !productId || !platform) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields: receipt, productId, platform'
    );
  }

  console.log(`Verifying ${platform} receipt for user ${userId}, product ${productId}`);

  let verificationResult;

  try {
    // Verify based on platform
    if (platform === 'ios') {
      verificationResult = await verifyAppleReceipt(receipt, productId);
    } else if (platform === 'android') {
      const packageName = 'com.indiralove.app'; // Replace with your package name
      verificationResult = await verifyGoogleReceipt(packageName, productId, receipt);
    } else {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid platform. Must be ios or android'
      );
    }

    // Store verification result in Firestore (for audit trail)
    await db.collection('receipt_verifications').add({
      userId: userId,
      productId: productId,
      purchaseId: purchaseId,
      platform: platform,
      result: verificationResult.valid ? 'success' : 'failed',
      reason: verificationResult.reason || null,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      verificationData: verificationResult,
    });

    // If verification failed, log security event
    if (!verificationResult.valid) {
      await db.collection('security_events').add({
        type: 'failed_receipt_verification',
        userId: userId,
        productId: productId,
        platform: platform,
        reason: verificationResult.reason,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return verificationResult;
  } catch (error) {
    console.error('Receipt verification error:', error);

    // Log error
    await db.collection('receipt_verification_errors').add({
      userId: userId,
      productId: productId,
      platform: platform,
      error: error.message,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    throw new functions.https.HttpsError(
      'internal',
      'Failed to verify receipt',
      error.message
    );
  }
});

/**
 * Scheduled function to check and update expired subscriptions
 * Runs daily at 1 AM
 */
exports.checkExpiredSubscriptions = functions.pubsub
  .schedule('0 1 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('Checking for expired subscriptions...');

    const now = admin.firestore.Timestamp.now();

    // Find users with expired subscriptions
    const expiredSubscriptions = await db.collection('users')
      .where('subscriptionActive', '==', true)
      .where('subscriptionExpiryDate', '<=', now)
      .get();

    const batch = db.batch();
    let count = 0;

    expiredSubscriptions.forEach((doc) => {
      batch.update(doc.ref, {
        subscriptionTier: 'free',
        subscriptionActive: false,
        subscriptionExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      count++;
    });

    if (count > 0) {
      await batch.commit();
      console.log(`Updated ${count} expired subscriptions`);
    } else {
      console.log('No expired subscriptions found');
    }

    return null;
  });

/**
 * Webhook handler for App Store Server Notifications
 * Handles subscription lifecycle events
 */
exports.appleWebhook = functions.https.onRequest(async (req, res) => {
  // Verify the request is from Apple (implement signature verification)
  // See: https://developer.apple.com/documentation/appstoreservernotifications

  const notification = req.body;
  console.log('Received Apple notification:', notification);

  // Handle different notification types
  const notificationType = notification.notification_type;

  switch (notificationType) {
    case 'DID_RENEW':
      // Subscription renewed successfully
      console.log('Subscription renewed');
      break;

    case 'CANCEL':
      // Subscription cancelled
      console.log('Subscription cancelled');
      // Update user's subscription status
      break;

    case 'DID_FAIL_TO_RENEW':
      // Subscription failed to renew
      console.log('Subscription failed to renew');
      break;

    case 'REFUND':
      // Purchase was refunded
      console.log('Purchase refunded');
      // Revoke user's subscription
      break;

    default:
      console.log('Unknown notification type:', notificationType);
  }

  res.status(200).send('OK');
});

/**
 * Webhook handler for Google Play Real-time Developer Notifications
 */
exports.googleWebhook = functions.https.onRequest(async (req, res) => {
  const message = req.body.message;

  if (!message) {
    res.status(400).send('No message in request');
    return;
  }

  // Decode the base64 message data
  const data = JSON.parse(Buffer.from(message.data, 'base64').toString());
  console.log('Received Google notification:', data);

  // Handle notification based on type
  if (data.subscriptionNotification) {
    const notification = data.subscriptionNotification;
    const notificationType = notification.notificationType;

    switch (notificationType) {
      case 1: // SUBSCRIPTION_RECOVERED
        console.log('Subscription recovered');
        break;

      case 2: // SUBSCRIPTION_RENEWED
        console.log('Subscription renewed');
        break;

      case 3: // SUBSCRIPTION_CANCELED
        console.log('Subscription cancelled');
        break;

      case 4: // SUBSCRIPTION_PURCHASED
        console.log('New subscription purchased');
        break;

      case 13: // SUBSCRIPTION_EXPIRED
        console.log('Subscription expired');
        break;

      default:
        console.log('Unknown notification type:', notificationType);
    }
  }

  res.status(200).send('OK');
});
