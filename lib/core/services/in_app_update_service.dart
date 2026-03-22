import 'dart:io';
import 'package:in_app_update/in_app_update.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Handles Play Store in-app updates and in-app review prompts.
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  static const _firstOpenKey = 'first_open_timestamp';
  static const _reviewShownKey = 'in_app_review_shown';

  /// Check for a Play Store update and install it without leaving the app.
  /// Android-only; no-op on iOS.
  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      logger.info('In-app update check skipped: $e');
    }
  }

  /// Show the native Play Store / App Store review dialog if the user
  /// has been on the app for at least 1 day and hasn't been prompted yet.
  Future<void> requestReviewIfEligible() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Record the first-open timestamp if not already set.
      final firstOpen = prefs.getInt(_firstOpenKey);
      if (firstOpen == null) {
        await prefs.setInt(
            _firstOpenKey, DateTime.now().millisecondsSinceEpoch);
        return; // Just installed — too early to ask.
      }

      // Already shown the review prompt — don't nag.
      if (prefs.getBool(_reviewShownKey) == true) return;

      // Check if at least 24 hours have passed since first open.
      final firstOpenDate =
          DateTime.fromMillisecondsSinceEpoch(firstOpen);
      final elapsed = DateTime.now().difference(firstOpenDate);
      if (elapsed.inHours < 24) return;

      final reviewer = InAppReview.instance;
      if (await reviewer.isAvailable()) {
        await reviewer.requestReview();
        await prefs.setBool(_reviewShownKey, true);
        logger.info('In-app review requested');
      }
    } catch (e) {
      logger.info('In-app review skipped: $e');
    }
  }
}
