import 'dart:io';

class AdConfig {
  // Production AdMob App IDs
  static const String androidAppId = 'ca-app-pub-7587025688858323~6036042883'; // Production Android App ID
  static const String iosAppId = 'ca-app-pub-7587025688858323~4798870148'; // iOS App ID - Production

  // ⚠️ IMPORTANT: These ad units must be UNIQUE for each format!
  // Using the same ID for all formats will cause AdMob issues and revenue loss.
  // Follow the instructions at the bottom of this file to create proper ad units.

  // Production Ad Unit IDs - Android
  // TODO: Replace these with actual Android ad unit IDs from AdMob console
  static const String androidBannerAdUnitId = 'ca-app-pub-7587025688858323/XXXXXXXXXX'; // Create Banner ad unit
  static const String androidInterstitialAdUnitId = 'ca-app-pub-7587025688858323/YYYYYYYYYY'; // Create Interstitial ad unit
  static const String androidRewardedAdUnitId = 'ca-app-pub-7587025688858323/ZZZZZZZZZZ'; // Create Rewarded ad unit
  static const String androidNativeAdUnitId = 'ca-app-pub-7587025688858323/AAAAAAAAAA'; // Create Native ad unit

  // Production Ad Unit IDs - iOS
  // TODO: Create additional ad units (Banner, Interstitial, Native) in AdMob console
  static const String iosBannerAdUnitId = 'ca-app-pub-7587025688858323/BBBBBBBBBB'; // TODO: Create Banner ad unit (iOS)
  static const String iosInterstitialAdUnitId = 'ca-app-pub-7587025688858323/CCCCCCCCCC'; // TODO: Create Interstitial ad unit (iOS)
  static const String iosRewardedAdUnitId = 'ca-app-pub-7587025688858323/6471701001'; // ✅ Production Rewarded Ad Unit
  static const String iosNativeAdUnitId = 'ca-app-pub-7587025688858323/EEEEEEEEEE'; // TODO: Create Native ad unit (iOS)

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

// ═══════════════════════════════════════════════════════════════════════════
// HOW TO CREATE PRODUCTION AD UNITS IN ADMOB
// ═══════════════════════════════════════════════════════════════════════════
//
// ⚠️ CRITICAL: Each ad format MUST have its own unique Ad Unit ID!
// Using the same ID for multiple formats will break your ads and cost revenue.
//
// STEP 1: Login to AdMob Console
// - Go to https://admob.google.com
// - Login with account: ca-app-pub-7587025688858323
//
// STEP 2: Create Separate Ad Units for Android
// - Click on your Android app
// - Click "Ad units" → "Add ad unit"
// - Create the following ad units:
//   1. Banner Ad → Copy the ID → Replace androidBannerAdUnitId
//   2. Interstitial Ad → Copy the ID → Replace androidInterstitialAdUnitId
//   3. Rewarded Ad → Copy the ID → Replace androidRewardedAdUnitId
//   4. Native Ad → Copy the ID → Replace androidNativeAdUnitId
//
// STEP 3: Create Separate Ad Units for iOS
// - Click on your iOS app (or create one if it doesn't exist)
// - Click "Ad units" → "Add ad unit"
// - Create the following ad units:
//   1. Banner Ad → Copy the ID → Replace iosBannerAdUnitId
//   2. Interstitial Ad → Copy the ID → Replace iosInterstitialAdUnitId
//   3. Rewarded Ad → Copy the ID → Replace iosRewardedAdUnitId
//   4. Native Ad → Copy the ID → Replace iosNativeAdUnitId
//
// STEP 4: Update this File
// - Replace all XXXXXXXXXX, YYYYYYYYYY, etc. with actual ad unit IDs
// - Each ID should be unique and in format: ca-app-pub-XXXXXXXX/YYYYYYYYYY
//
// STEP 5: Test Before Launching
// - Use test mode first to verify ads load correctly
// - Check each ad format works on both Android and iOS
// - Monitor AdMob dashboard for impressions
//
// ⚠️ NEVER use test ad IDs in production builds!
// ═══════════════════════════════════════════════════════════════════════════