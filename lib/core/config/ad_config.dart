import 'dart:io';

class AdConfig {
  // Production AdMob App IDs
  static const String androidAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX'; // Replace with your Android App ID
  static const String iosAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX'; // Replace with your iOS App ID

  // Production Ad Unit IDs - Android
  static const String androidBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String androidInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String androidRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String androidNativeAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // Production Ad Unit IDs - iOS
  static const String iosBannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String iosInterstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String iosRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String iosNativeAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

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

// NOTE: To get production Ad Unit IDs:
// 1. Go to https://admob.google.com
// 2. Create an app for Android and iOS
// 3. Create ad units for each ad format (banner, interstitial, rewarded, native)
// 4. Replace the XXXXXXX placeholders above with your actual ad unit IDs
// 5. NEVER use test ad IDs in production builds