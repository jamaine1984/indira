import 'package:flutter/material.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:indira_love/core/theme/app_theme.dart';

class WatchAdsDialog extends StatefulWidget {
  final String type; // 'likes' or 'messages'
  final int adsRequired;
  final VoidCallback onComplete;

  const WatchAdsDialog({
    super.key,
    required this.type,
    required this.adsRequired,
    required this.onComplete,
  });

  @override
  State<WatchAdsDialog> createState() => _WatchAdsDialogState();
}

class _WatchAdsDialogState extends State<WatchAdsDialog> {
  int _adsWatched = 0;
  bool _isWatchingAd = false;
  RewardedAd? _rewardedAd;

  // Production ad unit ID for rewarded ads
  static String get _adUnitId {
    // Real production AdMob Rewarded Ad Unit ID
    return 'ca-app-pub-7587025688858323/9118884689';
  }

  @override
  Widget build(BuildContext context) {
    String typeName;
    IconData icon;
    String message;

    switch (widget.type) {
      case 'likes':
        typeName = 'Likes';
        icon = Icons.favorite;
        message = 'You\'ve used all your $typeName for today!';
        break;
      case 'messages':
        typeName = 'Messages';
        icon = Icons.message;
        message = 'You\'ve used all your $typeName for today!';
        break;
      case 'gift':
        typeName = 'Gift';
        icon = Icons.card_giftcard;
        message = 'Watch an ad to add this gift to your inventory!';
        break;
      default:
        typeName = 'Items';
        icon = Icons.info;
        message = 'Watch ads to continue!';
    }

    return AlertDialog(
      title: Text(widget.type == 'gift' ? 'Send Gift' : 'Out of $typeName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryRose,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.type == 'gift'
                ? 'Watch ${widget.adsRequired} ad${widget.adsRequired > 1 ? "s" : ""} to add this gift to your inventory.'
                : 'Watch ${widget.adsRequired} ads to get more ${typeName.toLowerCase()}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: _adsWatched / widget.adsRequired,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRose),
          ),
          const SizedBox(height: 8),
          Text(
            '$_adsWatched / ${widget.adsRequired} ads watched',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        if (!_isWatchingAd) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: _watchAd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
            ),
            child: const Text('Watch Ad'),
          ),
        ],
        if (_isWatchingAd)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading ad...'),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _showRewardedAd();
        },
        onAdFailedToLoad: (error) {
          logger.error('RewardedAd failed to load: $error');
          if (mounted) {
            setState(() {
              _isWatchingAd = false;
            });
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

  void _showRewardedAd() {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        logger.info('RewardedAd showed full screen content');
      },
      onAdDismissedFullScreenContent: (ad) {
        logger.info('RewardedAd dismissed full screen content');
        ad.dispose();
        _rewardedAd = null;
        if (mounted) {
          setState(() {
            _isWatchingAd = false;
          });
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        logger.error('RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        if (mounted) {
          setState(() {
            _isWatchingAd = false;
          });
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
        logger.info('User earned reward: ${reward.amount} ${reward.type}');
        if (mounted) {
          setState(() {
            _adsWatched++;
          });

          if (_adsWatched >= widget.adsRequired) {
            // All ads watched!
            widget.onComplete();
            Navigator.pop(context);
            String message;
            switch (widget.type) {
              case 'likes':
                message = 'Likes refilled!';
                break;
              case 'messages':
                message = 'Messages refilled!';
                break;
              case 'gift':
                message = 'Gift added to inventory!';
                break;
              default:
                message = 'Complete!';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _watchAd() async {
    setState(() {
      _isWatchingAd = true;
    });

    await _loadRewardedAd();
  }
}

void showWatchAdsDialog(
  BuildContext context, {
  required String type,
  required int adsRequired,
  required VoidCallback onComplete,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WatchAdsDialog(
      type: type,
      adsRequired: adsRequired,
      onComplete: onComplete,
    ),
  );
}
