import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/subscription_tier.dart';
import 'package:indira_love/core/models/gift_model.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/widgets/watch_ads_dialog.dart';
import 'package:indira_love/features/gifts/presentation/screens/gift_inventory_screen.dart';

class GiftsScreen extends ConsumerStatefulWidget {
  const GiftsScreen({super.key});

  @override
  ConsumerState<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends ConsumerState<GiftsScreen> {
  SubscriptionTier _userTier = SubscriptionTier.free;

  @override
  void initState() {
    super.initState();
    _loadUserTier();
  }

  Future<void> _loadUserTier() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final tierString = doc.data()?['subscriptionTier'] as String?;
        setState(() {
          _userTier = tierString == 'silver'
              ? SubscriptionTier.silver
              : tierString == 'gold'
                  ? SubscriptionTier.gold
                  : SubscriptionTier.free;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'Gift Store',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Inventory button
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GiftInventoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                      ),
                      tooltip: 'My Gifts',
                    ),
                    const SizedBox(width: 8),
                    // Tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTierColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _userTier == SubscriptionTier.gold
                                ? Icons.workspace_premium
                                : Icons.card_giftcard,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _userTier == SubscriptionTier.gold
                                ? 'Unlimited'
                                : _userTier == SubscriptionTier.silver
                                    ? 'Silver'
                                    : 'Free',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Gift Grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: GiftCatalog.allGifts.length,
                    itemBuilder: (context, index) {
                      final gift = GiftCatalog.allGifts[index];
                      return _buildGiftItem(context, gift);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTierColor() {
    switch (_userTier) {
      case SubscriptionTier.gold:
        return AppTheme.accentGold;
      case SubscriptionTier.silver:
        return Colors.grey.shade600;
      case SubscriptionTier.free:
        return AppTheme.primaryRose.withOpacity(0.7);
    }
  }

  Widget _buildGiftItem(BuildContext context, GiftModel gift) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutralWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gift Emoji (as image)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryRose.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                gift.emoji,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Gift Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              gift.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textCharcoal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12),

          // Send Button (tier-based)
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ElevatedButton(
                onPressed: () => _sendGift(context, gift),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  backgroundColor: _getButtonColor(),
                ),
                child: Text(_getButtonText()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor() {
    switch (_userTier) {
      case SubscriptionTier.gold:
        return AppTheme.accentGold;
      case SubscriptionTier.silver:
        return Colors.grey.shade600;
      case SubscriptionTier.free:
        return AppTheme.primaryRose;
    }
  }

  String _getButtonText() {
    // All tiers must watch 1 ad per gift
    return 'Watch Ad';
  }

  Future<void> _sendGift(BuildContext context, GiftModel gift) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // All tiers must watch 1 ad per gift (even Gold)
    showWatchAdsDialog(
        context,
        type: 'gift',
        adsRequired: 1,
        onComplete: () async {
          try {
            await FirebaseFirestore.instance.collection('user_gifts').add({
              'userId': user.uid,
              'giftId': gift.id,
              'giftName': gift.name,
              'giftEmoji': gift.emoji,
              'obtainedAt': FieldValue.serverTimestamp(),
              'obtainedVia': 'ad_reward',
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${gift.emoji} ${gift.name} saved to inventory!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save gift: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      );
    }
  }
}
