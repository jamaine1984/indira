import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/subscription_tier.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';
import 'package:indira_love/core/providers/revenuecat_provider.dart';
import 'package:indira_love/core/services/revenuecat_service.dart';
import 'package:indira_love/features/subscription/presentation/screens/customer_center_screen.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _purchasing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final subscriptionState = ref.watch(subscriptionStateProvider);
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
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.subscription,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Manage subscription button (Customer Center)
                    subscriptionState.maybeWhen(
                      data: (tier) => tier != SubscriptionTier.free
                          ? IconButton(
                              onPressed: () =>
                                  CustomerCenterScreen.show(context),
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                              tooltip: 'Manage Subscription',
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Plans
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Active subscription banner
                      subscriptionState.maybeWhen(
                        data: (tier) => tier != SubscriptionTier.free
                            ? _buildActiveBanner(context, tier)
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),

                      // Header Text
                      Text(
                        l10n.upgradeToPremium,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose the plan that works best for you',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Free Plan
                      _buildPlanCard(
                        context,
                        SubscriptionPlan.freePlan,
                        false,
                        offeringsAsync,
                        subscriptionState,
                      ),
                      const SizedBox(height: 16),

                      // Silver Plan
                      _buildPlanCard(
                        context,
                        SubscriptionPlan.silverPlan,
                        false,
                        offeringsAsync,
                        subscriptionState,
                      ),
                      const SizedBox(height: 16),

                      // Gold Plan (Popular)
                      _buildPlanCard(
                        context,
                        SubscriptionPlan.goldPlan,
                        true,
                        offeringsAsync,
                        subscriptionState,
                      ),
                      const SizedBox(height: 32),

                      // Comparison Info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Plan Comparison',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildComparisonRow('Daily Messages', '3', '25', 'Unlimited'),
                            _buildComparisonRow('Daily Likes', '3', '10', 'Unlimited'),
                            _buildComparisonRow('Profile Boosts', '1 free', '1/day', 'Unlimited'),
                            _buildComparisonRow('Call Minutes', 'None', '45/mo', '600/mo'),
                            _buildComparisonRow('Gifts', 'Limited', 'Limited', 'Unlimited'),
                            _buildComparisonRow('Ads', '3 to refill', '3 to refill', 'No ads'),
                            _buildComparisonRow('See Who Liked You', '\u2717', '\u2713', '\u2713'),
                            _buildComparisonRow('Priority Matching', '\u2717', '\u2713', '\u2713'),
                            _buildComparisonRow('Advanced Filters', '\u2717', '\u2717', '\u2713'),
                          ],
                        ),
                      ),

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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBanner(BuildContext context, SubscriptionTier tier) {
    final tierName = tier == SubscriptionTier.gold ? 'Gold' : 'Silver';
    final bannerColor = tier == SubscriptionTier.gold
        ? AppTheme.accentGold
        : Colors.grey.shade400;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: bannerColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Indira $tierName Active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have access to $tierName features',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => CustomerCenterScreen.show(context),
            child: Text(
              'Manage',
              style: TextStyle(color: bannerColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    bool isPopular,
    AsyncValue<dynamic> offeringsAsync,
    AsyncValue<SubscriptionTier> subscriptionState,
  ) {
    Color cardColor;
    Color accentColor;

    switch (plan.tier) {
      case SubscriptionTier.free:
        cardColor = Colors.white;
        accentColor = AppTheme.primaryRose;
        break;
      case SubscriptionTier.silver:
        cardColor = Colors.white;
        accentColor = Colors.grey.shade600;
        break;
      case SubscriptionTier.gold:
        cardColor = AppTheme.accentGold;
        accentColor = Colors.amber.shade700;
        break;
    }

    // Determine if this is the user's current plan
    final currentTier = subscriptionState.valueOrNull ?? SubscriptionTier.free;
    final isCurrentPlan = currentTier == plan.tier;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isPopular ? Border.all(color: accentColor, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Popular Badge
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Plan Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        color: plan.tier == SubscriptionTier.gold
                            ? Colors.white
                            : AppTheme.textCharcoal,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.tier != SubscriptionTier.free)
                      Icon(
                        Icons.workspace_premium,
                        color: accentColor,
                        size: 32,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    plan.priceDisplay,
                    style: TextStyle(
                      color: plan.tier == SubscriptionTier.gold
                          ? Colors.white
                          : AppTheme.textCharcoal,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Features
                ...plan.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            color: plan.tier == SubscriptionTier.gold
                                ? Colors.white
                                : AppTheme.textCharcoal,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 20),

                // Subscribe Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_purchasing || isCurrentPlan)
                        ? null
                        : () => _handleSubscribe(plan.tier, offeringsAsync),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? Colors.grey
                          : accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                            isCurrentPlan
                                ? AppLocalizations.of(context).currentPlan
                                : plan.tier == SubscriptionTier.free
                                    ? 'Downgrade'
                                    : 'Subscribe',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String feature, String free, String silver, String gold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              free,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              silver,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              gold,
              style: const TextStyle(
                color: AppTheme.accentGold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe(SubscriptionTier tier, AsyncValue<dynamic> offeringsAsync) {
    if (tier == SubscriptionTier.free) {
      // Free = manage/cancel via Customer Center
      CustomerCenterScreen.show(context);
      return;
    }

    final offerings = offeringsAsync.valueOrNull;
    if (offerings == null || offerings.current == null) {
      AppSnackBar.error(context, 'Unable to load plans. Please try again.');
      return;
    }

    // Find the matching package by identifier
    final targetId = tier == SubscriptionTier.silver
        ? RevenueCatService.silverMonthlyId
        : RevenueCatService.goldMonthlyId;

    final packages = offerings.current!.availablePackages;
    final package = packages.cast<dynamic>().firstWhere(
      (pkg) => pkg.storeProduct.identifier == targetId,
      orElse: () => null,
    );

    if (package != null) {
      _purchasePackage(package);
    } else {
      // Fallback: if exact ID not found, try matching by identifier substring
      final fallback = packages.cast<dynamic>().firstWhere(
        (pkg) => pkg.storeProduct.identifier.toString().contains(
          tier == SubscriptionTier.silver ? 'silver' : 'gold',
        ),
        orElse: () => null,
      );

      if (fallback != null) {
        _purchasePackage(fallback);
      } else {
        AppSnackBar.error(context, 'Plan not available. Please try again later.');
      }
    }
  }

  Future<void> _purchasePackage(dynamic package) async {
    setState(() => _purchasing = true);

    try {
      final tier = await revenueCatService.purchasePackage(package);
      if (mounted) {
        if (tier != SubscriptionTier.free) {
          ref.invalidate(subscriptionStateProvider);
          final tierName = tier == SubscriptionTier.gold ? 'Gold' : 'Silver';
          AppSnackBar.success(context, 'Welcome to Indira $tierName!');
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
        } else {
          AppSnackBar.info(context, 'No previous purchases found.');
        }
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }
}
