import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['isAdmin'] == true;
  }

  // Get all users with pagination
  Stream<QuerySnapshot> getAllUsers({int limit = 20}) {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Search users by name or email
  Stream<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
        .limit(20)
        .snapshots();
  }

  // Get user details
  Future<DocumentSnapshot> getUserDetails(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Block/unblock user
  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    await _firestore.collection('users').doc(userId).update({
      'isBlocked': isBlocked,
      'blockedAt': isBlocked ? FieldValue.serverTimestamp() : null,
    });
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    final batch = _firestore.batch();

    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete user's likes
    final likes = await _firestore
        .collection('likes')
        .where('likerId', isEqualTo: userId)
        .get();
    for (var doc in likes.docs) {
      batch.delete(doc.reference);
    }

    // Delete user's matches
    final matches = await _firestore
        .collection('matches')
        .where('users', arrayContains: userId)
        .get();
    for (var doc in matches.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Change user subscription
  Future<void> updateUserSubscription(
    String userId,
    String tier,
    DateTime? expiresAt,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'subscriptionTier': tier,
      'subscriptionExpiresAt': expiresAt,
    });
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics() async {
    // Total users
    final usersSnapshot = await _firestore.collection('users').count().get();
    final totalUsers = usersSnapshot.count ?? 0;

    // Active users (last 24 hours)
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    final activeUsersSnapshot = await _firestore
        .collection('users')
        .where('lastSeen', isGreaterThan: Timestamp.fromDate(yesterday))
        .count()
        .get();
    final activeUsers24h = activeUsersSnapshot.count ?? 0;

    // Active users (last 7 days)
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    final activeUsers7dSnapshot = await _firestore
        .collection('users')
        .where('lastSeen', isGreaterThan: Timestamp.fromDate(lastWeek))
        .count()
        .get();
    final activeUsers7d = activeUsers7dSnapshot.count ?? 0;

    // Active users (last 30 days)
    final lastMonth = DateTime.now().subtract(const Duration(days: 30));
    final activeUsers30dSnapshot = await _firestore
        .collection('users')
        .where('lastSeen', isGreaterThan: Timestamp.fromDate(lastMonth))
        .count()
        .get();
    final activeUsers30d = activeUsers30dSnapshot.count ?? 0;

    // Total matches
    final matchesSnapshot = await _firestore.collection('matches').count().get();
    final totalMatches = matchesSnapshot.count ?? 0;

    // Messages today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final messagesSnapshot = await _firestore
        .collectionGroup('messages')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .count()
        .get();
    final messagesToday = messagesSnapshot.count ?? 0;

    // Ads watched today
    final adsSnapshot = await _firestore
        .collection('analytics')
        .where('action', isEqualTo: 'watch_ad')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .count()
        .get();
    final adsToday = adsSnapshot.count ?? 0;

    // Total ads watched
    final totalAdsSnapshot = await _firestore
        .collection('analytics')
        .where('action', isEqualTo: 'watch_ad')
        .count()
        .get();
    final totalAds = totalAdsSnapshot.count ?? 0;

    return {
      'totalUsers': totalUsers,
      'activeUsers24h': activeUsers24h,
      'activeUsers7d': activeUsers7d,
      'activeUsers30d': activeUsers30d,
      'totalMatches': totalMatches,
      'messagesToday': messagesToday,
      'adsWatchedToday': adsToday,
      'totalAdsWatched': totalAds,
    };
  }

  // Get real-time ad watch stream
  Stream<QuerySnapshot> getAdWatchStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection('analytics')
        .where('action', isEqualTo: 'watch_ad')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  // Get all reports
  Stream<QuerySnapshot> getAllReports({String? status}) {
    Query query = _firestore
        .collection('reports')
        .orderBy('timestamp', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.limit(50).snapshots();
  }

  // Update report status
  Future<void> updateReportStatus(
    String reportId,
    String status, {
    String? adminNotes,
  }) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': _auth.currentUser?.uid,
      if (adminNotes != null) 'adminNotes': adminNotes,
    });
  }

  // Take action on reported user
  Future<void> takeReportAction(
    String reportId,
    String reportedUserId,
    String action,
  ) async {
    final batch = _firestore.batch();

    // Update report
    batch.update(_firestore.collection('reports').doc(reportId), {
      'status': 'actioned',
      'action': action,
      'actionedAt': FieldValue.serverTimestamp(),
      'actionedBy': _auth.currentUser?.uid,
    });

    // Take action on user
    switch (action) {
      case 'warn':
        batch.update(_firestore.collection('users').doc(reportedUserId), {
          'warnings': FieldValue.increment(1),
          'lastWarningAt': FieldValue.serverTimestamp(),
        });
        break;
      case 'suspend':
        final suspendUntil =
            DateTime.now().add(const Duration(days: 7));
        batch.update(_firestore.collection('users').doc(reportedUserId), {
          'isSuspended': true,
          'suspendedUntil': Timestamp.fromDate(suspendUntil),
          'suspendedAt': FieldValue.serverTimestamp(),
        });
        break;
      case 'ban':
        batch.update(_firestore.collection('users').doc(reportedUserId), {
          'isBanned': true,
          'bannedAt': FieldValue.serverTimestamp(),
        });
        break;
      case 'dismiss':
        // No action on user
        break;
    }

    await batch.commit();
  }

  // Get user growth data for chart
  Future<List<Map<String, dynamic>>> getUserGrowthData(int days) async {
    final List<Map<String, dynamic>> data = [];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .count()
          .get();

      data.add({
        'date': '${date.month}/${date.day}',
        'count': snapshot.count ?? 0,
      });
    }

    return data;
  }

  // Get user demographics
  Future<Map<String, dynamic>> getUserDemographics() async {
    final usersSnapshot = await _firestore.collection('users').get();

    final Map<String, int> genderCount = {};
    final Map<String, int> ageGroups = {
      '18-24': 0,
      '25-34': 0,
      '35-44': 0,
      '45-54': 0,
      '55+': 0,
    };

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();

      // Gender count
      final gender = data['gender'] as String? ?? 'Other';
      genderCount[gender] = (genderCount[gender] ?? 0) + 1;

      // Age groups
      final age = data['age'] as int? ?? 0;
      if (age >= 18 && age <= 24) {
        ageGroups['18-24'] = ageGroups['18-24']! + 1;
      } else if (age >= 25 && age <= 34) {
        ageGroups['25-34'] = ageGroups['25-34']! + 1;
      } else if (age >= 35 && age <= 44) {
        ageGroups['35-44'] = ageGroups['35-44']! + 1;
      } else if (age >= 45 && age <= 54) {
        ageGroups['45-54'] = ageGroups['45-54']! + 1;
      } else if (age >= 55) {
        ageGroups['55+'] = ageGroups['55+']! + 1;
      }
    }

    return {
      'genderCount': genderCount,
      'ageGroups': ageGroups,
    };
  }

  // Ban/unban user
  Future<void> toggleUserBan(String userId, bool isBanned) async {
    await _firestore.collection('users').doc(userId).update({
      'isBanned': isBanned,
      'bannedAt': isBanned ? FieldValue.serverTimestamp() : null,
    });
  }
}
