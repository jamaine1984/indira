import 'package:firebase_performance/firebase_performance.dart';
import 'logger_service.dart';

/// Service for monitoring app performance and network requests
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  late FirebasePerformance _performance;
  bool _initialized = false;

  /// Initialize performance monitoring
  Future<void> initialize() async {
    try {
      _performance = FirebasePerformance.instance;

      // Enable performance monitoring
      await _performance.setPerformanceCollectionEnabled(true);

      _initialized = true;
      logger.info('Performance Monitoring initialized successfully');
    } catch (e) {
      logger.error('Failed to initialize Performance Monitoring', error: e);
    }
  }

  /// Create a custom trace for specific operations
  Trace? startTrace(String traceName) {
    if (!_initialized) return null;

    try {
      final trace = _performance.newTrace(traceName);
      trace.start();
      logger.debug('Started trace: $traceName');
      return trace;
    } catch (e) {
      logger.error('Failed to start trace: $traceName', error: e);
      return null;
    }
  }

  /// Stop a custom trace
  Future<void> stopTrace(Trace? trace) async {
    if (trace == null || !_initialized) return;

    try {
      await trace.stop();
      logger.debug('Stopped trace');
    } catch (e) {
      logger.error('Failed to stop trace', error: e);
    }
  }

  /// Add metric to a trace
  void incrementMetric(Trace? trace, String metricName, int value) {
    if (trace == null || !_initialized) return;

    try {
      trace.incrementMetric(metricName, value);
    } catch (e) {
      logger.error('Failed to increment metric: $metricName', error: e);
    }
  }

  /// Set custom attribute on trace
  void setAttribute(Trace? trace, String attributeName, String value) {
    if (trace == null || !_initialized) return;

    try {
      trace.putAttribute(attributeName, value);
    } catch (e) {
      logger.error('Failed to set attribute: $attributeName', error: e);
    }
  }

  /// Monitor HTTP request
  HttpMetric? startHttpMetric(String url, HttpMethod method) {
    if (!_initialized) return null;

    try {
      final metric = _performance.newHttpMetric(url, method);
      metric.start();
      logger.debug('Started HTTP metric: $method $url');
      return metric;
    } catch (e) {
      logger.error('Failed to start HTTP metric', error: e);
      return null;
    }
  }

  /// Stop HTTP metric
  Future<void> stopHttpMetric(
    HttpMetric? metric, {
    int? statusCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
    String? responseContentType,
  }) async {
    if (metric == null || !_initialized) return;

    try {
      if (statusCode != null) {
        metric.httpResponseCode = statusCode;
      }
      if (requestPayloadSize != null) {
        metric.requestPayloadSize = requestPayloadSize;
      }
      if (responsePayloadSize != null) {
        metric.responsePayloadSize = responsePayloadSize;
      }
      if (responseContentType != null) {
        metric.responseContentType = responseContentType;
      }

      await metric.stop();
      logger.debug('Stopped HTTP metric');
    } catch (e) {
      logger.error('Failed to stop HTTP metric', error: e);
    }
  }

  /// Monitor specific app operations

  // Screen loading trace
  Trace? startScreenLoadTrace(String screenName) {
    return startTrace('screen_load_$screenName');
  }

  // Database operation trace
  Trace? startDatabaseTrace(String operation) {
    return startTrace('database_$operation');
  }

  // Image loading trace
  Trace? startImageLoadTrace() {
    return startTrace('image_load');
  }

  // API call trace
  Trace? startApiCallTrace(String apiName) {
    return startTrace('api_call_$apiName');
  }

  /// Monitor specific dating app operations

  // Match operation trace
  Trace? startMatchTrace() {
    return startTrace('match_operation');
  }

  // Swipe operation trace
  Trace? startSwipeTrace() {
    return startTrace('swipe_operation');
  }

  // Message send trace
  Trace? startMessageSendTrace() {
    return startTrace('message_send');
  }

  // Profile load trace
  Trace? startProfileLoadTrace() {
    return startTrace('profile_load');
  }

  // Photo upload trace
  Trace? startPhotoUploadTrace() {
    return startTrace('photo_upload');
  }

  /// Enable/disable performance monitoring
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {
    try {
      await _performance.setPerformanceCollectionEnabled(enabled);
      logger.info('Performance collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      logger.error('Failed to set performance collection', error: e);
    }
  }
}

// Global performance monitoring instance
final performanceMonitoring = PerformanceMonitoringService();
