import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'logger_service.dart';

/// Service for managing remote configuration and feature flags
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  // Default values for remote config
  static const Map<String, dynamic> _defaults = {
    // Feature flags
    'enable_video_dating': true,
    'enable_voice_messages': true,
    'enable_gifts': true,
    'enable_superlikes': true,
    'enable_boost': true,
    'enable_verification': true,

    // Limits and quotas
    'free_daily_likes': 50,
    'free_daily_superlikes': 1,
    'silver_daily_likes': 100,
    'silver_daily_superlikes': 5,
    'gold_daily_likes': -1, // Unlimited
    'gold_daily_superlikes': -1, // Unlimited

    // Pricing
    'silver_monthly_price': 9.99,
    'silver_yearly_price': 79.99,
    'gold_monthly_price': 19.99,
    'gold_yearly_price': 149.99,

    // Ad configuration
    'show_ads_for_free_users': true,
    'ad_frequency_minutes': 30,
    'reward_per_ad_minutes': 5,

    // Matching algorithm
    'max_distance_km': 100,
    'age_range_default': 10,
    'enable_ai_matching': false,

    // Safety and moderation
    'enable_photo_verification': true,
    'enable_id_verification': true,
    'auto_hide_reported_profiles': true,
    'report_threshold_for_review': 3,

    // Maintenance
    'maintenance_mode': false,
    'maintenance_message': 'We are currently performing maintenance. Please check back soon!',
    'force_update_version': '1.0.0',
    'minimum_supported_version': '1.0.0',
  };

  /// Initialize remote config
  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1), // Fetch every hour in production
        ),
      );

      // Set default values
      await _remoteConfig.setDefaults(_defaults);

      // Fetch and activate config
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      logger.info('Remote Config initialized successfully');
    } catch (e) {
      logger.error('Failed to initialize Remote Config', error: e);
    }
  }

  /// Fetch latest config from server
  Future<void> fetchConfig() async {
    if (!_initialized) return;

    try {
      await _remoteConfig.fetchAndActivate();
      logger.info('Remote Config fetched and activated');
    } catch (e) {
      logger.error('Failed to fetch Remote Config', error: e);
    }
  }

  /// Get string value
  String getString(String key) {
    if (!_initialized) return _defaults[key]?.toString() ?? '';
    return _remoteConfig.getString(key);
  }

  /// Get int value
  int getInt(String key) {
    if (!_initialized) return _defaults[key] as int? ?? 0;
    return _remoteConfig.getInt(key);
  }

  /// Get double value
  double getDouble(String key) {
    if (!_initialized) return _defaults[key] as double? ?? 0.0;
    return _remoteConfig.getDouble(key);
  }

  /// Get bool value
  bool getBool(String key) {
    if (!_initialized) return _defaults[key] as bool? ?? false;
    return _remoteConfig.getBool(key);
  }

  // Feature flags getters

  bool get isVideoDatingEnabled => getBool('enable_video_dating');
  bool get isVoiceMessagesEnabled => getBool('enable_voice_messages');
  bool get isGiftsEnabled => getBool('enable_gifts');
  bool get isSuperlikesEnabled => getBool('enable_superlikes');
  bool get isBoostEnabled => getBool('enable_boost');
  bool get isVerificationEnabled => getBool('enable_verification');

  // Limits and quotas getters

  int get freeDailyLikes => getInt('free_daily_likes');
  int get freeDailySuperlikes => getInt('free_daily_superlikes');
  int get silverDailyLikes => getInt('silver_daily_likes');
  int get silverDailySuperlikes => getInt('silver_daily_superlikes');
  int get goldDailyLikes => getInt('gold_daily_likes');
  int get goldDailySuperlikes => getInt('gold_daily_superlikes');

  // Pricing getters

  double get silverMonthlyPrice => getDouble('silver_monthly_price');
  double get silverYearlyPrice => getDouble('silver_yearly_price');
  double get goldMonthlyPrice => getDouble('gold_monthly_price');
  double get goldYearlyPrice => getDouble('gold_yearly_price');

  // Ad configuration getters

  bool get showAdsForFreeUsers => getBool('show_ads_for_free_users');
  int get adFrequencyMinutes => getInt('ad_frequency_minutes');
  int get rewardPerAdMinutes => getInt('reward_per_ad_minutes');

  // Matching algorithm getters

  int get maxDistanceKm => getInt('max_distance_km');
  int get ageRangeDefault => getInt('age_range_default');
  bool get enableAiMatching => getBool('enable_ai_matching');

  // Safety and moderation getters

  bool get enablePhotoVerification => getBool('enable_photo_verification');
  bool get enableIdVerification => getBool('enable_id_verification');
  bool get autoHideReportedProfiles => getBool('auto_hide_reported_profiles');
  int get reportThresholdForReview => getInt('report_threshold_for_review');

  // Maintenance getters

  bool get isMaintenanceMode => getBool('maintenance_mode');
  String get maintenanceMessage => getString('maintenance_message');
  String get forceUpdateVersion => getString('force_update_version');
  String get minimumSupportedVersion => getString('minimum_supported_version');

  /// Check if app version is supported
  bool isVersionSupported(String currentVersion) {
    try {
      final minVersion = minimumSupportedVersion.split('.').map(int.parse).toList();
      final currVersion = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < minVersion.length && i < currVersion.length; i++) {
        if (currVersion[i] < minVersion[i]) return false;
        if (currVersion[i] > minVersion[i]) return true;
      }

      return true;
    } catch (e) {
      logger.error('Failed to check version support', error: e);
      return true; // Default to supported if version check fails
    }
  }

  /// Check if force update is required
  bool isForceUpdateRequired(String currentVersion) {
    try {
      final forceVersion = forceUpdateVersion.split('.').map(int.parse).toList();
      final currVersion = currentVersion.split('.').map(int.parse).toList();

      for (int i = 0; i < forceVersion.length && i < currVersion.length; i++) {
        if (currVersion[i] < forceVersion[i]) return true;
        if (currVersion[i] > forceVersion[i]) return false;
      }

      return false;
    } catch (e) {
      logger.error('Failed to check force update', error: e);
      return false;
    }
  }

  /// Get daily likes limit for subscription tier
  int getDailyLikesLimit(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return goldDailyLikes;
      case 'silver':
        return silverDailyLikes;
      default:
        return freeDailyLikes;
    }
  }

  /// Get daily superlikes limit for subscription tier
  int getDailySuperlikes(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return goldDailySuperlikes;
      case 'silver':
        return silverDailySuperlikes;
      default:
        return freeDailySuperlikes;
    }
  }

  /// Listen for config updates
  Stream<RemoteConfigUpdate> get onConfigUpdated {
    return _remoteConfig.onConfigUpdated;
  }
}

// Global remote config instance
final remoteConfig = RemoteConfigService();
