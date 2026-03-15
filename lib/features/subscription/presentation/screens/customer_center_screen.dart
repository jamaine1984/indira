import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Presents the RevenueCat Customer Center.
/// This allows users to manage their subscription, request cancellation,
/// and access support — all handled by RevenueCat's built-in UI.
///
/// Note: Customer Center is available on RevenueCat Pro and Enterprise plans.
class CustomerCenterScreen extends StatelessWidget {
  const CustomerCenterScreen({super.key});

  /// Present the RevenueCat Customer Center as a modal.
  static Future<void> show(BuildContext context) async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      logger.error('Error presenting Customer Center', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open subscription management. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CustomerCenterView();
  }
}
