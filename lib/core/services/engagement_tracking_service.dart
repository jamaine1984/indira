import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';

class EngagementTrackingService {
  static final EngagementTrackingService _instance =
      EngagementTrackingService._();
  factory EngagementTrackingService() => _instance;
  EngagementTrackingService._();

  final _firestore = FirebaseFirestore.instance;

  // View duration tracking
  DateTime? _viewStartTime;
  String? _currentViewerId;
  String? _currentViewedId;

  /// Start tracking when a user begins viewing a profile card
  void startViewingProfile(String viewerId, String viewedId) {
    _viewStartTime = DateTime.now();
    _currentViewerId = viewerId;
    _currentViewedId = viewedId;
  }

  /// Stop tracking and record the view duration
  Future<void> stopViewingProfile() async {
    if (_viewStartTime == null ||
        _currentViewerId == null ||
        _currentViewedId == null) return;

    final duration = DateTime.now().difference(_viewStartTime!);

    // Only record meaningful views (> 500ms)
    if (duration.inMilliseconds > 500) {
      try {
        await _firestore.collection('engagement_signals').add({
          'type': 'profile_view',
          'viewerId': _currentViewerId,
          'viewedId': _currentViewedId,
          'durationMs': duration.inMilliseconds,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        logger.error('Failed to record view duration', error: e);
      }
    }

    _viewStartTime = null;
    _currentViewerId = null;
    _currentViewedId = null;
  }

  /// Record swipe velocity (fast left = definite no, slow right = thoughtful yes)
  Future<void> recordSwipeVelocity(
    String userId,
    String targetId,
    String direction,
    double velocity,
  ) async {
    try {
      await _firestore.collection('engagement_signals').add({
        'type': 'swipe_velocity',
        'userId': userId,
        'targetId': targetId,
        'direction': direction,
        'velocity': velocity,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.error('Failed to record swipe velocity', error: e);
    }
  }

  /// Record when a user taps to view profile details (strong interest signal)
  Future<void> recordProfileDetailTap(String userId, String targetId) async {
    try {
      await _firestore.collection('engagement_signals').add({
        'type': 'profile_detail_tap',
        'userId': userId,
        'targetId': targetId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.error('Failed to record profile detail tap', error: e);
    }
  }

  /// Get engagement stats for a user (used by preference learning)
  Future<List<Map<String, dynamic>>> getRecentEngagements(
    String userId, {
    int limit = 200,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('engagement_signals')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      logger.error('Failed to get engagements', error: e);
      return [];
    }
  }
}
