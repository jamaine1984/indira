import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/models/subscription_tier.dart';

class UsageService {
  // Connect to the nam5 database instance where all users are stored
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

  // Check if user can use a rewind
  Future<bool> canRewind(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyRewinds == -1) return true; // Unlimited

    return (usage['rewindsUsed'] as int? ?? 0) < limits.dailyRewinds;
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

  // Increment rewind count
  Future<void> incrementRewindCount(String userId) async {
    final today = _getTodayKey();
    await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
      'rewindsUsed': FieldValue.increment(1),
      'date': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // Check if user can send a voice note
  Future<bool> canSendVoiceNote(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyVoiceNotes == -1) return true; // Unlimited

    return (usage['voiceNotesSent'] as int? ?? 0) < limits.dailyVoiceNotes;
  }

  // Increment voice note count
  Future<void> incrementVoiceNoteCount(String userId) async {
    final today = _getTodayKey();
    await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
      'voiceNotesSent': FieldValue.increment(1),
      'date': DateTime.now(),
    }, SetOptions(merge: true));
  }

  // Refill voice notes by watching ads
  Future<void> refillVoiceNotes(String userId, int adsWatched) async {
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (adsWatched >= limits.adsToRefill) {
      final today = _getTodayKey();
      await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
        'voiceNotesSent': 0,
        'lastVoiceNoteRefill': DateTime.now(),
      }, SetOptions(merge: true));
    }
  }

  // Get remaining voice notes for today
  Future<int> getRemainingVoiceNotes(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyVoiceNotes == -1) return -1; // Unlimited

    final voiceNotesSent = usage['voiceNotesSent'] as int? ?? 0;
    final remaining = limits.dailyVoiceNotes - voiceNotesSent;
    return remaining < 0 ? 0 : remaining;
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

  // Refill rewinds by watching ads
  Future<void> refillRewinds(String userId, int adsWatched) async {
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (adsWatched >= limits.adsToRefill) {
      final today = _getTodayKey();
      await _firestore.collection('users').doc(userId).collection('usage').doc(today).set({
        'rewindsUsed': 0,
        'lastRewindRefill': DateTime.now(),
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

  // Get remaining rewinds for today
  Future<int> getRemainingRewinds(String userId) async {
    final usage = await _getTodayUsage(userId);
    final user = await _getUserData(userId);
    final tier = _getUserTier(user);
    final limits = SubscriptionLimits.fromTier(tier);

    if (limits.dailyRewinds == -1) return -1; // Unlimited

    final rewindsUsed = usage['rewindsUsed'] as int? ?? 0;
    final remaining = limits.dailyRewinds - rewindsUsed;
    return remaining < 0 ? 0 : remaining;
  }

  // ===== VIDEO CALL MINUTES =====

  // Get total available video minutes (in seconds) - subscription + consumable
  Future<Map<String, int>> getVideoMinuteBalance(String userId) async {
    final data = await _getUserData(userId);
    return {
      'consumableVideoMinutes': (data['consumableVideoMinutes'] as int?) ?? 0,
      'subscriptionVideoMinutes': (data['subscriptionVideoMinutes'] as int?) ?? 0,
    };
  }

  // Check if user has enough minutes for a call
  Future<bool> canMakeCall(String userId) async {
    final balance = await getVideoMinuteBalance(userId);
    final total = (balance['consumableVideoMinutes'] ?? 0) +
        (balance['subscriptionVideoMinutes'] ?? 0);
    return total > 0;
  }

  // Deduct video minutes after a call ends (subscription minutes first, then consumable)
  Future<void> deductCallMinutes(String userId, int durationSeconds) async {
    if (durationSeconds <= 0) return;

    final balance = await getVideoMinuteBalance(userId);
    int subMinutes = balance['subscriptionVideoMinutes'] ?? 0;
    int conMinutes = balance['consumableVideoMinutes'] ?? 0;

    int remaining = durationSeconds;

    // Deduct from subscription first
    if (subMinutes > 0) {
      final deductFromSub = remaining > subMinutes ? subMinutes : remaining;
      subMinutes -= deductFromSub;
      remaining -= deductFromSub;
    }

    // Then deduct from consumable
    if (remaining > 0 && conMinutes > 0) {
      final deductFromCon = remaining > conMinutes ? conMinutes : remaining;
      conMinutes -= deductFromCon;
      remaining -= deductFromCon;
    }

    await _firestore.collection('users').doc(userId).update({
      'subscriptionVideoMinutes': subMinutes,
      'consumableVideoMinutes': conMinutes,
    });

    // Also track monthly usage
    await incrementCallMinutesUsed(userId, durationSeconds);
  }

  // Get monthly call minutes used (for display purposes)
  Future<int> getMonthlyCallMinutesUsed(String userId) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('usage')
        .doc('callMinutes_$monthKey')
        .get();

    if (!doc.exists) return 0;
    return (doc.data()?['totalSeconds'] as int?) ?? 0;
  }

  // Increment monthly call minutes tracking
  Future<void> incrementCallMinutesUsed(String userId, int seconds) async {
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('usage')
        .doc('callMinutes_$monthKey')
        .set({
      'totalSeconds': FieldValue.increment(seconds),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      return {'messagesSent': 0, 'likesSent': 0, 'rewindsUsed': 0, 'voiceNotesSent': 0};
    }

    final data = doc.data()!;
    return {
      'messagesSent': data['messagesSent'] ?? 0,
      'likesSent': data['likesSent'] ?? 0,
      'rewindsUsed': data['rewindsUsed'] ?? 0,
      'voiceNotesSent': data['voiceNotesSent'] ?? 0,
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
