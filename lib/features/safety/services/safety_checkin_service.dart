import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

class SafetyCheckinService {
  static final SafetyCheckinService _instance = SafetyCheckinService._();
  factory SafetyCheckinService() => _instance;
  SafetyCheckinService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Create a safety check-in for a date
  Future<String> createCheckin({
    required String trustedContactName,
    required String trustedContactPhone,
    required String dateLocation,
    required int durationMinutes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      final checkInTime = DateTime.now();
      final expectedEndTime = checkInTime.add(Duration(minutes: durationMinutes));

      final doc = await _firestore.collection('safety_checkins').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'trustedContactName': trustedContactName,
        'trustedContactPhone': trustedContactPhone,
        'dateLocation': dateLocation,
        'durationMinutes': durationMinutes,
        'checkInTime': FieldValue.serverTimestamp(),
        'expectedEndTime': Timestamp.fromDate(expectedEndTime),
        'status': 'active', // active, checked_in, expired, sos
        'checkedInAt': null,
      });

      logger.info('Safety check-in created: ${doc.id}');
      return doc.id;
    } catch (e) {
      logger.error('Error creating check-in: $e');
      rethrow;
    }
  }

  /// Mark user as safe (checked in)
  Future<void> markSafe(String checkinId) async {
    await _firestore.collection('safety_checkins').doc(checkinId).update({
      'status': 'checked_in',
      'checkedInAt': FieldValue.serverTimestamp(),
    });
  }

  /// Trigger SOS alert
  Future<void> triggerSOS(String checkinId) async {
    await _firestore.collection('safety_checkins').doc(checkinId).update({
      'status': 'sos',
      'sosTriggeredAt': FieldValue.serverTimestamp(),
    });
    // In production, this would trigger SMS/call to trusted contact
  }

  /// Get active check-in
  Future<Map<String, dynamic>?> getActiveCheckin() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _firestore
        .collection('safety_checkins')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .orderBy('checkInTime', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return {'id': snap.docs.first.id, ...snap.docs.first.data()};
  }
}
