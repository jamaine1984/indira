import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/subscription_tier.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      'Choose Your Plan',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                      // Header Text
                      const Text(
                        'Unlock Your Perfect Match',
                        style: TextStyle(
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
                      ),
                      const SizedBox(height: 16),

                      // Silver Plan
                      _buildPlanCard(
                        context,
                        SubscriptionPlan.silverPlan,
                        false,
                      ),
                      const SizedBox(height: 16),

                      // Gold Plan (Popular)
                      _buildPlanCard(
                        context,
                        SubscriptionPlan.goldPlan,
                        true,
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
                            _buildComparisonRow('Profile Boosts', 'None', '1/day', 'Unlimited'),
                            _buildComparisonRow('Gifts', 'Limited', 'Limited', 'Unlimited'),
                            _buildComparisonRow('Ads', '3 to refill', '3 to refill', 'No ads'),
                            _buildComparisonRow('See Who Liked You', '✗', '✓', '✓'),
                            _buildComparisonRow('Priority Matching', '✗', '✓', '✓'),
                            _buildComparisonRow('Advanced Filters', '✗', '✗', '✓'),
                          ],
                        ),
                      ),
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

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan, bool isPopular) {
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
                '⭐ MOST POPULAR',
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
                    onPressed: () {
                      if (plan.tier == SubscriptionTier.free) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('You are on the Free plan')),
                        );
                      } else {
                        _showSubscribeDialog(context, plan);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.tier == SubscriptionTier.free
                          ? Colors.grey
                          : accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      plan.tier == SubscriptionTier.free
                          ? 'Current Plan'
                          : 'Subscribe Now',
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

  void _showSubscribeDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscribe to ${plan.name}?'),
        content: Text(
          'You will be charged ${plan.priceDisplay}.\n\nThis is a demo. In production, this would integrate with app store subscriptions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${plan.name} subscription activated! (Demo)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Subscribe'),
          ),
        ],
      ),
    );
  }
}
