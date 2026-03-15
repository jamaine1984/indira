import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:indira_love/core/services/revenuecat_service.dart';
import 'package:indira_love/core/models/subscription_tier.dart';

/// Provider that exposes the user's current subscription tier.
final subscriptionTierProvider = FutureProvider<SubscriptionTier>((ref) async {
  return revenueCatService.getSubscriptionTier();
});

/// Provider that exposes the current RevenueCat customer info.
final customerInfoProvider = FutureProvider<CustomerInfo?>((ref) async {
  return revenueCatService.getCustomerInfo();
});

/// Provider that exposes available RevenueCat offerings.
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return revenueCatService.getOfferings();
});

/// StateNotifier that manages subscription tier and listens for changes.
class SubscriptionNotifier extends StateNotifier<AsyncValue<SubscriptionTier>> {
  SubscriptionNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _checkStatus();
    revenueCatService.addCustomerInfoListener(_onCustomerInfoUpdated);
  }

  Future<void> _checkStatus() async {
    try {
      final tier = await revenueCatService.getSubscriptionTier();
      if (mounted) {
        state = AsyncValue.data(tier);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    SubscriptionTier tier = SubscriptionTier.free;
    if (info.entitlements.active.containsKey(RevenueCatService.goldEntitlementId)) {
      tier = SubscriptionTier.gold;
    } else if (info.entitlements.active.containsKey(RevenueCatService.silverEntitlementId)) {
      tier = SubscriptionTier.silver;
    }
    if (mounted) {
      state = AsyncValue.data(tier);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _checkStatus();
  }
}

/// Auto-updating provider that listens to RevenueCat customer info changes.
/// Emits the current SubscriptionTier (free, silver, or gold).
final subscriptionStateProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionTier>>((ref) {
  return SubscriptionNotifier();
});
