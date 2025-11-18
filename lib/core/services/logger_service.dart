import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Production-grade logging service that replaces print statements
/// Supports different log levels and integrates with Firebase Crashlytics
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  FirebaseCrashlytics? _crashlytics;
  bool _initialized = false;

  /// Initialize logger with Firebase Crashlytics
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = _crashlytics!.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics!.recordError(error, stack, fatal: true);
        return true;
      };

      _initialized = true;
      debug('LoggerService initialized successfully');
    } catch (e) {
      // Fallback to debug print if Crashlytics fails
      if (kDebugMode) {
        debugPrint('Failed to initialize LoggerService: $e');
      }
    }
  }

  /// Log debug messages (only in debug mode)
  void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('🔍 DEBUG: $tagPrefix$message');
    }
  }

  /// Log info messages
  void info(String message, {String? tag}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ INFO: $tagPrefix$message');
    }
    _crashlytics?.log('INFO: $message');
  }

  /// Log warning messages
  void warning(String message, {String? tag, Object? error}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ WARNING: $tagPrefix$message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
    }
    _crashlytics?.log('WARNING: $message');
    if (error != null) {
      _crashlytics?.recordError(error, null, fatal: false);
    }
  }

  /// Log error messages and record to Crashlytics
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ ERROR: $tagPrefix$message');
      if (error != null) {
        debugPrint('Error details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    _crashlytics?.log('ERROR: $message');
    if (error != null) {
      _crashlytics?.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }

  /// Log fatal errors that crash the app
  void fatal(String message, {String? tag, required Object error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      final tagPrefix = tag != null ? '[$tag] ' : '';
      debugPrint('💀 FATAL: $tagPrefix$message');
      debugPrint('Error details: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    _crashlytics?.recordError(
      error,
      stackTrace,
      reason: message,
      fatal: true,
    );
  }

  /// Set user identifier for crash reports
  void setUserId(String? userId) {
    if (userId != null) {
      _crashlytics?.setUserIdentifier(userId);
    }
  }

  /// Set custom key-value pairs for crash reports
  void setCustomKey(String key, dynamic value) {
    _crashlytics?.setCustomKey(key, value);
  }

  /// Log analytics-style events (non-crash events)
  void logEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      debugPrint('📊 EVENT: $eventName ${parameters ?? ''}');
    }
    _crashlytics?.log('EVENT: $eventName - ${parameters ?? {}}');
  }

  /// Log network requests (useful for debugging API issues)
  void logNetworkRequest(String url, String method, {int? statusCode, String? error}) {
    if (kDebugMode) {
      debugPrint('🌐 NETWORK: $method $url ${statusCode != null ? '- $statusCode' : ''}');
      if (error != null) {
        debugPrint('Network error: $error');
      }
    }
    _crashlytics?.log('NETWORK: $method $url - ${statusCode ?? 'ERROR: $error'}');
  }

  /// Log user actions (for audit trail)
  void logUserAction(String action, {String? userId, Map<String, dynamic>? details}) {
    if (kDebugMode) {
      debugPrint('👤 USER ACTION: $action ${details ?? ''}');
    }
    _crashlytics?.log('USER_ACTION: $action - User: ${userId ?? 'unknown'} - ${details ?? {}}');
  }

  /// Log security events
  void logSecurityEvent(String event, {String? userId, Map<String, dynamic>? details}) {
    if (kDebugMode) {
      debugPrint('🔒 SECURITY: $event ${details ?? ''}');
    }
    _crashlytics?.log('SECURITY: $event - User: ${userId ?? 'unknown'} - ${details ?? {}}');

    // Security events are important, record as non-fatal error
    _crashlytics?.recordError(
      Exception('Security Event: $event'),
      null,
      reason: 'Security event logged for user ${userId ?? 'unknown'}',
      fatal: false,
    );
  }

  /// Force send all pending crash reports
  Future<void> sendUnsentReports() async {
    await _crashlytics?.sendUnsentReports();
  }

  /// Check if crash reporting is enabled
  bool isCrashlyticsCollectionEnabled() {
    return _crashlytics?.isCrashlyticsCollectionEnabled ?? false;
  }

  /// Enable/disable crash reporting
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
  }
}

// Global logger instance
final logger = LoggerService();
