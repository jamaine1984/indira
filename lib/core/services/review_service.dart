import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Google Play In-App Review trigger.
/// Shows review prompt 1 day after user signup.
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  /// Check if it's time to show review and trigger it.
  /// Call this on app startup (after auth is confirmed).
  Future<void> checkAndRequestReview() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;
      final data = userDoc.data()!;

      // Check if already reviewed
      if (data['hasReviewed'] == true) return;

      // Check account creation date
      final createdAt = data['createdAt'] as Timestamp?;
      if (createdAt == null) return;

      final accountAge = DateTime.now().difference(createdAt.toDate());

      // Show review after 1 day (24 hours)
      if (accountAge.inHours >= 24) {
        final isAvailable = await _inAppReview.isAvailable();
        if (isAvailable) {
          await _inAppReview.requestReview();

          // Mark as reviewed so we don't ask again
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'hasReviewed': true});

          logger.info('In-app review requested successfully');
        }
      }
    } catch (e) {
      logger.error('Error requesting in-app review: $e');
    }
  }
}

final reviewService = ReviewService();
