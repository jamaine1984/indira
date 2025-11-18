import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/likes/providers/boost_provider.dart';
import 'package:indira_love/features/likes/presentation/widgets/boost_dialog.dart';

class BoostTimerWidget extends ConsumerStatefulWidget {
  const BoostTimerWidget({super.key});

  @override
  ConsumerState<BoostTimerWidget> createState() => _BoostTimerWidgetState();
}

class _BoostTimerWidgetState extends ConsumerState<BoostTimerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBoostAsync = ref.watch(activeBoostProvider);

    return activeBoostAsync.when(
      data: (boost) {
        if (boost == null || boost.isExpired) {
          // No active boost - show button to activate boost
          return _buildActivateBoostButton();
        } else {
          // Active boost - show timer
          return _buildActiveBoostTimer(boost.remainingTime);
        }
      },
      loading: () => const SizedBox(),
      error: (_, __) => _buildActivateBoostButton(),
    );
  }

  Widget _buildActivateBoostButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () => showBoostDialog(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRose,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.rocket_launch, size: 24),
          label: const Text(
            'Boost Your Profile',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveBoostTimer(Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    final timeString = '${minutes}m ${seconds}s';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryRose,
              AppTheme.secondaryPlum,
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.rocket_launch,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Boosted',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  timeString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
