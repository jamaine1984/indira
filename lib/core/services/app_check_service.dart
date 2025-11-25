import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'logger_service.dart';

/// Service for Firebase App Check to protect against abuse and fraud
/// App Check helps protect your backend resources from abuse, such as
/// billing fraud, phishing, app impersonation, and data poisoning
class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();
  factory AppCheckService() => _instance;
  AppCheckService._internal();

  late FirebaseAppCheck _appCheck;
  bool _initialized = false;

  /// Initialize App Check
  ///
  /// For Android: Uses Play Integrity API
  /// For iOS: Uses DeviceCheck/App Attest
  /// For Web: Uses reCAPTCHA
  ///
  /// In debug mode, uses debug provider to allow testing without real device attestation
  Future<void> initialize() async {
    try {
      _appCheck = FirebaseAppCheck.instance;

      // Activate App Check
      if (kDebugMode) {
        // In debug mode, use debug provider for easier testing
        // The debug token will be printed to console
        await _appCheck.activate(
          // For Android: Debug provider
          androidProvider: AndroidProvider.debug,
          // For iOS: Debug provider
          appleProvider: AppleProvider.debug,
          // For Web: reCAPTCHA debug
          webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        );
        logger.info('App Check initialized in DEBUG mode');
      } else {
        // In production, use real attestation providers
        await _appCheck.activate(
          // For Android: Play Integrity (Google Play Services)
          androidProvider: AndroidProvider.playIntegrity,
          // For iOS: DeviceCheck or App Attest (iOS 14+)
          appleProvider: AppleProvider.appAttest,
          // For Web: reCAPTCHA v3
          webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
        );
        logger.info('App Check initialized in PRODUCTION mode');
      }

      _initialized = true;
      logger.info('App Check activated successfully');
    } catch (e) {
      logger.error('Failed to initialize App Check', error: e);
    }
  }

  /// Get App Check token
  /// This is usually handled automatically by Firebase SDKs,
  /// but you can get it manually if needed for custom backends
  Future<String?> getToken({bool forceRefresh = false}) async {
    if (!_initialized) {
      logger.warning('App Check not initialized');
      return null;
    }

    try {
      final token = await _appCheck.getToken(forceRefresh);
      logger.debug('App Check token retrieved');
      return token;
    } catch (e) {
      logger.error('Failed to get App Check token', error: e);
      return null;
    }
  }

  /// Set token auto-refresh enabled
  /// When enabled, SDKs automatically refresh tokens before they expire
  Future<void> setTokenAutoRefreshEnabled(bool enabled) async {
    if (!_initialized) return;

    try {
      await _appCheck.setTokenAutoRefreshEnabled(enabled);
      logger.info('Token auto-refresh ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      logger.error('Failed to set token auto-refresh', error: e);
    }
  }

  /// Listen to token changes
  /// Useful for logging or custom analytics
  Stream<String?> get onTokenChange {
    if (!_initialized) {
      return Stream.value(null);
    }
    return _appCheck.onTokenChange;
  }

  /// Check if App Check is initialized
  bool get isInitialized => _initialized;

  /// Verify that App Check is working
  /// This is primarily for debugging purposes
  Future<bool> verifyAppCheck() async {
    if (!_initialized) {
      logger.warning('App Check not initialized, cannot verify');
      return false;
    }

    try {
      final token = await getToken(forceRefresh: true);
      if (token != null && token.isNotEmpty) {
        logger.info('App Check verification successful');
        return true;
      } else {
        logger.warning('App Check token is null or empty');
        return false;
      }
    } catch (e) {
      logger.error('App Check verification failed', error: e);
      return false;
    }
  }
}

// Global app check instance
final appCheck = AppCheckService();

/// IMPORTANT SETUP NOTES:
///
/// 1. Android Setup (Play Integrity):
///    - Enable Play Integrity API in Google Cloud Console
///    - Add SHA-256 fingerprints to Firebase project settings
///    - In production, app must be published to Play Store (internal testing track is fine)
///
/// 2. iOS Setup (App Attest):
///    - Available on iOS 14+ devices
///    - Automatically works with App Store and TestFlight builds
///    - For local development, use DeviceCheck (falls back automatically)
///
/// 3. Firebase Console Setup:
///    - Enable App Check in Firebase Console for your project
///    - Register your app for App Check
///    - Configure providers (Play Integrity for Android, App Attest for iOS)
///
/// 4. Debug Tokens:
///    - When running in debug mode, check console for debug token
///    - Add debug token to Firebase Console under App Check > Apps > Debug tokens
///    - This allows testing without real device attestation
///
/// 5. Backend Protection:
///    - App Check tokens are automatically included in requests to:
///      * Cloud Firestore
///      * Cloud Storage
///      * Cloud Functions
///      * Realtime Database
///    - Configure enforcement in Firebase Console per service
///
/// 6. Custom Backend Integration:
///    - For custom backends, get token manually: appCheck.getToken()
///    - Send token in header: 'X-Firebase-AppCheck': token
///    - Verify token on backend using Admin SDK
