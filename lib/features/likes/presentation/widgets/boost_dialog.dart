import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/widgets/watch_ads_dialog.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/features/likes/providers/boost_provider.dart';
import 'package:indira_love/features/likes/services/boost_service.dart';

void showBoostDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => const BoostDialog(),
  );
}

class BoostDialog extends ConsumerWidget {
  const BoostDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasGoldAsync = ref.watch(hasGoldForBoostProvider);
    final adRequirements = ref.watch(boostAdRequirementsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.romanticGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Boost Your Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get 10x more profile views!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Gold users get free boost
            hasGoldAsync.when(
              data: (hasGold) {
                if (hasGold) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentGold,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: AppTheme.accentGold,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gold Member',
                                    style: TextStyle(
                                      color: AppTheme.accentGold,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Unlimited ad-free boosts!',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBoostOption(
                        context,
                        ref,
                        duration: 30,
                        adsRequired: 0,
                        isGold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildBoostOption(
                        context,
                        ref,
                        duration: 60,
                        adsRequired: 0,
                        isGold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildBoostOption(
                        context,
                        ref,
                        duration: 120,
                        adsRequired: 0,
                        isGold: true,
                      ),
                    ],
                  );
                } else {
                  // Free/Silver users watch ads
                  return Column(
                    children: [
                      _buildBoostOption(
                        context,
                        ref,
                        duration: 30,
                        adsRequired: adRequirements[30]!,
                        isGold: false,
                      ),
                      const SizedBox(height: 12),
                      _buildBoostOption(
                        context,
                        ref,
                        duration: 60,
                        adsRequired: adRequirements[60]!,
                        isGold: false,
                      ),
                      const SizedBox(height: 12),
                      _buildBoostOption(
                        context,
                        ref,
                        duration: 120,
                        adsRequired: adRequirements[120]!,
                        isGold: false,
                      ),
                    ],
                  );
                }
              },
              loading: () => const CircularProgressIndicator(color: Colors.white),
              error: (_, __) => const Text(
                'Error loading boost options',
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostOption(
    BuildContext context,
    WidgetRef ref, {
    required int duration,
    required int adsRequired,
    required bool isGold,
  }) {
    String durationText;
    if (duration == 30) {
      durationText = '30 minutes';
    } else if (duration == 60) {
      durationText = '1 hour';
    } else {
      durationText = '2 hours';
    }

    return ElevatedButton(
      onPressed: () => _activateBoost(context, ref, duration, adsRequired, isGold),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryRose,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                durationText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isGold ? 'Free with Gold' : 'Watch $adsRequired ads',
                style: TextStyle(
                  fontSize: 14,
                  color: isGold ? AppTheme.accentGold : AppTheme.primaryRose,
                ),
              ),
            ],
          ),
          Icon(
            isGold ? Icons.workspace_premium : Icons.play_circle_outline,
            size: 32,
            color: isGold ? AppTheme.accentGold : AppTheme.primaryRose,
          ),
        ],
      ),
    );
  }

  void _activateBoost(
    BuildContext context,
    WidgetRef ref,
    int duration,
    int adsRequired,
    bool isGold,
  ) {
    Navigator.pop(context); // Close dialog

    if (isGold) {
      // Gold users activate boost immediately
      _createBoost(context, ref, duration, 0);
    } else {
      // Free/Silver users watch ads first
      showWatchAdsDialog(
        context,
        type: 'boost',
        adsRequired: adsRequired,
        onComplete: () async {
          await _createBoost(context, ref, duration, adsRequired);
        },
      );
    }
  }

  Future<void> _createBoost(
    BuildContext context,
    WidgetRef ref,
    int duration,
    int adsWatched,
  ) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      await ref.read(boostServiceProvider).createBoost(
            userId: user.uid,
            durationMinutes: duration,
            adsWatched: adsWatched,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile boosted for ${duration} minutes!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh active boost
      ref.invalidate(activeBoostProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate boost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
