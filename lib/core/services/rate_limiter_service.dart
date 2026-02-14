import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

/// Rate limiting service to prevent abuse and spam
/// Implements various rate limits for different actions
class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  factory RateLimiterService() => _instance;
  RateLimiterService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  SharedPreferences? _prefs;

  /// Initialize rate limiter
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      logger.info('RateLimiterService initialized successfully');
    } catch (e) {
      logger.error('Failed to initialize RateLimiterService', error: e);
    }
  }

  // Rate limit configurations
  static const int _maxSwipesPerHour = 100;
  static const int _maxSwipesPerDay = 500;
  static const int _maxLikesPerHour = 50;
  static const int _maxLikesPerDay = 200;
  static const int _maxSuperlikesPerDay = 5;
  static const int _maxMessagesPerMinute = 10;
  static const int _maxMessagesPerHour = 100;
  static const int _maxMessagesPerDay = 500;
  static const int _maxReportsPerDay = 10;
  static const int _maxProfileUpdatesPerHour = 5;
  static const int _maxPhotoUploadsPerDay = 20;
  static const int _maxGiftsPerHour = 10;
  static const int _maxGiftsPerDay = 50;
  static const int _maxMatchAttemptsPerMinute = 5;

  /// Check if user can perform swipe action
  Future<RateLimitResult> checkSwipeLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'swipe',
      hourLimit: _maxSwipesPerHour,
      dayLimit: _maxSwipesPerDay,
    );
  }

  /// Check if user can like
  Future<RateLimitResult> checkLikeLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'like',
      hourLimit: _maxLikesPerHour,
      dayLimit: _maxLikesPerDay,
    );
  }

  /// Check if user can superlike
  Future<RateLimitResult> checkSuperlikeLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'superlike',
      dayLimit: _maxSuperlikesPerDay,
    );
  }

  /// Check if user can send message
  Future<RateLimitResult> checkMessageLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'message',
      minuteLimit: _maxMessagesPerMinute,
      hourLimit: _maxMessagesPerHour,
      dayLimit: _maxMessagesPerDay,
    );
  }

  /// Check if user can report
  Future<RateLimitResult> checkReportLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'report',
      dayLimit: _maxReportsPerDay,
    );
  }

  /// Check if user can update profile
  Future<RateLimitResult> checkProfileUpdateLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'profile_update',
      hourLimit: _maxProfileUpdatesPerHour,
    );
  }

  /// Check if user can upload photo
  Future<RateLimitResult> checkPhotoUploadLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'photo_upload',
      dayLimit: _maxPhotoUploadsPerDay,
    );
  }

  /// Check if user can send gift
  Future<RateLimitResult> checkGiftLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'gift',
      hourLimit: _maxGiftsPerHour,
      dayLimit: _maxGiftsPerDay,
    );
  }

  /// Check if user can attempt match
  Future<RateLimitResult> checkMatchAttemptLimit(String userId) async {
    return await _checkLimit(
      userId: userId,
      action: 'match_attempt',
      minuteLimit: _maxMatchAttemptsPerMinute,
    );
  }

  /// Generic rate limit checker
  Future<RateLimitResult> _checkLimit({
    required String userId,
    required String action,
    int? minuteLimit,
    int? hourLimit,
    int? dayLimit,
  }) async {
    try {
      final now = DateTime.now();

      // Get user's action log from Firestore
      final actionLog = await _getUserActionLog(userId, action);

      // Check minute limit
      if (minuteLimit != null) {
        final minuteAgo = now.subtract(const Duration(minutes: 1));
        final actionsInLastMinute = actionLog.where((timestamp) => timestamp.isAfter(minuteAgo)).length;

        if (actionsInLastMinute >= minuteLimit) {
          logger.logSecurityEvent(
            'Rate limit exceeded',
            userId: userId,
            details: {
              'action': action,
              'limit_type': 'minute',
              'limit': minuteLimit,
              'actual': actionsInLastMinute,
            },
          );

          return RateLimitResult(
            allowed: false,
            reason: 'Too many $action actions. Please wait a minute.',
            retryAfter: 60,
            currentCount: actionsInLastMinute,
            limit: minuteLimit,
          );
        }
      }

      // Check hour limit
      if (hourLimit != null) {
        final hourAgo = now.subtract(const Duration(hours: 1));
        final actionsInLastHour = actionLog.where((timestamp) => timestamp.isAfter(hourAgo)).length;

        if (actionsInLastHour >= hourLimit) {
          logger.logSecurityEvent(
            'Rate limit exceeded',
            userId: userId,
            details: {
              'action': action,
              'limit_type': 'hour',
              'limit': hourLimit,
              'actual': actionsInLastHour,
            },
          );

          return RateLimitResult(
            allowed: false,
            reason: 'Hourly limit reached. Try again later.',
            retryAfter: 3600,
            currentCount: actionsInLastHour,
            limit: hourLimit,
          );
        }
      }

      // Check day limit
      if (dayLimit != null) {
        final dayAgo = now.subtract(const Duration(days: 1));
        final actionsInLastDay = actionLog.where((timestamp) => timestamp.isAfter(dayAgo)).length;

        if (actionsInLastDay >= dayLimit) {
          logger.logSecurityEvent(
            'Rate limit exceeded',
            userId: userId,
            details: {
              'action': action,
              'limit_type': 'day',
              'limit': dayLimit,
              'actual': actionsInLastDay,
            },
          );

          return RateLimitResult(
            allowed: false,
            reason: 'Daily limit reached. Come back tomorrow!',
            retryAfter: 86400,
            currentCount: actionsInLastDay,
            limit: dayLimit,
          );
        }
      }

      // Allowed - record the action
      await _recordAction(userId, action);

      return RateLimitResult(
        allowed: true,
        reason: 'Action allowed',
      );
    } catch (e) {
      logger.error('Failed to check rate limit', error: e);
      // Fail closed - deny action if rate limiting check fails (security)
      return RateLimitResult(allowed: false, reason: 'Rate limit check unavailable. Please try again.');
    }
  }

  /// Get user's action log from Firestore
  Future<List<DateTime>> _getUserActionLog(String userId, String action) async {
    try {
      final doc = await _firestore
          .collection('rate_limits')
          .doc('${userId}_$action')
          .get();

      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null) return [];

      final timestamps = data['timestamps'] as List<dynamic>? ?? [];
      return timestamps
          .map((ts) => (ts as Timestamp).toDate())
          .toList();
    } catch (e) {
      logger.error('Failed to get action log', error: e);
      return [];
    }
  }

  /// Record action in Firestore
  Future<void> _recordAction(String userId, String action) async {
    try {
      final docRef = _firestore.collection('rate_limits').doc('${userId}_$action');
      final now = DateTime.now();

      // Clean up old entries (keep last 24 hours only)
      final dayAgo = now.subtract(const Duration(days: 1));

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        List<Timestamp> timestamps = [];
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final existingTimestamps = data['timestamps'] as List<dynamic>? ?? [];
            timestamps = existingTimestamps
                .map((ts) => ts as Timestamp)
                .where((ts) => ts.toDate().isAfter(dayAgo))
                .toList();
          }
        }

        // Add new timestamp
        timestamps.add(Timestamp.fromDate(now));

        transaction.set(docRef, {
          'user_id': userId,
          'action': action,
          'timestamps': timestamps,
          'last_action': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      logger.error('Failed to record action', error: e);
    }
  }

  /// Check if user is temporarily banned
  Future<bool> isUserBanned(String userId) async {
    try {
      final doc = await _firestore.collection('user_bans').doc(userId).get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      final bannedUntil = (data['banned_until'] as Timestamp?)?.toDate();
      if (bannedUntil == null) return false;

      final now = DateTime.now();
      if (now.isBefore(bannedUntil)) {
        return true; // Still banned
      }

      // Ban expired, remove it
      await doc.reference.delete();
      return false;
    } catch (e) {
      logger.error('Failed to check ban status', error: e);
      return false;
    }
  }

  /// Temporarily ban user for abuse
  Future<void> banUser(String userId, int durationHours, String reason) async {
    try {
      final bannedUntil = DateTime.now().add(Duration(hours: durationHours));

      await _firestore.collection('user_bans').doc(userId).set({
        'user_id': userId,
        'banned_at': FieldValue.serverTimestamp(),
        'banned_until': Timestamp.fromDate(bannedUntil),
        'duration_hours': durationHours,
        'reason': reason,
      });

      logger.logSecurityEvent(
        'User banned',
        userId: userId,
        details: {
          'duration_hours': durationHours,
          'reason': reason,
        },
      );
    } catch (e) {
      logger.error('Failed to ban user', error: e);
    }
  }

  /// Unban user
  Future<void> unbanUser(String userId) async {
    try {
      await _firestore.collection('user_bans').doc(userId).delete();
      logger.info('User unbanned: $userId');
    } catch (e) {
      logger.error('Failed to unban user', error: e);
    }
  }

  /// Get remaining actions for user
  Future<Map<String, int>> getRemainingActions(String userId) async {
    try {
      final swipeLog = await _getUserActionLog(userId, 'swipe');
      final likeLog = await _getUserActionLog(userId, 'like');
      final superlikeLog = await _getUserActionLog(userId, 'superlike');
      final messageLog = await _getUserActionLog(userId, 'message');

      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final hourAgo = now.subtract(const Duration(hours: 1));

      return {
        'swipes_remaining_today': _maxSwipesPerDay - swipeLog.where((t) => t.isAfter(dayAgo)).length,
        'likes_remaining_today': _maxLikesPerDay - likeLog.where((t) => t.isAfter(dayAgo)).length,
        'superlikes_remaining_today': _maxSuperlikesPerDay - superlikeLog.where((t) => t.isAfter(dayAgo)).length,
        'messages_remaining_hour': _maxMessagesPerHour - messageLog.where((t) => t.isAfter(hourAgo)).length,
      };
    } catch (e) {
      logger.error('Failed to get remaining actions', error: e);
      return {};
    }
  }

  /// Clean up old rate limit data (run periodically)
  Future<void> cleanupOldData() async {
    try {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));

      final oldDocs = await _firestore
          .collection('rate_limits')
          .where('last_action', isLessThan: Timestamp.fromDate(twoDaysAgo))
          .get();

      for (final doc in oldDocs.docs) {
        await doc.reference.delete();
      }

      logger.info('Cleaned up ${oldDocs.docs.length} old rate limit records');
    } catch (e) {
      logger.error('Failed to cleanup old data', error: e);
    }
  }

  /// Increase limits for premium users
  int _getMultiplier(String? subscriptionTier) {
    switch (subscriptionTier) {
      case 'gold':
        return 2;
      case 'platinum':
        return 5;
      case 'diamond':
        return 10;
      default:
        return 1;
    }
  }

  /// Check rate limit with subscription tier consideration
  Future<RateLimitResult> checkLimitWithTier({
    required String userId,
    required String action,
    String? subscriptionTier,
    int? minuteLimit,
    int? hourLimit,
    int? dayLimit,
  }) async {
    final multiplier = _getMultiplier(subscriptionTier);

    return await _checkLimit(
      userId: userId,
      action: action,
      minuteLimit: minuteLimit != null ? minuteLimit * multiplier : null,
      hourLimit: hourLimit != null ? hourLimit * multiplier : null,
      dayLimit: dayLimit != null ? dayLimit * multiplier : null,
    );
  }
}

/// Rate limit check result
class RateLimitResult {
  final bool allowed;
  final String reason;
  final int? retryAfter; // Seconds until user can retry
  final int? currentCount;
  final int? limit;

  RateLimitResult({
    required this.allowed,
    required this.reason,
    this.retryAfter,
    this.currentCount,
    this.limit,
  });

  @override
  String toString() {
    if (allowed) return 'Allowed';
    return 'Rate limit exceeded: $reason (${currentCount ?? 0}/${limit ?? 0})';
  }
}

// Global rate limiter instance
final rateLimiter = RateLimiterService();
