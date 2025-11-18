const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');
const crypto = require('crypto');

// Initialize Google Play API
const androidPublisher = google.androidpublisher('v3');

// Apple App Store Verification
const verifyAppleReceipt = async (receipt, isProduction = false) => {
  const endpoint = isProduction
    ? 'https://buy.itunes.apple.com/verifyReceipt'
    : 'https://sandbox.itunes.apple.com/verifyReceipt';

  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receipt,
        'password': functions.config().apple.shared_secret,
      }),
    });

    const data = await response.json();

    if (data.status === 0) {
      // Valid receipt
      const latestReceipt = data.latest_receipt_info?.[0] || data.receipt;
      return {
        valid: true,
        productId: latestReceipt.product_id,
        transactionId: latestReceipt.transaction_id,
        expiresAt: latestReceipt.expires_date_ms
          ? new Date(parseInt(latestReceipt.expires_date_ms))
          : null,
        originalTransactionId: latestReceipt.original_transaction_id,
      };
    } else if (data.status === 21007 && isProduction) {
      // Receipt is from sandbox, retry with sandbox endpoint
      return verifyAppleReceipt(receipt, false);
    }

    return { valid: false, error: `Apple verification failed: ${data.status}` };
  } catch (error) {
    console.error('Apple receipt verification error:', error);
    return { valid: false, error: error.message };
  }
};

