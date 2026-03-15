import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.debug('Handling background message: ${message.messageId}', tag: 'PushNotifications');
  // You can show a notification here if needed
}

/// Default notification preferences for new users
const Map<String, dynamic> defaultNotificationPreferences = {
  'likesEnabled': true,
  'matchesEnabled': true,
  'messagesEnabled': true,
  'promotionsEnabled': false,
  'quietHoursStart': 23, // 11 PM
  'quietHoursEnd': 7, // 7 AM
};

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  /// Cached notification preferences
  Map<String, dynamic> _cachedPreferences = {...defaultNotificationPreferences};

  /// Pending like notifications for batching (keyed by recipientUserId)
  final Map<String, List<Map<String, dynamic>>> _pendingLikeBatch = {};

  /// Queue of notifications held during quiet hours
  final List<Map<String, dynamic>> _quietHoursQueue = [];

  /// Initialize push notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await _requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      logger.warning('User declined or has not accepted push notifications', tag: 'PushNotifications');
      return;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token and save to Firestore
    await _saveTokenToDatabase();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Load notification preferences from Firestore
    await _loadNotificationPreferences();

    // Schedule quiet hours queue flush
    _scheduleQuietHoursFlush();

    _initialized = true;
    logger.info('Push notifications initialized successfully', tag: 'PushNotifications');
  }

  /// Request notification permission
  Future<NotificationSettings> _requestPermission() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToDatabase([String? token]) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final fcmToken = token ?? await _firebaseMessaging.getToken();
    if (fcmToken == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': fcmToken,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    logger.logSecurityEvent('FCM Token updated', details: {'platform': Platform.isIOS ? 'ios' : 'android'});
  }

  /// Handle foreground messages with preference checks and quiet hours
  void _handleForegroundMessage(RemoteMessage message) {
    logger.debug('Received foreground message: ${message.messageId}', tag: 'PushNotifications');

    final notification = message.notification;
    final type = message.data['type'] as String?;

    // Check if this notification type is enabled
    if (!_isNotificationTypeEnabled(type)) {
      logger.debug('Notification type "$type" is disabled by user preferences', tag: 'PushNotifications');
      return;
    }

    if (notification != null) {
      final title = notification.title ?? 'Indira Love';
      final body = notification.body ?? '';
      final payload = message.data.toString();

      // Check quiet hours - queue if in quiet period
      if (_isInQuietHours()) {
        logger.debug('In quiet hours, queuing notification', tag: 'PushNotifications');
        _quietHoursQueue.add({
          'title': title,
          'body': body,
          'payload': payload,
          'type': type,
        });
        return;
      }

      _showLocalNotification(
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  // Global navigator key for notification navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    logger.logUserAction('notification_tapped', details: {'payload': response.payload});
    _navigateFromPayload(response.payload);
  }

  /// Handle message when app is opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    logger.logUserAction('notification_opened_app', details: {'messageId': message.messageId});
    final type = message.data['type'] as String?;
    final targetId = message.data['senderId'] ?? message.data['matchedUserId'] ?? message.data['likerId'];
    _navigateByType(type, targetId);
  }

  /// Navigate based on notification payload string
  void _navigateFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    // Payload is data.toString() map - parse type if present
    if (payload.contains('match')) {
      _navigateByType('match', null);
    } else if (payload.contains('message')) {
      _navigateByType('message', null);
    } else if (payload.contains('like')) {
      _navigateByType('like', null);
    }
  }

  /// Navigate by notification type
  void _navigateByType(String? type, String? targetId) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      case 'match':
        navigatorKey.currentState?.pushNamed('/matches');
        break;
      case 'message':
        if (targetId != null) {
          navigatorKey.currentState?.pushNamed('/conversation/$targetId');
        } else {
          navigatorKey.currentState?.pushNamed('/messages');
        }
        break;
      case 'like':
        navigatorKey.currentState?.pushNamed('/likes');
        break;
      default:
        break;
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'indira_love_channel',
      'Indira Love Notifications',
      channelDescription: 'Notifications for matches, messages, and likes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Send notification to a user (called from backend/Cloud Functions)
  /// This method saves notification data to Firestore
  /// Cloud Functions will handle actual FCM sending
  Future<void> sendNotification({
    required String recipientUserId,
    required String title,
    required String body,
    required String type, // 'match', 'message', 'like', etc.
    Map<String, dynamic>? data,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Save notification to Firestore
    // Cloud Functions will pick this up and send via FCM
    await _firestore.collection('notifications').add({
      'recipientId': recipientUserId,
      'senderId': currentUser.uid,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'sent': false, // Will be set to true by Cloud Functions
    });
  }

  /// Send match notification
  Future<void> sendMatchNotification(String matchedUserId, String userName) async {
    await sendNotification(
      recipientUserId: matchedUserId,
      title: 'New Match!',
      body: 'You matched with $userName',
      type: 'match',
      data: {'matchedUserId': matchedUserId},
    );
  }

  /// Send message notification
  Future<void> sendMessageNotification(
    String recipientUserId,
    String senderName,
    String messagePreview,
  ) async {
    await sendNotification(
      recipientUserId: recipientUserId,
      title: senderName,
      body: messagePreview,
      type: 'message',
      data: {'senderId': _auth.currentUser?.uid ?? ''},
    );
  }

  /// Send like notification with smart batching
  ///
  /// Instead of sending individual notifications for each like, this method
  /// batches likes and sends a single summary notification after a short delay.
  /// e.g., "You have 5 new likes!" instead of 5 separate notifications.
  Future<void> sendLikeNotification(String likedUserId, String userName) async {
    // Add to pending batch
    _pendingLikeBatch.putIfAbsent(likedUserId, () => []);
    _pendingLikeBatch[likedUserId]!.add({
      'userName': userName,
      'likerId': _auth.currentUser?.uid ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });

    // If this is the first like in the batch, schedule the batch send
    if (_pendingLikeBatch[likedUserId]!.length == 1) {
      // Wait 30 seconds to collect more likes before sending
      Future.delayed(const Duration(seconds: 30), () async {
        await _flushLikeBatch(likedUserId);
      });
    }
  }

  /// Flush pending like notifications as a batched summary
  Future<void> _flushLikeBatch(String recipientUserId) async {
    final pending = _pendingLikeBatch.remove(recipientUserId);
    if (pending == null || pending.isEmpty) return;

    final String title;
    final String body;

    if (pending.length == 1) {
      title = 'Someone likes you!';
      body = '${pending.first['userName']} liked your profile';
    } else {
      title = 'You have ${pending.length} new likes!';
      final firstName = pending.first['userName'] as String;
      body = '$firstName and ${pending.length - 1} others liked your profile';
    }

    await sendNotification(
      recipientUserId: recipientUserId,
      title: title,
      body: body,
      type: 'like',
      data: {
        'likerId': pending.last['likerId'] ?? '',
        'batchCount': pending.length,
      },
    );
  }

  /// Get user notifications stream
  Stream<QuerySnapshot> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Delete FCM token on logout
  Future<void> deleteToken() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firebaseMessaging.deleteToken();

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }

  // ---------------------------------------------------------------------------
  // Notification Preferences
  // ---------------------------------------------------------------------------

  /// Load notification preferences from Firestore into cache
  Future<void> _loadNotificationPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data.containsKey('notificationPreferences')) {
        final prefs = Map<String, dynamic>.from(data['notificationPreferences'] as Map);
        _cachedPreferences = {...defaultNotificationPreferences, ...prefs};
      } else {
        // Initialize default preferences in Firestore
        _cachedPreferences = {...defaultNotificationPreferences};
        await _firestore.collection('users').doc(user.uid).set({
          'notificationPreferences': defaultNotificationPreferences,
        }, SetOptions(merge: true));
      }
      logger.debug('Loaded notification preferences: $_cachedPreferences', tag: 'PushNotifications');
    } catch (e) {
      logger.warning('Failed to load notification preferences: $e', tag: 'PushNotifications');
    }
  }

  /// Get current notification preferences
  Map<String, dynamic> getNotificationPreferences() {
    return Map.unmodifiable(_cachedPreferences);
  }

  /// Update notification preferences and persist to Firestore
  ///
  /// Accepts a partial map of preferences to update. Valid keys:
  /// - `likesEnabled` (bool)
  /// - `matchesEnabled` (bool)
  /// - `messagesEnabled` (bool)
  /// - `promotionsEnabled` (bool)
  /// - `quietHoursStart` (int, 0-23 hour)
  /// - `quietHoursEnd` (int, 0-23 hour)
  Future<void> updateNotificationPreferences(Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Merge updates into cache
    _cachedPreferences = {..._cachedPreferences, ...updates};

    // Persist to Firestore under notificationPreferences map
    final firestoreUpdate = <String, dynamic>{};
    for (final entry in updates.entries) {
      firestoreUpdate['notificationPreferences.${entry.key}'] = entry.value;
    }

    await _firestore.collection('users').doc(user.uid).update(firestoreUpdate);
    logger.info('Updated notification preferences: $updates', tag: 'PushNotifications');
  }

  /// Check if a notification type is enabled in user preferences
  bool _isNotificationTypeEnabled(String? type) {
    switch (type) {
      case 'like':
        return _cachedPreferences['likesEnabled'] == true;
      case 'match':
        return _cachedPreferences['matchesEnabled'] == true;
      case 'message':
        return _cachedPreferences['messagesEnabled'] == true;
      case 'promotion':
        return _cachedPreferences['promotionsEnabled'] == true;
      default:
        // Unknown types are allowed through by default
        return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Quiet Hours
  // ---------------------------------------------------------------------------

  /// Check if the current time falls within quiet hours
  bool _isInQuietHours() {
    final now = DateTime.now();
    final currentHour = now.hour;
    final start = _cachedPreferences['quietHoursStart'] as int? ?? 23;
    final end = _cachedPreferences['quietHoursEnd'] as int? ?? 7;

    if (start <= end) {
      // e.g., start=1, end=5 means quiet from 1am-5am
      return currentHour >= start && currentHour < end;
    } else {
      // e.g., start=23, end=7 means quiet from 11pm-7am (wraps midnight)
      return currentHour >= start || currentHour < end;
    }
  }

  /// Schedule a periodic timer that flushes the quiet hours queue
  /// when quiet hours end
  void _scheduleQuietHoursFlush() {
    // Check every 5 minutes whether quiet hours have ended
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (!_isInQuietHours() && _quietHoursQueue.isNotEmpty) {
        _deliverQueuedNotifications();
      }
    });
  }

  /// Deliver all notifications that were queued during quiet hours
  Future<void> _deliverQueuedNotifications() async {
    logger.info(
      'Delivering ${_quietHoursQueue.length} queued notifications after quiet hours',
      tag: 'PushNotifications',
    );

    final queued = List<Map<String, dynamic>>.from(_quietHoursQueue);
    _quietHoursQueue.clear();

    for (final notification in queued) {
      await _showLocalNotification(
        title: notification['title'] as String,
        body: notification['body'] as String,
        payload: notification['payload'] as String?,
      );
    }
  }
}
