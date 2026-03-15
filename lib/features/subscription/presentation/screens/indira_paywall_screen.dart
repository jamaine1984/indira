import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:indira_love/core/services/revenuecat_service.dart';
import 'package:indira_love/core/providers/revenuecat_provider.dart';
import 'package:indira_love/core/models/subscription_tier.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';

/// Presents the RevenueCat-managed paywall.
/// This uses the paywall you configure in the RevenueCat dashboard.
class RevenueCatPaywallScreen extends StatelessWidget {
  const RevenueCatPaywallScreen({super.key});

  /// Show the RevenueCat native paywall as a bottom sheet.
  /// Returns true if the user subscribed.
  static Future<bool> show(BuildContext context) async {
    try {
      final paywallResult = await RevenueCatUI.presentPaywall();
      return paywallResult == PaywallResult.purchased ||
          paywallResult == PaywallResult.restored;
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Could not load paywall. Please try again.');
      }
      return false;
    }
  }

  /// Show the paywall only if user doesn't have the given entitlement.
  static Future<bool> showIfNeeded(
    BuildContext context,
    String entitlementId,
  ) async {
    try {
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded(
        entitlementId,
      );
      return paywallResult == PaywallResult.purchased ||
          paywallResult == PaywallResult.restored;
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Could not load paywall. Please try again.');
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const PaywallView();
  }
}

/// Custom Indira-branded paywall that fetches offerings from RevenueCat
/// and presents them with the app's visual style.
/// Shows both Silver and Gold packages.
class IndiraPaywallScreen extends ConsumerStatefulWidget {
  const IndiraPaywallScreen({super.key});

  @override
  ConsumerState<IndiraPaywallScreen> createState() =>
      _IndiraPaywallScreenState();
}

class _IndiraPaywallScreenState extends ConsumerState<IndiraPaywallScreen> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upgrade Your Plan',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: offeringsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.white70, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Unable to load subscription options.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                ref.invalidate(offeringsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (offerings) {
                    if (offerings == null ||
                        offerings.current == null ||
                        offerings.current!.availablePackages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No subscription plans available right now.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    final packages = offerings.current!.availablePackages;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Pro badge
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.workspace_premium,
                              color: AppTheme.accentGold,
                              size: 64,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Choose Your Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Unlock premium features with Silver or Gold',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Packages
                          ...packages.map((pkg) => _buildPackageCard(pkg)),
                          const SizedBox(height: 16),

                          // Restore purchases
                          TextButton(
                            onPressed: _purchasing ? null : _restorePurchases,
                            child: const Text(
                              'Restore Purchases',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Terms
                          const Text(
                            'Subscription auto-renews. Cancel anytime in your app store settings.',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final product = package.storeProduct;
    final isGold = product.identifier.contains('gold');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _purchasing ? null : () => _purchase(package),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isGold ? AppTheme.accentGold : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: isGold
                ? Border.all(color: Colors.amber.shade700, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: isGold ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isGold ? Colors.white : AppTheme.textCharcoal,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isGold
                              ? Colors.white70
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isGold
                      ? const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        )
                      : const LinearGradient(
                          colors: [AppTheme.primaryRose, AppTheme.secondaryPlum],
                        ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _purchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        product.priceString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _purchase(Package package) async {
    setState(() => _purchasing = true);

    try {
      final tier = await revenueCatService.purchasePackage(package);
      if (mounted) {
        if (tier != SubscriptionTier.free) {
          ref.invalidate(subscriptionStateProvider);
          final tierName = tier == SubscriptionTier.gold ? 'Gold' : 'Silver';
          AppSnackBar.success(context, 'Welcome to Indira $tierName!');
          Navigator.pop(context, true);
        }
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _purchasing = true);

    try {
      final tier = await revenueCatService.restorePurchases();
      if (mounted) {
        if (tier != SubscriptionTier.free) {
          ref.invalidate(subscriptionStateProvider);
          final tierName = tier == SubscriptionTier.gold ? 'Gold' : 'Silver';
          AppSnackBar.success(context, 'Restored! Welcome back to Indira $tierName.');
          Navigator.pop(context, true);
        } else {
          AppSnackBar.info(context, 'No previous purchases found.');
        }
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}
