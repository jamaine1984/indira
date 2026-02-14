import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/widgets/watch_ads_dialog.dart';
import 'package:indira_love/core/services/location_service.dart';
import 'package:indira_love/features/discover/presentation/widgets/swipe_card.dart';
import 'package:indira_love/features/discover/presentation/providers/discover_provider.dart';
import 'package:indira_love/features/discover/presentation/screens/cultural_filters_screen.dart';
import 'package:indira_love/features/auth/presentation/providers/auth_provider.dart';
import 'package:indira_love/features/likes/presentation/widgets/boost_timer_widget.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CardSwiperController _swiperController = CardSwiperController();

  // Track the profile list snapshot for the swiper
  List<Map<String, dynamic>> _profiles = [];
  String? _profilesKey; // tracks which dataset we have

  // Swipe feedback overlay states
  bool _showLike = false;
  bool _showNope = false;
  bool _showSuperLike = false;

  // Match overlay
  bool _showMatchOverlay = false;
  Map<String, dynamic>? _matchedUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(discoverProvider);
      if (state.potentialMatches.isEmpty && !state.isLoading) {
        ref.read(discoverProvider.notifier).loadPotentialMatches();
      }
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _syncProfiles(List<Map<String, dynamic>> providerProfiles) {
    if (providerProfiles.isEmpty) return;

    final newKey =
        '${providerProfiles.length}_${providerProfiles.first['uid']}';

    if (_profilesKey == null) {
      // First load
      _profiles = providerProfiles.toList();
      _profilesKey = newKey;
      _swiperController = CardSwiperController();
    } else if (providerProfiles.length > _profiles.length) {
      // Pagination appended more profiles
      _profiles = providerProfiles.toList();
      _profilesKey = newKey;
    } else if (newKey != _profilesKey) {
      // Full reload (filters changed, etc.)
      _profiles = providerProfiles.toList();
      _profilesKey = newKey;
      _swiperController = CardSwiperController();
    }
  }

  void _flashOverlay(String type) {
    setState(() {
      _showLike = type == 'like';
      _showNope = type == 'nope';
      _showSuperLike = type == 'superlike';
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showLike = false;
          _showNope = false;
          _showSuperLike = false;
        });
      }
    });
  }

  Future<bool> _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (previousIndex >= _profiles.length) return false;

    final targetUser = _profiles[previousIndex];
    final targetUserId = targetUser['uid'] as String? ?? '';

    SwipeDirection swipeDir;

    switch (direction) {
      case CardSwiperDirection.right:
        _flashOverlay('like');
        swipeDir = SwipeDirection.right;
      case CardSwiperDirection.top:
        _flashOverlay('superlike');
        swipeDir = SwipeDirection.up;
      case CardSwiperDirection.left:
        _flashOverlay('nope');
        swipeDir = SwipeDirection.left;
      default:
        swipeDir = SwipeDirection.left;
    }

    // Process swipe via provider (doesn't modify the list)
    final isMatch = await ref
        .read(discoverProvider.notifier)
        .processSwipe(swipeDir, targetUserId);

    if (isMatch && mounted) {
      setState(() {
        _matchedUser = targetUser;
        _showMatchOverlay = true;
      });
    }

    // Prefetch more profiles when running low
    if (currentIndex != null && _profiles.length - currentIndex < 10) {
      final discoverState = ref.read(discoverProvider);
      if (discoverState.hasMoreUsers) {
        ref.read(discoverProvider.notifier).loadPotentialMatches(loadMore: true);
      }
    }

    return true;
  }

  void _onTapUndo() {
    _swiperController.undo();
  }

  void _onTapDislike() {
    _swiperController.swipe(CardSwiperDirection.left);
  }

  void _onTapSuperLike() {
    _swiperController.swipe(CardSwiperDirection.top);
  }

  void _onTapLike() {
    _swiperController.swipe(CardSwiperDirection.right);
  }

  void _onTapBoost() {
    context.push('/subscription');
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProvider);
    final currentUser = ref.watch(authProvider).user;

    // Sync profiles from provider
    _syncProfiles(discoverState.potentialMatches);

    // Show ad dialog when limit is reached
    if (discoverState.showLimitDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showWatchAdsDialog(
          context,
          type: 'likes',
          adsRequired: 3,
          onComplete: () {
            ref.read(discoverProvider.notifier).refillLikesAfterAds(3);
          },
        );
        ref.read(discoverProvider.notifier).dismissLimitDialog();
      });
    }

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildHamburgerMenu(context),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Top bar with logo and hamburger menu
              _buildTopBar(context),

              // Boost timer widget
              const BoostTimerWidget(),

              // Swipe cards area
              Expanded(
                child: discoverState.isLoading && _profiles.isEmpty
                    ? _buildLoadingState()
                    : _profiles.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              // Card swiper
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: CardSwiper(
                                    key: ValueKey(_profilesKey),
                                    controller: _swiperController,
                                    cardsCount: _profiles.length,
                                    numberOfCardsDisplayed:
                                        min(3, _profiles.length),
                                    backCardOffset: const Offset(0, -30),
                                    scale: 0.92,
                                    padding: EdgeInsets.zero,
                                    isLoop: false,
                                    allowedSwipeDirection:
                                        const AllowedSwipeDirection.only(
                                      left: true,
                                      right: true,
                                      up: true,
                                    ),
                                    onSwipe: _onSwipe,
                                    onEnd: () {
                                      final state = ref.read(discoverProvider);
                                      if (state.hasMoreUsers) {
                                        ref
                                            .read(discoverProvider.notifier)
                                            .loadPotentialMatches(
                                                loadMore: true);
                                      }
                                    },
                                    cardBuilder: (context, index,
                                        horizontalOffsetPercentage,
                                        verticalOffsetPercentage) {
                                      if (index >= _profiles.length) {
                                        return const SizedBox();
                                      }
                                      // 3D perspective transform during swipe
                                      return Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.001)
                                          ..rotateY(
                                              horizontalOffsetPercentage *
                                                  0.006),
                                        child: ProfileCard(
                                          user: _profiles[index],
                                          onTap: () => context.push(
                                              '/user-profile/${_profiles[index]['uid']}'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              // Action buttons
                              _ActionButtonRow(
                                onUndo: _onTapUndo,
                                onDislike: _onTapDislike,
                                onSuperLike: _onTapSuperLike,
                                onLike: _onTapLike,
                                onBoost: _onTapBoost,
                              ),

                              const SizedBox(height: 12),
                            ],
                          ),
              ),
            ],
          ),

          // Swipe feedback overlays
          if (_showLike)
            _SwipeFeedback(
              icon: Icons.favorite_rounded,
              color: const Color(0xFF22C55E),
              label: 'LIKE',
            ),
          if (_showNope)
            _SwipeFeedback(
              icon: Icons.close_rounded,
              color: AppTheme.primaryRose,
              label: 'NOPE',
            ),
          if (_showSuperLike)
            _SwipeFeedback(
              icon: Icons.star_rounded,
              color: AppTheme.accentGold,
              label: 'SUPER LIKE',
            ),

          // Match celebration overlay
          if (_showMatchOverlay && _matchedUser != null)
            _MatchOverlay(
              matchedUser: _matchedUser!,
              currentUser: currentUser,
              onSendMessage: () {
                setState(() => _showMatchOverlay = false);
                context.push('/messages');
              },
              onKeepSwiping: () {
                setState(() {
                  _showMatchOverlay = false;
                  _matchedUser = null;
                });
              },
            ),
        ],
      ),
    );
  }

  // ─── Top Bar ────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRose.withOpacity(0.8),
            AppTheme.secondaryPlum.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Indira Love',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.filter_list,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CulturalFiltersScreen(),
                        ),
                      );
                      // Reset profile tracking so swiper rebuilds
                      _profilesKey = null;
                      ref
                          .read(discoverProvider.notifier)
                          .loadPotentialMatches();
                    },
                    tooltip: 'Cultural Filters',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Loading State ──────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.romanticGradient,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Finding your matches...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ────────────────────────────────────────────

  Widget _buildEmptyState() {
    final discoverState = ref.watch(discoverProvider);
    final hasError =
        discoverState.error != null && discoverState.error!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.romanticGradient,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.explore_off_rounded,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 24),
              Text(
                hasError ? 'Oops!' : 'No More Profiles',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  discoverState.error ??
                      'No more profiles nearby!\nTry adjusting your filters.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Troubleshooting:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Check your internet connection\n'
                        '• Make sure there are users in the database\n'
                        '• Try logging out and back in\n'
                        '• Contact support if issue persists',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  _profilesKey = null;
                  ref
                      .read(discoverProvider.notifier)
                      .loadPotentialMatches();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hamburger Menu ─────────────────────────────────────────

  Widget _buildHamburgerMenu(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30, thickness: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildMenuItem(
                      icon: Icons.explore,
                      title: 'Discover',
                      onTap: () => Navigator.pop(context),
                    ),
                    _buildMenuItem(
                      icon: Icons.thumb_up,
                      title: 'Likes',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/likes');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on,
                      title: 'Location Settings',
                      onTap: () {
                        Navigator.pop(context);
                        _showLocationDialog(context);
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _getUnreadMessagesCount(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data?.docs.length ?? 0;
                        return _buildMenuItem(
                          icon: Icons.chat_bubble,
                          title: 'Messages',
                          badgeCount: unreadCount,
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/messages');
                          },
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Social',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/social');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.card_giftcard,
                      title: 'Gifts',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/gifts');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.workspace_premium,
                      title: 'Premium',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/subscription');
                      },
                    ),
                    const Divider(color: Colors.white30, height: 32),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/welcome');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  // ─── Location Dialog ────────────────────────────────────────

  void _showLocationDialog(BuildContext context) async {
    final locationService = LocationService();
    final currentUser = ref.read(authProvider).user;
    final permission = await locationService.checkPermission();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Allow Indira Love to access your location to find matches nearby.'),
              const SizedBox(height: 16),
              if (permission == LocationPermission.deniedForever) ...[
                const Text(
                  'Location permission is permanently denied. Please enable it in app settings.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await locationService.openSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                  ),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    if (currentUser?.uid == null) return;
                    final success = await locationService
                        .updateUserLocation(currentUser!.uid);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Failed to get location. Please check your settings.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                  ),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Enable Location'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getUnreadMessagesCount() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: currentUser.uid)
        .snapshots();
  }
}

// ═══════════════════════════════════════════════════════════════
// Action Button Row
// ═══════════════════════════════════════════════════════════════

class _ActionButtonRow extends StatelessWidget {
  const _ActionButtonRow({
    required this.onUndo,
    required this.onDislike,
    required this.onSuperLike,
    required this.onLike,
    required this.onBoost,
  });

  final VoidCallback onUndo;
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.undo_rounded,
            color: AppTheme.accentGold,
            size: 44,
            iconSize: 22,
            onTap: onUndo,
            tooltip: 'Undo',
          ),
          _ActionButton(
            icon: Icons.close_rounded,
            color: AppTheme.primaryRose,
            size: 56,
            iconSize: 28,
            onTap: onDislike,
            tooltip: 'Pass',
          ),
          _ActionButton(
            icon: Icons.star_rounded,
            color: AppTheme.accentGold,
            size: 44,
            iconSize: 22,
            onTap: onSuperLike,
            tooltip: 'Super Like',
          ),
          _ActionButton(
            icon: Icons.favorite_rounded,
            color: const Color(0xFF22C55E),
            size: 56,
            iconSize: 28,
            onTap: onLike,
            tooltip: 'Like',
          ),
          _ActionButton(
            icon: Icons.rocket_launch_rounded,
            color: AppTheme.secondaryPlum,
            size: 44,
            iconSize: 22,
            onTap: onBoost,
            tooltip: 'Boost',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Swipe Feedback Overlay
// ═══════════════════════════════════════════════════════════════

class _SwipeFeedback extends StatelessWidget {
  const _SwipeFeedback({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color)
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.2, 1.2),
                    duration: 300.ms,
                  )
                  .then()
                  .fadeOut(delay: 200.ms, duration: 200.ms),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .then()
                  .fadeOut(delay: 200.ms, duration: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Match Celebration Overlay
// ═══════════════════════════════════════════════════════════════

class _MatchOverlay extends StatelessWidget {
  const _MatchOverlay({
    required this.matchedUser,
    required this.currentUser,
    required this.onSendMessage,
    required this.onKeepSwiping,
  });

  final Map<String, dynamic> matchedUser;
  final dynamic currentUser;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  @override
  Widget build(BuildContext context) {
    final matchedPhotos = matchedUser['photos'] as List<dynamic>? ?? [];
    final matchedPhoto =
        matchedPhotos.isNotEmpty ? matchedPhotos[0].toString() : null;
    final matchedName = matchedUser['displayName'] ?? 'Someone';

    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Confetti decorative circles
                ...List.generate(8, (i) {
                  final random = Random(i);
                  return Icon(
                    Icons.favorite,
                    size: 8.0 + random.nextDouble() * 12,
                    color: [
                      AppTheme.accentGold,
                      AppTheme.primaryRose,
                      AppTheme.secondaryPlum,
                      Colors.white,
                    ][i % 4]
                        .withOpacity(0.6),
                  )
                      .animate()
                      .fadeIn(delay: (i * 80).ms)
                      .slideY(
                        begin: -2,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.bounceOut,
                      );
                }),

                const SizedBox(height: 16),

                // Title
                Text(
                  "It's a Match!",
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 8),

                Text(
                  'You and $matchedName liked each other!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                // Profile photos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current user photo
                    _MatchPhoto(imageUrl: null)
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideX(begin: -0.5, duration: 500.ms),
                    const SizedBox(width: 16),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryRose,
                            AppTheme.secondaryPlum,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms)
                        .scale(
                          begin: const Offset(0, 0),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(width: 16),
                    // Matched user photo
                    _MatchPhoto(imageUrl: matchedPhoto)
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideX(begin: 0.5, duration: 500.ms),
                  ],
                ),

                const SizedBox(height: 40),

                // Send Message Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryRose,
                          AppTheme.secondaryPlum,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton(
                      onPressed: onSendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Send Message',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                const SizedBox(height: 12),

                // Keep Swiping Button
                TextButton(
                  onPressed: onKeepSwiping,
                  child: Text(
                    'Keep Swiping',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchPhoto extends StatelessWidget {
  const _MatchPhoto({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryPlum.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppTheme.primaryRose.withOpacity(0.3),
                  child: const Icon(Icons.person,
                      size: 40, color: Colors.white),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.primaryRose.withOpacity(0.3),
                  child: const Icon(Icons.person,
                      size: 40, color: Colors.white),
                ),
              )
            : Container(
                color: AppTheme.primaryRose.withOpacity(0.3),
                child:
                    const Icon(Icons.person, size: 40, color: Colors.white),
              ),
      ),
    );
  }
}
