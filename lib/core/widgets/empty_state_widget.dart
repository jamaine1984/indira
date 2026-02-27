import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:indira_love/core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.secondaryPlum,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textCharcoal.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              )
                  .animate()
                  .fadeIn(delay: 450.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }
}
