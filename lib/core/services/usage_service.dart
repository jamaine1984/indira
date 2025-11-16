import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/models/subscription_tier.dart';

class UsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user can send a message
  Future<bool> canSendMessage(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyMessages == -1) return true; // Unlimited

    return (usage['messagesSent'] as int? ?? 0) < limits.dailyMessages;
  }

  // Check if user can send a like
  Future<bool> canSendLike(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyLikes == -1) return true; // Unlimited

    return (usage['likesSent'] as int? ?? 0) < limits.dailyLikes;
  }

  // Increment message count
  Future<void> incrementMessageCount(String userId) async {
    final today = _getTodayKey();
    await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
      'messagesSent': FieldValue.increment(1),
      'date': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // Increment like count
  Future<void> incrementLikeCount(String userId) async {
    final today = _getTodayKey();
    await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
      'likesSent': FieldValue.increment(1),
      'date': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // Refill messages by watching ads
  Future<void> refillMessages(String userId, int adsWatched) async {
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (adsWatched >= limits.adsToRefill) {
      // Reset message count for today
      final today = _getTodayKey();
      await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
        'messagesSent': 0,
        'lastMessageRefill': DateTime.now(),
      }, SetOptions(merge: true));
    }
  }

  // Refill likes by watching ads
  Future<void> refillLikes(String userId, int adsWatched) async {
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (adsWatched >= limits.adsToRefill) {
      // Reset like count for today
      final today = _getTodayKey();
      await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
        'likesSent': 0,
        'lastLikeRefill': DateTime.now(),
      }, SetOptions(merge: true));
    }
  }

  // Get today's usage stats
  Future<Map<String, int>> getTodayUsage(String userId) async {
    return await _getTodayUsage(userId);
  }

  // Get remaining messages for today
  Future<int> getRemainingMessages(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyMessages == -1) return -1; // Unlimited

    final messagesSent = usage['messagesSent'] as int? ?? 0;
    final remaining = limits.dailyMessages - messagesSent;
    return remaining < 0 ? 0 : remaining;
  }

  // Get remaining likes for today
  Future<int> getRemainingLikes(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyLikes == -1) return -1; // Unlimited

    final likesSent = usage['likesSent'] as int? ?? 0;
    final remaining = limits.dailyLikes - likesSent;
    return remaining < 0 ? 0 : remaining;
  }

  // Private helper methods
  Future<Map<String, int>> _getTodayUsage(String userId) async {
    final today = _getTodayKey();
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('usage')
        .doc(today)
        .get();

    if (!doc.exists) {
      return {'messagesSent': 0, 'likesSent': 0};
    }

    final data = doc.data()!;
    return {
      'messagesSent': data['messagesSent'] ?? 0,
      'likesSent': data['likesSent'] ?? 0,
    };
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }

  SubscriptionTier _getUserTier(Map<String, dynamic> userData) {
    final tierString = userData['subscriptionTier'] as String?;
    switch (tierString) {
      case 'silver':
        return SubscriptionTier.silver;
      case 'gold':
        return SubscriptionTier.gold;
      default:
        return SubscriptionTier.free;
    }
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
