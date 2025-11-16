import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  // Product IDs - these should match your App Store Connect and Google Play Console
  static const String silverMonthlyId = 'indira_love_silver_monthly';
  static const String silverYearlyId = 'indira_love_silver_yearly';
  static const String goldMonthlyId = 'indira_love_gold_monthly';
  static const String goldYearlyId = 'indira_love_gold_yearly';

  static const Set<String> _productIds = {
    silverMonthlyId,
    silverYearlyId,
    goldMonthlyId,
    goldYearlyId,
  };

  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;

  /// Initialize IAP
  Future<void> initialize() async {
    // Check if IAP is available
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      print('In-app purchases not available');
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
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Load products
    await loadProducts();

    print('IAP initialized successfully');
  }

  /// Load available products
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final ProductDetailsResponse response = await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      print('Error loading products: ${response.error}');
      return;
    }

    if (response.productDetails.isEmpty) {
      print('No products found');
      return;
    }

    _products = response.productDetails;
    print('Loaded ${_products.length} products');
  }

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Purchase a product
  Future<bool> purchase(String productId) async {
    if (!_isAvailable) {
      print('IAP not available');
      return false;
    }

    final product = getProduct(productId);
    if (product == null) {
      print('Product not found: $productId');
      return false;
    }

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Error purchasing: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      print('Error restoring purchases: $e');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      print('Purchase status: ${purchaseDetails.status}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
        print('Purchase pending');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        print('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify and deliver purchase
        final bool valid = await _verifyPurchase(purchaseDetails);
        if (valid) {
          await _deliverProduct(purchaseDetails);
        }
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }
    }
  }

  /// Verify purchase (implement server-side verification in production)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, you should verify purchases with your backend server
    // For now, we'll do basic client-side verification
    return purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored;
  }

  /// Deliver purchased product
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('User not logged in');
      return;
    }

    final productId = purchaseDetails.productID;
    String tier = 'free';
    String duration = 'monthly';

    // Determine tier and duration from product ID
    if (productId.contains('silver')) {
      tier = 'silver';
    } else if (productId.contains('gold')) {
      tier = 'gold';
    }

    if (productId.contains('yearly')) {
      duration = 'yearly';
    }

    // Calculate expiry date
    final now = DateTime.now();
    final expiryDate = duration == 'yearly'
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));

    // Update user subscription in Firestore
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'subscriptionTier': tier,
        'subscriptionDuration': duration,
        'subscriptionStartDate': FieldValue.serverTimestamp(),
        'subscriptionExpiryDate': Timestamp.fromDate(expiryDate),
        'subscriptionActive': true,
      });

      // Save purchase record
      await _firestore.collection('purchases').add({
        'userId': user.uid,
        'productId': productId,
        'tier': tier,
        'duration': duration,
        'purchaseId': purchaseDetails.purchaseID,
        'transactionDate': FieldValue.serverTimestamp(),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'verificationData': purchaseDetails.verificationData.serverVerificationData,
      });

      print('Product delivered: $productId');
    } catch (e) {
      print('Error delivering product: $e');
    }
  }

  /// Check subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'tier': 'free',
        'active': false,
      };
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data == null) {
        return {
          'tier': 'free',
          'active': false,
        };
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

          return {
            'tier': 'free',
            'active': false,
          };
        }
      }

      return {
        'tier': tier,
        'active': active,
        'expiryDate': expiryTimestamp?.toDate(),
      };
    } catch (e) {
      print('Error checking subscription: $e');
      return {
        'tier': 'free',
        'active': false,
      };
    }
  }

  /// Cancel subscription (only marks as cancelled, doesn't refund)
  Future<void> cancelSubscription() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'subscriptionActive': false,
      'subscriptionCancelledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Dispose
  void dispose() {
    _subscription?.cancel();
  }
}
