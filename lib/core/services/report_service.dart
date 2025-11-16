import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum ReportReason {
  inappropriate,
  harassment,
  spam,
  fake,
  offensive,
  scam,
  underage,
  other,
}

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Report a user for inappropriate behavior
  Future<void> reportUser({
    required String reportedUserId,
    required ReportReason reason,
    required String description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to report');
    }

    // Check if user has already reported this person
    final existingReport = await _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: currentUser.uid)
        .where('reportedUserId', isEqualTo: reportedUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingReport.docs.isNotEmpty) {
      throw Exception('You have already reported this user');
    }

    // Create the report
    await _firestore.collection('reports').add({
      'reporterId': currentUser.uid,
      'reportedUserId': reportedUserId,
      'reason': reason.toString().split('.').last,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // pending, reviewed, actioned
      'type': 'user',
    });
  }

  /// Report a post for inappropriate content
  Future<void> reportPost({
    required String postId,
    required String postOwnerId,
    required ReportReason reason,
    required String description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to report');
    }

    // Check if user has already reported this post
    final existingReport = await _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: currentUser.uid)
        .where('postId', isEqualTo: postId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingReport.docs.isNotEmpty) {
      throw Exception('You have already reported this post');
    }

    // Create the report
    await _firestore.collection('reports').add({
      'reporterId': currentUser.uid,
      'reportedUserId': postOwnerId,
      'postId': postId,
      'reason': reason.toString().split('.').last,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'type': 'post',
    });
  }

  /// Report a message for inappropriate content
  Future<void> reportMessage({
    required String messageId,
    required String senderId,
    required String chatId,
    required ReportReason reason,
    required String description,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to report');
    }

    // Create the report
    await _firestore.collection('reports').add({
      'reporterId': currentUser.uid,
      'reportedUserId': senderId,
      'messageId': messageId,
      'chatId': chatId,
      'reason': reason.toString().split('.').last,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'type': 'message',
    });
  }

  /// Get all reports made by current user
  Stream<QuerySnapshot> getUserReports() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in');
    }

    return _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get report statistics for a user (admin function)
  Future<Map<String, dynamic>> getReportStats(String userId) async {
    final reports = await _firestore
        .collection('reports')
        .where('reportedUserId', isEqualTo: userId)
        .get();

    final pendingReports = reports.docs.where((doc) =>
      doc.data()['status'] == 'pending'
    ).length;

    final actionedReports = reports.docs.where((doc) =>
      doc.data()['status'] == 'actioned'
    ).length;

    return {
      'totalReports': reports.docs.length,
      'pendingReports': pendingReports,
      'actionedReports': actionedReports,
    };
  }

  /// Helper to get readable reason text
  static String getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.inappropriate:
        return 'Inappropriate content';
      case ReportReason.harassment:
        return 'Harassment or bullying';
      case ReportReason.spam:
        return 'Spam or advertising';
      case ReportReason.fake:
        return 'Fake profile';
      case ReportReason.offensive:
        return 'Offensive language';
      case ReportReason.scam:
        return 'Scam or fraud';
      case ReportReason.underage:
        return 'Underage user';
      case ReportReason.other:
        return 'Other';
    }
  }
}