// Google Play Verification
const verifyGooglePurchase = async (packageName, productId, purchaseToken) => {
  try {
    // Authenticate with Google Play API
    const auth = new google.auth.GoogleAuth({
      keyFile: './service-account.json', // Your service account key
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const authClient = await auth.getClient();
    google.options({ auth: authClient });

    // Verify subscription
    const response = await androidPublisher.purchases.subscriptions.get({
      packageName,
      subscriptionId: productId,
      token: purchaseToken,
    });

    if (response.data) {
      const purchase = response.data;
      return {
        valid: true,
        productId,
        orderId: purchase.orderId,
        expiresAt: purchase.expiryTimeMillis
          ? new Date(parseInt(purchase.expiryTimeMillis))
          : null,
        autoRenewing: purchase.autoRenewing,
        cancelReason: purchase.cancelReason,
      };
    }

    return { valid: false, error: 'Purchase not found' };
  } catch (error) {
    console.error('Google purchase verification error:', error);

    // Try verifying as a one-time product if subscription fails
    try {
      const response = await androidPublisher.purchases.products.get({
        packageName,
        productId,
        token: purchaseToken,
      });

      if (response.data && response.data.purchaseState === 0) {
        return {
          valid: true,
          productId,
          orderId: response.data.orderId,
          isOneTime: true,
        };
      }
    } catch (productError) {
      console.error('Product verification also failed:', productError);
    }

    return { valid: false, error: error.message };
  }
};

// Main verification function
exports.verifyPurchase = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { platform, receipt, productId, purchaseToken, packageName, orderId } = data;

  if (!platform || (!receipt && !purchaseToken)) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters');
  }

  let verificationResult;

  try {
    // Verify based on platform
    if (platform === 'ios') {
      verificationResult = await verifyAppleReceipt(receipt, true);
    } else if (platform === 'android') {
      verificationResult = await verifyGooglePurchase(
        packageName || 'com.indiralove.dating',
        productId,
        purchaseToken
      );
    } else {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid platform');
    }

    if (!verificationResult.valid) {
      // Log failed verification attempt
      await admin.firestore().collection('failed_verifications').add({
        userId: context.auth.uid,
        platform,
        productId,
        orderId,
        error: verificationResult.error,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      throw new functions.https.HttpsError('invalid-argument', 'Purchase verification failed');
    }

    // Generate secure purchase ID
    const purchaseId = crypto
      .createHash('sha256')
      .update(`${context.auth.uid}_${verificationResult.transactionId || verificationResult.orderId}_${Date.now()}`)
      .digest('hex')
      .substring(0, 20);

    // Store verified purchase
    const purchaseData = {
      purchaseId,
      userId: context.auth.uid,
      platform,
      productId: verificationResult.productId,
      orderId: verificationResult.orderId || verificationResult.transactionId,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: verificationResult.expiresAt,
      autoRenewing: verificationResult.autoRenewing || false,
      isValid: true,
      isConsumed: false,
    };

    await admin.firestore()
      .collection('verified_purchases')
      .doc(purchaseId)
      .set(purchaseData);

    // Update user subscription status
    const subscriptionTier = getSubscriptionTier(productId);
    if (subscriptionTier) {
      await admin.firestore()
        .collection('users')
        .doc(context.auth.uid)
        .update({
          subscriptionTier,
          subscriptionExpiry: verificationResult.expiresAt,
          lastPurchaseId: purchaseId,
          lastPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
        });

      // Log subscription update
      await admin.firestore().collection('audit_logs').add({
        action: 'subscription_updated',
        userId: context.auth.uid,
        subscriptionTier,
        purchaseId,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return {
      success: true,
      purchaseId,
      subscriptionTier,
      expiresAt: verificationResult.expiresAt,
    };
  } catch (error) {
    console.error('Purchase verification error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Helper function to map product IDs to subscription tiers
function getSubscriptionTier(productId) {
  const tierMap = {
    'com.indiralove.silver.monthly': 'silver',
    'com.indiralove.silver.yearly': 'silver',
    'com.indiralove.gold.monthly': 'gold',
    'com.indiralove.gold.yearly': 'gold',
    'silver_monthly': 'silver',
    'silver_yearly': 'silver',
    'gold_monthly': 'gold',
    'gold_yearly': 'gold',
  };

  return tierMap[productId] || null;
}

// Webhook for handling subscription renewals/cancellations (Google Play)
exports.googlePlayWebhook = functions.https.onRequest(async (req, res) => {
  const { message } = req.body;

  if (!message) {
    res.status(400).send('Invalid request');
    return;
  }

  try {
    // Decode the Pub/Sub message
    const decodedData = Buffer.from(message.data, 'base64').toString();
    const notification = JSON.parse(decodedData);

    // Handle different notification types
    switch (notification.notificationType) {
      case 1: // SUBSCRIPTION_RECOVERED
      case 2: // SUBSCRIPTION_RENEWED
        await handleSubscriptionRenewal(notification);
        break;
      case 3: // SUBSCRIPTION_CANCELED
      case 4: // SUBSCRIPTION_PURCHASED
      case 10: // SUBSCRIPTION_EXPIRED
        await handleSubscriptionCancellation(notification);
        break;
      default:
        console.log('Unhandled notification type:', notification.notificationType);
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('Webhook processing error:', error);
    res.status(500).send('Internal error');
  }
});

// Helper functions for subscription management
async function handleSubscriptionRenewal(notification) {
  const { subscriptionId, purchaseToken } = notification;

  // Verify and update subscription
  const verification = await verifyGooglePurchase(
    notification.packageName,
    subscriptionId,
    purchaseToken
  );

  if (verification.valid) {
    // Find user by purchase token
    const purchaseSnapshot = await admin.firestore()
      .collection('verified_purchases')
      .where('orderId', '==', verification.orderId)
      .limit(1)
      .get();

    if (!purchaseSnapshot.empty) {
      const purchase = purchaseSnapshot.docs[0];
      const userId = purchase.data().userId;

      // Update user subscription
      await admin.firestore()
        .collection('users')
        .doc(userId)
        .update({
          subscriptionExpiry: verification.expiresAt,
          subscriptionAutoRenewing: verification.autoRenewing,
        });
    }
  }
}

async function handleSubscriptionCancellation(notification) {
  const { subscriptionId, purchaseToken } = notification;

  // Find the purchase record
  const purchaseSnapshot = await admin.firestore()
    .collection('verified_purchases')
    .where('productId', '==', subscriptionId)
    .where('platform', '==', 'android')
    .limit(1)
    .get();

  if (!purchaseSnapshot.empty) {
    const purchase = purchaseSnapshot.docs[0];
    const userId = purchase.data().userId;

    // Update user subscription status
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .update({
        subscriptionAutoRenewing: false,
        subscriptionCancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Log cancellation
    await admin.firestore().collection('audit_logs').add({
      action: 'subscription_cancelled',
      userId,
      subscriptionId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
}

// Apple App Store Server Notifications
exports.appleWebhook = functions.https.onRequest(async (req, res) => {
  const { notification_type, latest_receipt_info } = req.body;

  try {
    switch (notification_type) {
      case 'RENEWAL':
      case 'INTERACTIVE_RENEWAL':
        await handleAppleRenewal(latest_receipt_info);
        break;
      case 'CANCEL':
      case 'REFUND':
        await handleAppleCancellation(latest_receipt_info);
        break;
      default:
        console.log('Unhandled Apple notification:', notification_type);
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('Apple webhook error:', error);
    res.status(500).send('Internal error');
  }
});

async function handleAppleRenewal(receiptInfo) {
  // Implementation similar to Google Play renewal
  // Find user by original_transaction_id and update subscription
}

async function handleAppleCancellation(receiptInfo) {
  // Implementation similar to Google Play cancellation
  // Find user by original_transaction_id and update subscription status
}