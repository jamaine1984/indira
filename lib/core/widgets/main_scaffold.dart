import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';

class MainScaffold extends ConsumerWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTabChanged;

  const MainScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = AuthService().currentUser;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.neutralWhite,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowSoft.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.explore_rounded,
                  label: 'Discover',
                  isSelected: currentIndex == 0,
                  onTap: () => onTabChanged(0),
                ),
                _NavItem(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Gifts',
                  isSelected: currentIndex == 1,
                  onTap: () => onTabChanged(1),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  isSelected: currentIndex == 2,
                  onTap: () => onTabChanged(2),
                  badgeStream: currentUser != null
                      ? FirebaseFirestore.instance
                          .collection('chats')
                          .where('participants',
                              arrayContains: currentUser.uid)
                          .where('hasUnread_${currentUser.uid}',
                              isEqualTo: true)
                          .snapshots()
                      : null,
                ),
                _NavItem(
                  icon: Icons.groups_rounded,
                  label: 'Social',
                  isSelected: currentIndex == 3,
                  onTap: () => onTabChanged(3),
                ),
                _NavItem(
                  icon: Icons.sports_esports_rounded,
                  label: 'Fun',
                  isSelected: currentIndex == 4,
                  onTap: () => onTabChanged(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Stream<QuerySnapshot>? badgeStream;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeStream,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected
                        ? AppTheme.primaryRose
                        : AppTheme.secondaryPlum.withOpacity(0.5),
                  ),
                ),
                if (badgeStream != null)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: badgeStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? AppTheme.primaryRose
                    : AppTheme.secondaryPlum.withOpacity(0.5),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
