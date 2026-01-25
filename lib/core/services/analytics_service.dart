import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logger_service.dart';

/// Comprehensive analytics service for tracking user events and behavior
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  // Connect to the nam5 database instance where all users are stored
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  /// Initialize analytics
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _initialized = true;
      logger.info('AnalyticsService initialized successfully');
    } catch (e) {
      logger.error('Failed to initialize AnalyticsService', error: e);
    }
  }

  /// Set user properties for analytics
  Future<void> setUserProperties({
    required String userId,
    String? subscriptionTier,
    String? gender,
    int? age,
    String? location,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics.setUserId(id: userId);

      if (subscriptionTier != null) {
        await _analytics.setUserProperty(name: 'subscription_tier', value: subscriptionTier);
      }

      if (gender != null) {
        await _analytics.setUserProperty(name: 'gender', value: gender);
      }

      if (age != null) {
        await _analytics.setUserProperty(name: 'age_group', value: _getAgeGroup(age));
      }

      if (location != null) {
        await _analytics.setUserProperty(name: 'location', value: location);
      }

      logger.debug('User properties set for analytics');
    } catch (e) {
      logger.error('Failed to set user properties', error: e);
    }
  }

  String _getAgeGroup(int age) {
    if (age < 25) return '18-24';
    if (age < 35) return '25-34';
    if (age < 45) return '35-44';
    if (age < 55) return '45-54';
    return '55+';
  }

  // User Authentication Events

  Future<void> logSignUp(String method) async {
    await _logEvent('sign_up', parameters: {'method': method});
  }

  Future<void> logLogin(String method) async {
    await _logEvent('login', parameters: {'method': method});
  }

  Future<void> logLogout() async {
    await _logEvent('logout');
  }

  // Onboarding Events

  Future<void> logOnboardingStart() async {
    await _logEvent('onboarding_start');
  }

  Future<void> logOnboardingComplete() async {
    await _logEvent('onboarding_complete');
  }

  Future<void> logOnboardingStep(int step, String stepName) async {
    await _logEvent('onboarding_step', parameters: {
      'step_number': step,
      'step_name': stepName,
    });
  }

  // Profile Events

  Future<void> logProfileView(String viewedUserId) async {
    await _logEvent('profile_view', parameters: {'viewed_user_id': viewedUserId});
    await _incrementProfileViews(viewedUserId);
  }

  Future<void> logProfileEdit() async {
    await _logEvent('profile_edit');
  }

  Future<void> logPhotoUpload(int photoCount) async {
    await _logEvent('photo_upload', parameters: {'photo_count': photoCount});
  }

  // Discovery & Swiping Events

  Future<void> logSwipeRight(String swipedUserId) async {
    await _logEvent('swipe_right', parameters: {'swiped_user_id': swipedUserId});
  }

  Future<void> logSwipeLeft(String swipedUserId) async {
    await _logEvent('swipe_left', parameters: {'swiped_user_id': swipedUserId});
  }

  Future<void> logSuperlike(String likedUserId) async {
    await _logEvent('superlike', parameters: {'liked_user_id': likedUserId});
  }

  Future<void> logBoostActivated(int durationMinutes) async {
    await _logEvent('boost_activated', parameters: {
      'duration_minutes': durationMinutes,
    });
  }

  // Match Events

  Future<void> logMatch(String matchedUserId) async {
    await _logEvent('match_created', parameters: {'matched_user_id': matchedUserId});
  }

  Future<void> logUnmatch(String unmatchedUserId) async {
    await _logEvent('unmatch', parameters: {'unmatched_user_id': unmatchedUserId});
  }

  // Messaging Events

  Future<void> logMessageSent(String receiverId, String messageType) async {
    await _logEvent('message_sent', parameters: {
      'receiver_id': receiverId,
      'message_type': messageType,
    });
  }

  Future<void> logVoiceMessageSent(int durationSeconds) async {
    await _logEvent('voice_message_sent', parameters: {
      'duration_seconds': durationSeconds,
    });
  }

  Future<void> logConversationStarted(String withUserId) async {
    await _logEvent('conversation_started', parameters: {'with_user_id': withUserId});
  }

  // Gift Events

  Future<void> logGiftSent(String giftId, String receiverId, int cost) async {
    await _logEvent('gift_sent', parameters: {
      'gift_id': giftId,
      'receiver_id': receiverId,
      'gift_cost': cost,
    });
  }

  Future<void> logGiftReceived(String giftId, String senderId) async {
    await _logEvent('gift_received', parameters: {
      'gift_id': giftId,
      'sender_id': senderId,
    });
  }

  // Subscription Events

  Future<void> logSubscriptionPurchase(String tier, double price) async {
    await _logEvent('subscription_purchase', parameters: {
      'tier': tier,
      'price': price,
      'currency': 'USD',
    });
  }

  Future<void> logSubscriptionCancel(String tier) async {
    await _logEvent('subscription_cancel', parameters: {'tier': tier});
  }

  Future<void> logSubscriptionRenew(String tier) async {
    await _logEvent('subscription_renew', parameters: {'tier': tier});
  }

  // In-App Purchase Events

  Future<void> logPurchase(String productId, double price) async {
    await _logEvent('purchase', parameters: {
      'product_id': productId,
      'price': price,
      'currency': 'USD',
    });
  }

  // Verification Events

  Future<void> logVerificationStart(String verificationType) async {
    await _logEvent('verification_start', parameters: {
      'verification_type': verificationType,
    });
  }

  Future<void> logVerificationComplete(String verificationType) async {
    await _logEvent('verification_complete', parameters: {
      'verification_type': verificationType,
    });
  }

  // Safety & Reporting Events

  Future<void> logUserReported(String reportedUserId, String reason) async {
    await _logEvent('user_reported', parameters: {
      'reported_user_id': reportedUserId,
      'reason': reason,
    });
  }

  Future<void> logUserBlocked(String blockedUserId) async {
    await _logEvent('user_blocked', parameters: {
      'blocked_user_id': blockedUserId,
    });
  }

  // Ad Events

  Future<void> logAdWatched(String adType, String rewardType) async {
    await _logEvent('ad_watched', parameters: {
      'ad_type': adType,
      'reward_type': rewardType,
    });
  }

  Future<void> logAdFailed(String adType, String errorReason) async {
    await _logEvent('ad_failed', parameters: {
      'ad_type': adType,
      'error_reason': errorReason,
    });
  }

  // Engagement Metrics

  Future<void> logSessionStart() async {
    await _logEvent('session_start');
  }

  Future<void> logSessionEnd(int durationSeconds) async {
    await _logEvent('session_end', parameters: {
      'duration_seconds': durationSeconds,
    });
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logFeatureUsed(String featureName) async {
    await _logEvent('feature_used', parameters: {'feature_name': featureName});
  }

  // Retention Events

  Future<void> logDailyActive() async {
    await _logEvent('daily_active_user');
  }

  Future<void> logWeeklyActive() async {
    await _logEvent('weekly_active_user');
  }

  Future<void> logMonthlyActive() async {
    await _logEvent('monthly_active_user');
  }

  // Conversion Events

  Future<void> logConversion(String conversionType, double value) async {
    await _logEvent('conversion', parameters: {
      'conversion_type': conversionType,
      'value': value,
    });
  }

  // Error Events

  Future<void> logError(String errorType, String errorMessage) async {
    await _logEvent('error_occurred', parameters: {
      'error_type': errorType,
      'error_message': errorMessage,
    });
  }

  // Performance Events

  Future<void> logPerformanceMetric(String metricName, int valueMs) async {
    await _logEvent('performance_metric', parameters: {
      'metric_name': metricName,
      'value_ms': valueMs,
    });
  }

  // Generic event logger
  Future<void> _logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    if (!_initialized) return;

    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters?.cast<String, Object>(),
      );

      logger.logEvent(eventName, parameters: parameters);

      // Also store important events in Firestore for custom analytics
      if (_shouldStoreInFirestore(eventName)) {
        await _storeEventInFirestore(eventName, parameters);
      }
    } catch (e) {
      logger.error('Failed to log event: $eventName', error: e);
    }
  }

  bool _shouldStoreInFirestore(String eventName) {
    // Store critical events in Firestore for custom analytics
    const criticalEvents = [
      'sign_up',
      'match_created',
      'subscription_purchase',
      'gift_sent',
      'user_reported',
      'verification_complete',
    ];
    return criticalEvents.contains(eventName);
  }

  Future<void> _storeEventInFirestore(String eventName, Map<String, dynamic>? parameters) async {
    try {
      await _firestore.collection('analytics_events').add({
        'event_name': eventName,
        'parameters': parameters ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.warning('Failed to store event in Firestore', error: e);
    }
  }

  Future<void> _incrementProfileViews(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profile_views': FieldValue.increment(1),
      });
    } catch (e) {
      logger.warning('Failed to increment profile views', error: e);
    }
  }

  /// Get analytics for admin dashboard
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    try {
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get user counts
      final usersSnapshot = await _firestore.collection('users').get();
      final totalUsers = usersSnapshot.docs.length;

      // Get active users (last 24h)
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastActive', isGreaterThan: Timestamp.fromDate(dayAgo))
          .get();
      final dailyActiveUsers = activeUsersSnapshot.docs.length;

      // Get matches created
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .get();
      final weeklyMatches = matchesSnapshot.docs.length;

      // Get messages sent
      final messagesSnapshot = await _firestore
          .collectionGroup('messages')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(dayAgo))
          .get();
      final dailyMessages = messagesSnapshot.docs.length;

      return {
        'total_users': totalUsers,
        'daily_active_users': dailyActiveUsers,
        'weekly_matches': weeklyMatches,
        'daily_messages': dailyMessages,
        'engagement_rate': totalUsers > 0 ? (dailyActiveUsers / totalUsers * 100).toStringAsFixed(2) : '0',
      };
    } catch (e) {
      logger.error('Failed to get analytics summary', error: e);
      return {};
    }
  }

  /// Clear user data from analytics (GDPR compliance)
  Future<void> clearUserAnalytics(String userId) async {
    try {
      await _analytics.setUserId(id: null);
      logger.info('Cleared analytics for user: $userId');
    } catch (e) {
      logger.error('Failed to clear user analytics', error: e);
    }
  }
}

// Global analytics instance
final analytics = AnalyticsService();
