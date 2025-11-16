import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // You can show a notification here if needed
}

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

  /// Initialize push notifications
  Future<void> initialize() async {
    if (_initialized) return;

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await _requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined or has not accepted push notifications');
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

    _initialized = true;
    print('Push notifications initialized successfully');
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

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': fcmToken,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });

    print('FCM Token saved: $fcmToken');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Indira Love',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Handle message when app is opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.messageId}');
    // TODO: Navigate to appropriate screen based on message data
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

  /// Send like notification
  Future<void> sendLikeNotification(String likedUserId, String userName) async {
    await sendNotification(
      recipientUserId: likedUserId,
      title: 'Someone likes you!',
      body: '$userName liked your profile',
      type: 'like',
      data: {'likerId': _auth.currentUser?.uid ?? ''},
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
}
