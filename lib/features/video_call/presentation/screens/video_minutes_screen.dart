import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/subscription_tier.dart';
import 'package:indira_love/core/services/usage_service.dart';
import 'package:indira_love/core/services/logger_service.dart';

class VideoMinutesScreen extends StatefulWidget {
  const VideoMinutesScreen({super.key});

  @override
  State<VideoMinutesScreen> createState() => _VideoMinutesScreenState();
}

class _VideoMinutesScreenState extends State<VideoMinutesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _usageService = UsageService();

  int _consumableMinutes = 0; // in seconds
  int _subscriptionMinutes = 0; // in seconds
  int _minutesUsedThisMonth = 0; // in seconds
  int _callMinutesPerMonth = 0;
  SubscriptionTier _tier = SubscriptionTier.free;
  bool _isLoading = true;

  // Ad progress tracking
  int _ads1Minute = 0;   // progress toward 1 minute (watch 10 ads)
  int _ads5Minutes = 0;  // progress toward 5 minutes (watch 50 ads)
  int _ads10Minutes = 0; // progress toward 10 minutes (watch 90 ads)

  bool _isWatchingAd = false;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      final tierString = data['subscriptionTier'] as String?;
      final tier = tierString == 'gold'
          ? SubscriptionTier.gold
          : tierString == 'silver'
              ? SubscriptionTier.silver
              : SubscriptionTier.free;

      final limits = SubscriptionLimits.fromTier(tier);
      final monthlyUsage = await _usageService.getMonthlyCallMinutesUsed(user.uid);

      if (mounted) {
        setState(() {
          _consumableMinutes = (data['consumableVideoMinutes'] as int?) ?? 0;
          _subscriptionMinutes = (data['subscriptionVideoMinutes'] as int?) ?? 0;
          _minutesUsedThisMonth = monthlyUsage;
          _callMinutesPerMonth = limits.callMinutesPerMonth;
          _tier = tier;
          _ads1Minute = (data['ads1Minute'] as int?) ?? 0;
          _ads5Minutes = (data['ads5Minutes'] as int?) ?? 0;
          _ads10Minutes = (data['ads10Minutes'] as int?) ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.error('Error loading video minutes data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _totalAvailableSeconds => _consumableMinutes + _subscriptionMinutes;
  int get _totalAvailableMinutes => (_totalAvailableSeconds / 60).floor();

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Video Minutes',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMinutesSummary(),
                              const SizedBox(height: 24),
                              _buildSubscriptionInfo(),
                              const SizedBox(height: 24),
                              _buildWatchAdsSection(),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinutesSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRose, AppTheme.primaryRose.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.videocam, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            '$_totalAvailableMinutes',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Minutes Available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMinuteDetail(
                'Subscription',
                '${(_subscriptionMinutes / 60).floor()}m',
                Icons.star,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildMinuteDetail(
                'Earned',
                '${(_consumableMinutes / 60).floor()}m',
                Icons.emoji_events,
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              _buildMinuteDetail(
                'Used',
                '${(_minutesUsedThisMonth / 60).floor()}m',
                Icons.history,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinuteDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSubscriptionInfo() {
    String tierName;
    String minutesInfo;
    Color tierColor;

    switch (_tier) {
      case SubscriptionTier.gold:
        tierName = 'Gold';
        minutesInfo = '600 minutes/month included';
        tierColor = AppTheme.accentGold;
        break;
      case SubscriptionTier.silver:
        tierName = 'Silver';
        minutesInfo = '45 minutes/month included';
        tierColor = Colors.grey.shade600;
        break;
      case SubscriptionTier.free:
        tierName = 'Free';
        minutesInfo = 'No subscription minutes - earn by watching ads!';
        tierColor = AppTheme.primaryRose;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tierColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: tierColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$tierName Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: tierColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  minutesInfo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_tier == SubscriptionTier.free)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/subscription'),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  Widget _buildWatchAdsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earn Minutes by Watching Ads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textCharcoal,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Watch ads to earn free video call minutes!',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        _buildAdPackage(
          minutes: 1,
          adsRequired: 10,
          adsWatched: _ads1Minute,
          icon: '\u{1F3AC}',
          field: 'ads1Minute',
        ),
        const SizedBox(height: 12),
        _buildAdPackage(
          minutes: 5,
          adsRequired: 50,
          adsWatched: _ads5Minutes,
          icon: '\u{1F3A5}',
          field: 'ads5Minutes',
        ),
        const SizedBox(height: 12),
        _buildAdPackage(
          minutes: 10,
          adsRequired: 90,
          adsWatched: _ads10Minutes,
          icon: '\u{1F3C6}',
          field: 'ads10Minutes',
        ),
      ],
    );
  }

  Widget _buildAdPackage({
    required int minutes,
    required int adsRequired,
    required int adsWatched,
    required String icon,
    required String field,
  }) {
    final progress = adsWatched / adsRequired;
    final isComplete = adsWatched >= adsRequired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? Colors.green.shade300 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$minutes ${minutes == 1 ? 'Minute' : 'Minutes'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$adsWatched / $adsRequired ads watched',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isWatchingAd ? null : () => _watchAdForMinutes(minutes, field),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRose,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: _isWatchingAd
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Watch'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : AppTheme.primaryRose,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _watchAdForMinutes(int minutes, String field) async {
    setState(() => _isWatchingAd = true);

    await RewardedAd.load(
      adUnitId: 'ca-app-pub-7587025688858323/9118884689',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _showAd(minutes, field);
        },
        onAdFailedToLoad: (error) {
          logger.error('Failed to load rewarded ad: $error');
          if (mounted) {
            setState(() => _isWatchingAd = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load ad. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showAd(int minutes, String field) {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        if (mounted) setState(() => _isWatchingAd = false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        if (mounted) {
          setState(() => _isWatchingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to show ad. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        _incrementAdProgress(minutes, field);
      },
    );
  }

  Future<void> _incrementAdProgress(int minutes, String field) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    int currentCount;
    int adsRequired;

    switch (minutes) {
      case 1:
        currentCount = _ads1Minute;
        adsRequired = 10;
        break;
      case 5:
        currentCount = _ads5Minutes;
        adsRequired = 50;
        break;
      case 10:
        currentCount = _ads10Minutes;
        adsRequired = 90;
        break;
      default:
        return;
    }

    final newCount = currentCount + 1;

    if (newCount >= adsRequired) {
      // Tier complete - award minutes and reset
      final secondsToAdd = minutes * 60;
      await _firestore.collection('users').doc(user.uid).update({
        'consumableVideoMinutes': FieldValue.increment(secondsToAdd),
        field: 0,
      });

      if (mounted) {
        setState(() {
          _consumableMinutes += secondsToAdd;
          switch (minutes) {
            case 1:
              _ads1Minute = 0;
              break;
            case 5:
              _ads5Minutes = 0;
              break;
            case 10:
              _ads10Minutes = 0;
              break;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$minutes ${minutes == 1 ? 'minute' : 'minutes'} added! Total: $_totalAvailableMinutes minutes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Just increment progress
      await _firestore.collection('users').doc(user.uid).update({
        field: newCount,
      });

      if (mounted) {
        setState(() {
          switch (minutes) {
            case 1:
              _ads1Minute = newCount;
              break;
            case 5:
              _ads5Minutes = newCount;
              break;
            case 10:
              _ads10Minutes = newCount;
              break;
          }
        });
      }
    }
  }
}
