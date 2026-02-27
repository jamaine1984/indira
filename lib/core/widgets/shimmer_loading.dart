import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:indira_love/core/theme/app_theme.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.accentGold.withOpacity(0.3),
      highlightColor: AppTheme.neutralWhite,
      child: child,
    );
  }

  /// Rounded rectangle matching swipe card dimensions
  static Widget card({double height = 500}) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  /// Circle avatar + 2 text lines (for list items)
  static Widget listTile() {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const CircleAvatar(radius: 28, backgroundColor: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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

  /// Full-height card skeleton (for profile cards in grids)
  static Widget profileCard({double height = 220}) {
    return ShimmerLoading(
      child: Container(
        height: height,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// Grid of profile card skeletons
  static Widget profileGrid({int count = 6}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (_, __) => profileCard(),
    );
  }

  /// List of listTile skeletons
  static Widget listLoading({int count = 8}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => listTile(),
    );
  }
}
