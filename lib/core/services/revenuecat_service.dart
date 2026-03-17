import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/models/subscription_tier.dart';

/// RevenueCat service for managing subscriptions and entitlements.
/// Supports two paid tiers: Silver (indira_silver) and Gold (indira_gold).
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // API key loaded from .env — never hardcode production keys
  static String get _apiKey => dotenv.env['REVENUECAT_API_KEY'] ?? '';

  // Entitlement identifiers (configured in RevenueCat dashboard)
  static const String silverEntitlementId = 'indira_silver';
  static const String goldEntitlementId = 'indira_gold';

  // Product identifiers (packages in RevenueCat offerings)
  static const String silverMonthlyId = 'silver_monthly';
  static const String goldMonthlyId = 'gold_monthly';

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize RevenueCat SDK.
  /// Call this after Firebase Auth is ready.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (_apiKey.isEmpty) {
        logger.error('REVENUECAT_API_KEY not set in .env');
        return;
      }

      await Purchases.setLogLevel(LogLevel.error);

      final configuration = PurchasesConfiguration(_apiKey);

      // If user is already logged in, set their app user ID
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        configuration.appUserID = firebaseUser.uid;
      }

      await Purchases.configure(configuration);
      _initialized = true;

      logger.info('RevenueCat initialized successfully');
    } catch (e) {
      logger.error('RevenueCat initialization failed', error: e);
    }
  }

  /// Log in the RevenueCat user when Firebase Auth user logs in.
  Future<void> login(String firebaseUid) async {
    if (!_initialized) await initialize();

    try {
      final result = await Purchases.logIn(firebaseUid);
      logger.info('RevenueCat login: created=${result.created}');

      await _syncEntitlementsToFirestore(result.customerInfo);
    } catch (e) {
      logger.error('RevenueCat login failed', error: e);
    }
  }

  /// Log out the RevenueCat user (resets to anonymous).
  Future<void> logout() async {
    if (!_initialized) return;

    try {
      await Purchases.logOut();
      logger.info('RevenueCat logged out');
    } catch (e) {
      logger.error('RevenueCat logout failed', error: e);
    }
  }

  /// Get the user's current subscription tier from RevenueCat entitlements.
  Future<SubscriptionTier> getSubscriptionTier() async {
    if (!_initialized) return SubscriptionTier.free;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _tierFromCustomerInfo(customerInfo);
    } catch (e) {
      logger.error('Error checking subscription tier', error: e);
      return SubscriptionTier.free;
    }
  }

  /// Check if user has any paid subscription (Silver or Gold).
  Future<bool> isSubscribed() async {
    final tier = await getSubscriptionTier();
    return tier != SubscriptionTier.free;
  }

  /// Get current customer info with all entitlements.
  Future<CustomerInfo?> getCustomerInfo() async {
    if (!_initialized) return null;

    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      logger.error('Error getting customer info', error: e);
      return null;
    }
  }

  /// Get available offerings (products configured in RevenueCat dashboard).
  Future<Offerings?> getOfferings() async {
    if (!_initialized) return null;

    try {
      return await Purchases.getOfferings();
    } catch (e) {
      logger.error('Error getting offerings', error: e);
      return null;
    }
  }

  /// Purchase a package from an offering.
  /// Returns the resulting subscription tier after purchase.
  Future<SubscriptionTier> purchasePackage(Package package) async {
    if (!_initialized) return SubscriptionTier.free;

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = result.customerInfo;
      final tier = _tierFromCustomerInfo(customerInfo);

      if (tier != SubscriptionTier.free) {
        await _syncEntitlementsToFirestore(customerInfo);
        logger.info('Purchase successful - tier: $tier');
      }

      return tier;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        logger.info('Purchase cancelled by user');
      } else {
        logger.error('Purchase error: $errorCode', error: e);
      }
      return SubscriptionTier.free;
    }
  }

  /// Restore purchases (e.g., after reinstalling the app).
  /// Returns the resulting subscription tier.
  Future<SubscriptionTier> restorePurchases() async {
    if (!_initialized) return SubscriptionTier.free;

    try {
      final customerInfo = await Purchases.restorePurchases();
      final tier = _tierFromCustomerInfo(customerInfo);

      await _syncEntitlementsToFirestore(customerInfo);
      logger.info('Restore complete - tier: $tier');

      return tier;
    } catch (e) {
      logger.error('Restore purchases failed', error: e);
      return SubscriptionTier.free;
    }
  }

  /// Listen for customer info changes (entitlement updates in real-time).
  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    if (!_initialized) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Determine subscription tier from CustomerInfo entitlements.
  SubscriptionTier _tierFromCustomerInfo(CustomerInfo customerInfo) {
    if (customerInfo.entitlements.active.containsKey(goldEntitlementId)) {
      return SubscriptionTier.gold;
    } else if (customerInfo.entitlements.active.containsKey(silverEntitlementId)) {
      return SubscriptionTier.silver;
    }
    return SubscriptionTier.free;
  }

  /// Sync RevenueCat entitlements to Firestore for server-side checks.
  Future<void> _syncEntitlementsToFirestore(CustomerInfo customerInfo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final isGold = customerInfo.entitlements.active.containsKey(goldEntitlementId);
      final isSilver = customerInfo.entitlements.active.containsKey(silverEntitlementId);

      String tier = 'free';
      if (isGold) {
        tier = 'gold';
      } else if (isSilver) {
        tier = 'silver';
      }

      final activeEntitlement = isGold
          ? customerInfo.entitlements.active[goldEntitlementId]
          : isSilver
              ? customerInfo.entitlements.active[silverEntitlementId]
              : null;

      // Get the user's current tier to detect upgrades/downgrades
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final previousTier = userDoc.data()?['subscriptionTier'] as String? ?? 'free';

      final Map<String, dynamic> updateData = {
        'subscriptionTier': tier,
        'subscriptionActive': isGold || isSilver,
        'lastSubscriptionSync': FieldValue.serverTimestamp(),
      };

      if (activeEntitlement != null) {
        if (activeEntitlement.expirationDate != null) {
          updateData['subscriptionExpiryDate'] = Timestamp.fromDate(
            DateTime.parse(activeEntitlement.expirationDate!),
          );
        }
        updateData['subscriptionProductId'] = activeEntitlement.productIdentifier;
      }

      // Grant subscription benefits when tier changes
      if (tier != previousTier) {
        final subscriptionTier = isGold
            ? SubscriptionTier.gold
            : isSilver
                ? SubscriptionTier.silver
                : SubscriptionTier.free;
        final limits = SubscriptionLimits.fromTier(subscriptionTier);

        // Set call minutes based on plan
        updateData['subscriptionVideoMinutes'] = limits.callMinutesPerMonth > 0
            ? limits.callMinutesPerMonth
            : 0;

        logger.info('Tier changed $previousTier -> $tier, granting ${limits.callMinutesPerMonth} call minutes');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updateData);

      logger.info('Synced entitlements to Firestore: tier=$tier');
    } catch (e) {
      logger.error('Error syncing entitlements to Firestore', error: e);
    }
  }
}

/// Global singleton instance
final revenueCatService = RevenueCatService();
