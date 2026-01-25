import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/features/likes/models/boost_model.dart';

class BoostService {
  // Connect to the nam5 database instance where all users are stored
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get boost ad requirements based on duration
  Map<int, int> getBoostAdRequirements() {
    return {
      30: 3,   // 30 minutes = 3 ads
      60: 8,   // 1 hour = 8 ads
      120: 15, // 2 hours = 15 ads
    };
  }

  /// Check if user has Gold subscription (ad-free boost)
  Future<bool> hasGoldSubscription(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final subscriptionTier = userDoc.data()?['subscriptionTier'] as String? ?? 'free';
    final expiresAt = userDoc.data()?['subscriptionExpiresAt'] as Timestamp?;

    if (subscriptionTier == 'gold') {
      if (expiresAt == null) return true; // Lifetime subscription
      return DateTime.now().isBefore(expiresAt.toDate());
    }
    return false;
  }

  /// Get active boost for user
  Future<BoostModel?> getActiveBoost(String userId) async {
    final snapshot = await _firestore
        .collection('boosts')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final boost = BoostModel.fromFirestore(snapshot.docs.first);

    // Check if boost expired
    if (boost.isExpired) {
      await deactivateBoost(snapshot.docs.first.id);
      return null;
    }

    return boost;
  }

  /// Create a new boost
  Future<String> createBoost({
    required String userId,
    required int durationMinutes,
    required int adsWatched,
  }) async {
    logger.info('BoostService.createBoost: Starting for user $userId, duration: $durationMinutes min, ads: $adsWatched');

    // Deactivate any existing active boosts
    logger.info('BoostService: Checking for existing active boosts...');
    final existingBoosts = await _firestore
        .collection('boosts')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    logger.info('BoostService: Found ${existingBoosts.docs.length} existing active boosts');
    for (var doc in existingBoosts.docs) {
      logger.info('BoostService: Deactivating boost ${doc.id}');
      await doc.reference.update({'isActive': false});
    }

    // Create new boost
    final now = DateTime.now();
    final endTime = now.add(Duration(minutes: durationMinutes));
    logger.info('BoostService: Creating boost from $now to $endTime');

    final boostRef = await _firestore.collection('boosts').add({
      'userId': userId,
      'startTime': Timestamp.fromDate(now),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'adsWatched': adsWatched,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    logger.info('BoostService: Boost created with ID: ${boostRef.id}');

    // Update user profile with boost status
    logger.info('BoostService: Updating user profile...');
    await _firestore.collection('users').doc(userId).update({
      'isBoosted': true,
      'boostEndTime': Timestamp.fromDate(endTime),
      'lastBoostTime': FieldValue.serverTimestamp(),
    });
    logger.info('BoostService: User profile updated');

    // Log analytics
    logger.info('BoostService: Logging analytics...');
    await _firestore.collection('analytics').add({
      'userId': userId,
      'action': 'activate_boost',
      'durationMinutes': durationMinutes,
      'adsWatched': adsWatched,
      'timestamp': FieldValue.serverTimestamp(),
    });
    logger.info('BoostService: Boost creation complete!');

    return boostRef.id;
  }

  /// Deactivate a boost
  Future<void> deactivateBoost(String boostId) async {
    final boostDoc = await _firestore.collection('boosts').doc(boostId).get();
    final userId = boostDoc.data()?['userId'] as String?;

    await _firestore.collection('boosts').doc(boostId).update({
      'isActive': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
    });

    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'isBoosted': false,
        'boostEndTime': null,
      });
    }
  }

  /// Record ad watch for boost
  Future<void> recordAdWatchForBoost(String userId, int adsWatched, int durationMinutes) async {
    await _firestore.collection('analytics').add({
      'userId': userId,
      'action': 'watch_ad_for_boost',
      'adsWatched': adsWatched,
      'durationMinutes': durationMinutes,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream active boost status
  Stream<BoostModel?> watchActiveBoost(String userId) {
    return _firestore
        .collection('boosts')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return null;

      final boost = BoostModel.fromFirestore(snapshot.docs.first);

      // Auto-deactivate if expired
      if (boost.isExpired) {
        await deactivateBoost(snapshot.docs.first.id);
        return null;
      }

      return boost;
    });
  }
}
