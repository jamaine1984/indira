import 'dart:io';

class AdConfig {
  // Production AdMob App IDs
  static const String androidAppId = 'ca-app-pub-7587025688858323~6036042883';
  static const String iosAppId = 'ca-app-pub-7587025688858323~4798870148';

  // Production Ad Unit IDs - Android
  static const String androidBannerAdUnitId = 'ca-app-pub-7587025688858323/9118884689';
  static const String androidInterstitialAdUnitId = 'ca-app-pub-7587025688858323/9118884689';
  static const String androidRewardedAdUnitId = 'ca-app-pub-7587025688858323/9118884689';
  static const String androidNativeAdUnitId = 'ca-app-pub-7587025688858323/9118884689';

  // iOS Ad Unit IDs - temporarily disabled (Android-only deployment)
  static const String iosBannerAdUnitId = 'ca-app-pub-7587025688858323/0000000000';
  static const String iosInterstitialAdUnitId = 'ca-app-pub-7587025688858323/0000000000';
  static const String iosRewardedAdUnitId = 'ca-app-pub-7587025688858323/0000000000';
  static const String iosNativeAdUnitId = 'ca-app-pub-7587025688858323/0000000000';

  // Get platform-specific ad unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return iosBannerAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return androidInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return iosInterstitialAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return iosRewardedAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return androidNativeAdUnitId;
    } else if (Platform.isIOS) {
      return iosNativeAdUnitId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Ad frequency configuration
  static const int minSecondsBetweenInterstitials = 120; // 2 minutes
  static const int maxRewardedAdsPerDay = 20;
  static const int maxInterstitialAdsPerDay = 10;

  // User targeting
  static const List<String> keywords = [
    'dating',
    'romance',
    'relationships',
    'singles',
    'love',
    'match',
    'chat',
    'meet',
    'date',
    'social',
  ];

  // Content rating
  static const String maxAdContentRating = 'MA'; // Mature audiences for dating app
}
