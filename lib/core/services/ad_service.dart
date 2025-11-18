import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:indira_love/core/config/ad_config.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/analytics_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final LoggerService _logger = LoggerService();
  final AnalyticsService _analytics = AnalyticsService();

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  NativeAd? _nativeAd;

  // Ad state tracking
  bool _isInterstitialReady = false;
  bool _isRewardedAdReady = false;
  DateTime? _lastInterstitialTime;
  DateTime? _lastRewardedTime;
  int _interstitialsToday = 0;
  int _rewardedAdsToday = 0;
  DateTime _dayStart = DateTime.now();

  // Initialize ads
  Future<void> initialize() async {
    try {
      // Reset daily counters at midnight
      _scheduleDailyReset();

      // Preload ads
      await _loadBannerAd();
      await _loadInterstitialAd();
      await _loadRewardedAd();

      await _logger.info('Ad service initialized');
    } catch (e) {
      await _logger.error('Failed to initialize ads', error: e);
    }
  }

  // Schedule daily counter reset
  void _scheduleDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    Future.delayed(timeUntilMidnight, () {
      _interstitialsToday = 0;
      _rewardedAdsToday = 0;
      _dayStart = DateTime.now();
      _scheduleDailyReset(); // Schedule next reset
    });
  }

  // BANNER ADS
  Future<void> _loadBannerAd() async {
    try {
      _bannerAd = BannerAd(
        adUnitId: AdConfig.bannerAdUnitId,
        size: AdSize.banner,
        request: AdRequest(
          keywords: AdConfig.keywords,
          contentUrl: 'https://indiralove.com',
          nonPersonalizedAds: false,
        ),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            _logger.info('Banner ad loaded');
            _analytics.logAdImpression('banner', AdConfig.bannerAdUnitId);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _logger.error('Banner ad failed to load', error: error);
            ad.dispose();
            _bannerAd = null;
            // Retry after delay
            Future.delayed(const Duration(minutes: 5), _loadBannerAd);
          },
          onAdOpened: (Ad ad) {
            _analytics.logAdClick('banner', AdConfig.bannerAdUnitId);
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      await _logger.error('Error loading banner ad', error: e);
    }
  }

  Widget? getBannerAdWidget() {
    if (_bannerAd == null) return null;

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  // INTERSTITIAL ADS
  Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialAdUnitId,
        request: AdRequest(
          keywords: AdConfig.keywords,
          nonPersonalizedAds: false,
        ),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialReady = true;
            _logger.info('Interstitial ad loaded');

            // Set fullscreen content callback
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) {
                _analytics.logAdImpression('interstitial', AdConfig.interstitialAdUnitId);
                _lastInterstitialTime = DateTime.now();
                _interstitialsToday++;
              },
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                ad.dispose();
                _isInterstitialReady = false;
                // Preload next interstitial
                if (_interstitialsToday < AdConfig.maxInterstitialAdsPerDay) {
                  Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
                }
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                _logger.error('Interstitial ad failed to show', error: error);
                ad.dispose();
                _isInterstitialReady = false;
                // Retry loading
                Future.delayed(const Duration(minutes: 2), _loadInterstitialAd);
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            _logger.error('Interstitial ad failed to load', error: error);
            _isInterstitialReady = false;
            // Retry after delay
            Future.delayed(const Duration(minutes: 5), _loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      await _logger.error('Error loading interstitial ad', error: e);
    }
  }

  Future<void> showInterstitialAd({
    required String placement,
    VoidCallback? onAdDismissed,
  }) async {
    // Check daily limit
    if (_interstitialsToday >= AdConfig.maxInterstitialAdsPerDay) {
      await _logger.info('Daily interstitial ad limit reached');
      onAdDismissed?.call();
      return;
    }

    // Check minimum time between ads
    if (_lastInterstitialTime != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialTime!);
      if (timeSinceLastAd.inSeconds < AdConfig.minSecondsBetweenInterstitials) {
        await _logger.info('Too soon to show another interstitial');
        onAdDismissed?.call();
        return;
      }
    }

    if (_isInterstitialReady && _interstitialAd != null) {
      try {
        await _interstitialAd!.show();
        await _analytics.logEvent('interstitial_shown', parameters: {
          'placement': placement,
        });
      } catch (e) {
        await _logger.error('Error showing interstitial ad', error: e);
        onAdDismissed?.call();
      }
    } else {
      await _logger.info('Interstitial ad not ready');
      onAdDismissed?.call();
      // Try to load if not loaded
      if (!_isInterstitialReady) {
        _loadInterstitialAd();
      }
    }
  }

  // REWARDED ADS
  Future<void> _loadRewardedAd() async {
    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId,
        request: AdRequest(
          keywords: AdConfig.keywords,
          nonPersonalizedAds: false,
        ),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _logger.info('Rewarded ad loaded');

            // Set fullscreen content callback
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) {
                _analytics.logAdImpression('rewarded', AdConfig.rewardedAdUnitId);
                _lastRewardedTime = DateTime.now();
                _rewardedAdsToday++;
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                ad.dispose();
                _isRewardedAdReady = false;
                // Preload next rewarded ad
                if (_rewardedAdsToday < AdConfig.maxRewardedAdsPerDay) {
                  Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
                }
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                _logger.error('Rewarded ad failed to show', error: error);
                ad.dispose();
                _isRewardedAdReady = false;
                // Retry loading
                Future.delayed(const Duration(minutes: 2), _loadRewardedAd);
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            _logger.error('Rewarded ad failed to load', error: error);
            _isRewardedAdReady = false;
            // Retry after delay
            Future.delayed(const Duration(minutes: 5), _loadRewardedAd);
          },
        ),
      );
    } catch (e) {
      await _logger.error('Error loading rewarded ad', error: e);
    }
  }

  Future<void> showRewardedAd({
    required String placement,
    required Function(int amount) onUserEarnedReward,
    VoidCallback? onAdDismissed,
  }) async {
    // Check daily limit
    if (_rewardedAdsToday >= AdConfig.maxRewardedAdsPerDay) {
      await _logger.info('Daily rewarded ad limit reached');
      onAdDismissed?.call();
      return;
    }

    if (_isRewardedAdReady && _rewardedAd != null) {
      try {
        await _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            _analytics.logEvent('reward_earned', parameters: {
              'placement': placement,
              'reward_type': reward.type,
              'reward_amount': reward.amount,
            });
            onUserEarnedReward(reward.amount.toInt());
          },
        );

        await _analytics.logEvent('rewarded_ad_shown', parameters: {
          'placement': placement,
        });
      } catch (e) {
        await _logger.error('Error showing rewarded ad', error: e);
        onAdDismissed?.call();
      }
    } else {
      await _logger.info('Rewarded ad not ready');
      onAdDismissed?.call();
      // Try to load if not loaded
      if (!_isRewardedAdReady) {
        _loadRewardedAd();
      }
    }
  }

  // NATIVE ADS
  Future<void> loadNativeAd({
    required Function(NativeAd) onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) async {
    try {
      _nativeAd = NativeAd(
        adUnitId: AdConfig.nativeAdUnitId,
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            _logger.info('Native ad loaded');
            _analytics.logAdImpression('native', AdConfig.nativeAdUnitId);
            onAdLoaded(ad as NativeAd);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _logger.error('Native ad failed to load', error: error);
            ad.dispose();
            onAdFailedToLoad(error);
          },
          onAdOpened: (Ad ad) {
            _analytics.logAdClick('native', AdConfig.nativeAdUnitId);
          },
        ),
        request: AdRequest(
          keywords: AdConfig.keywords,
          nonPersonalizedAds: false,
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Colors.white,
          cornerRadius: 12.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: const Color(0xFFFF6B6B),
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black87,
            style: NativeTemplateFontStyle.bold,
            size: 16.0,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black54,
            style: NativeTemplateFontStyle.normal,
            size: 14.0,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: Colors.black45,
            style: NativeTemplateFontStyle.normal,
            size: 12.0,
          ),
        ),
      );

      await _nativeAd!.load();
    } catch (e) {
      await _logger.error('Error loading native ad', error: e);
      onAdFailedToLoad(LoadAdError(
        code: 0,
        domain: 'AdService',
        message: e.toString(),
      ));
    }
  }

  // Check if ads are available
  bool get canShowInterstitialAd =>
      _isInterstitialReady && _interstitialsToday < AdConfig.maxInterstitialAdsPerDay;

  bool get canShowRewardedAd =>
      _isRewardedAdReady && _rewardedAdsToday < AdConfig.maxRewardedAdsPerDay;

  int get remainingInterstitialsToday =>
      AdConfig.maxInterstitialAdsPerDay - _interstitialsToday;

  int get remainingRewardedAdsToday =>
      AdConfig.maxRewardedAdsPerDay - _rewardedAdsToday;

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _nativeAd?.dispose();
  }
}