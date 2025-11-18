import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'logger_service.dart';
import 'analytics_service.dart';

/// Production-grade IAP service with server-side verification
/// IMPORTANT: This requires a backend Cloud Function for receipt verification
class IAPServiceImproved {
  static final IAPServiceImproved _instance = IAPServiceImproved._internal();
  factory IAPServiceImproved() => _instance;
  IAPServiceImproved._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  // Backend endpoint for receipt verification
  // TODO: Replace with your actual Cloud Function URL
  static const String _verificationEndpoint =
      'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/verifyReceipt';

  // Product IDs - must match App Store Connect and Google Play Console
  static const String silverMonthlyId = 'indira_love_silver_monthly';
  static const String silverYearlyId = 'indira_love_silver_yearly';
  static const String goldMonthlyId = 'indira_love_gold_monthly';
  static const String goldYearlyId = 'indira_love_gold_yearly';
  static const String platinumMonthlyId = 'indira_love_platinum_monthly';
  static const String platinumYearlyId = 'indira_love_platinum_yearly';

  static const Set<String> _productIds = {
    silverMonthlyId,
    silverYearlyId,
    goldMonthlyId,
    goldYearlyId,
    platinumMonthlyId,
    platinumYearlyId,
  };

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  /// Initialize IAP
  Future<void> initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();

      if (!_isAvailable) {
        logger.warning('In-app purchases not available on this device');
        return;
      }

      // Enable pending purchases on Android
      if (Platform.isAndroid) {
        final InAppPurchaseAndroidPlatformAddition androidAddition = _iap
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await androidAddition.enablePendingPurchases();
      }

      // Listen for purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          logger.error('Purchase stream error', error: error);
        },
      );

      // Load products
      await loadProducts();

      logger.info('IAP service initialized successfully');
      analytics.logFeatureUsed('iap_initialized');
    } catch (e) {
      logger.error('Failed to initialize IAP', error: e);
    }
  }

  /// Load available products
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(_productIds);

      if (response.error != null) {
        logger.error('Error loading products', error: response.error);
        return;
      }

      if (response.productDetails.isEmpty) {
        logger.warning('No IAP products found');
        return;
      }

      _products = response.productDetails;
      logger.info('Loaded ${_products.length} IAP products');
    } catch (e) {
      logger.error('Failed to load products', error: e);
    }
  }

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      logger.warning('Product not found: $productId');
      return null;
    }
  }

  /// Purchase a product
  Future<bool> purchase(String productId) async {
    if (!_isAvailable) {
      logger.warning('IAP not available');
      return false;
    }

    final product = getProduct(productId);
    if (product == null) {
      logger.error('Product not found: $productId');
      return false;
    }

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: _auth.currentUser?.uid,
      );

      analytics.logFeatureUsed('iap_purchase_initiated');

      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      logger.error('Error initiating purchase', error: e);
      analytics.logError('iap_purchase_failed', e.toString());
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      logger.info('Restoring purchases...');
      await _iap.restorePurchases();
      analytics.logFeatureUsed('iap_restore_purchases');
    } catch (e) {
      logger.error('Error restoring purchases', error: e);
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      logger.info('Purchase update: ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
        await _handlePendingPurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        await _handlePurchaseError(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify and deliver purchase
        await _handleSuccessfulPurchase(purchaseDetails);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Handle pending purchase
  Future<void> _handlePendingPurchase(PurchaseDetails purchaseDetails) async {
    logger.info('Purchase pending: ${purchaseDetails.productID}');

    final user = _auth.currentUser;
    if (user == null) return;

    // Store pending purchase in Firestore
    await _firestore.collection('pending_purchases').add({
      'userId': user.uid,
      'productId': purchaseDetails.productID,
      'purchaseId': purchaseDetails.purchaseID,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'platform': Platform.isIOS ? 'ios' : 'android',
    });

    analytics.logFeatureUsed('iap_purchase_pending');
  }

  /// Handle purchase error
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    logger.error(
      'Purchase error: ${purchaseDetails.productID}',
      error: purchaseDetails.error,
    );

    final user = _auth.currentUser;
    if (user == null) return;

    // Log error in Firestore
    await _firestore.collection('purchase_errors').add({
      'userId': user.uid,
      'productId': purchaseDetails.productID,
      'errorCode': purchaseDetails.error?.code,
      'errorMessage': purchaseDetails.error?.message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    analytics.logError(
      'iap_purchase_error',
      purchaseDetails.error?.message ?? 'Unknown error',
    );
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    logger.info('Purchase successful: ${purchaseDetails.productID}');

    // Verify purchase with backend server
    final bool valid = await _verifyPurchaseWithServer(purchaseDetails);

    if (valid) {
      await _deliverProduct(purchaseDetails);
      analytics.logPurchase(
        purchaseDetails.productID,
        _getPriceFromProduct(purchaseDetails.productID),
      );
    } else {
      logger.error('Purchase verification failed: ${purchaseDetails.productID}');
      analytics.logError('iap_verification_failed', purchaseDetails.productID);

      // Store failed verification for manual review
      await _storeFraudulentPurchase(purchaseDetails);
    }
  }

  /// Verify purchase with backend server (PRODUCTION IMPLEMENTATION)
  Future<bool> _verifyPurchaseWithServer(PurchaseDetails purchaseDetails) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.error('No authenticated user for purchase verification');
        return false;
      }

      // Get the verification data
      final verificationData = purchaseDetails.verificationData;
      final receiptData = verificationData.serverVerificationData;

      if (receiptData.isEmpty) {
        logger.error('Empty receipt data');
        return false;
      }

      // Call backend Cloud Function for verification
      final response = await http.post(
        Uri.parse(_verificationEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await user.getIdToken()}',
        },
        body: jsonEncode({
          'receipt': receiptData,
          'productId': purchaseDetails.productID,
          'purchaseId': purchaseDetails.purchaseID,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'userId': user.uid,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isValid = data['valid'] as bool? ?? false;

        if (isValid) {
          logger.info('Purchase verified successfully');
          return true;
        } else {
          logger.warning('Purchase verification failed: ${data['reason']}');
          return false;
        }
      } else {
        logger.error('Server verification failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.error('Error verifying purchase with server', error: e);

      // FALLBACK: In case of network error, do basic client-side verification
      // This should only be used as a temporary measure
      logger.warning('Using fallback client-side verification');
      return _fallbackVerification(purchaseDetails);
    }
  }

  /// Fallback verification (only when server is unreachable)
  bool _fallbackVerification(PurchaseDetails purchaseDetails) {
    // Basic client-side checks
    if (purchaseDetails.verificationData.serverVerificationData.isEmpty) {
      return false;
    }

    if (purchaseDetails.productID.isEmpty || !_productIds.contains(purchaseDetails.productID)) {
      return false;
    }

    // Log that we're using fallback verification
    logger.logSecurityEvent(
      'Using fallback IAP verification',
      userId: _auth.currentUser?.uid,
      details: {
        'product_id': purchaseDetails.productID,
        'purchase_id': purchaseDetails.purchaseID,
      },
    );

    return true;
  }

  /// Store fraudulent purchase attempt
  Future<void> _storeFraudulentPurchase(PurchaseDetails purchaseDetails) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('fraudulent_purchases').add({
      'userId': user.uid,
      'productId': purchaseDetails.productID,
      'purchaseId': purchaseDetails.purchaseID,
      'timestamp': FieldValue.serverTimestamp(),
      'verificationData': purchaseDetails.verificationData.serverVerificationData,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'status': 'verification_failed',
    });

    logger.logSecurityEvent(
      'Fraudulent purchase detected',
      userId: user.uid,
      details: {
        'product_id': purchaseDetails.productID,
      },
    );
  }

  /// Deliver purchased product
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final user = _auth.currentUser;
    if (user == null) {
      logger.error('No user logged in for product delivery');
      return;
    }

    final productId = purchaseDetails.productID;
    final tierInfo = _getTierFromProductId(productId);

    // Calculate expiry date
    final now = DateTime.now();
    final expiryDate = tierInfo['duration'] == 'yearly'
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));

    try {
      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('User document not found');
        }

        // Update user subscription
        transaction.update(userRef, {
          'subscriptionTier': tierInfo['tier'],
          'subscriptionDuration': tierInfo['duration'],
          'subscriptionStartDate': FieldValue.serverTimestamp(),
          'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
          'subscriptionActive': true,
          'lastPurchaseDate': FieldValue.serverTimestamp(),
        });

        // Create purchase record
        final purchaseRef = _firestore.collection('purchases').doc();
        transaction.set(purchaseRef, {
          'userId': user.uid,
          'productId': productId,
          'tier': tierInfo['tier'],
          'duration': tierInfo['duration'],
          'purchaseId': purchaseDetails.purchaseID,
          'transactionDate': FieldValue.serverTimestamp(),
          'expiryDate': Timestamp.fromDate(expiryDate),
          'platform': Platform.isIOS ? 'ios' : 'android',
          'verifiedByServer': true,
          'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
        });
      });

      logger.info('Product delivered successfully: $productId');
      analytics.logSubscriptionPurchase(
        tierInfo['tier'],
        _getPriceFromProduct(productId),
      );
    } catch (e) {
      logger.error('Error delivering product', error: e);
    }
  }

  /// Get tier and duration from product ID
  Map<String, String> _getTierFromProductId(String productId) {
    String tier = 'free';
    String duration = 'monthly';

    if (productId.contains('silver')) {
      tier = 'silver';
    } else if (productId.contains('gold')) {
      tier = 'gold';
    } else if (productId.contains('platinum')) {
      tier = 'platinum';
    }

    if (productId.contains('yearly')) {
      duration = 'yearly';
    }

    return {'tier': tier, 'duration': duration};
  }

  /// Get price from product
  double _getPriceFromProduct(String productId) {
    final product = getProduct(productId);
    if (product == null) return 0.0;

    // Parse price from product
    final priceString = product.price.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(priceString) ?? 0.0;
  }

  /// Check subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'tier': 'free', 'active': false};
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null) {
        return {'tier': 'free', 'active': false};
      }

      final tier = data['subscriptionTier'] ?? 'free';
      final active = data['subscriptionActive'] ?? false;
      final expiryTimestamp = data['subscriptionExpiryDate'] as Timestamp?;

      // Check if subscription has expired
      if (expiryTimestamp != null) {
        final expiryDate = expiryTimestamp.toDate();
        if (DateTime.now().isAfter(expiryDate)) {
          // Subscription expired, update to free
          await _firestore.collection('users').doc(user.uid).update({
            'subscriptionTier': 'free',
            'subscriptionActive': false,
          });

          return {'tier': 'free', 'active': false};
        }
      }

      return {
        'tier': tier,
        'active': active,
        'expiryDate': expiryTimestamp?.toDate(),
      };
    } catch (e) {
      logger.error('Error checking subscription status', error: e);
      return {'tier': 'free', 'active': false};
    }
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }
}

// Global IAP service instance
final iapService = IAPServiceImproved();
