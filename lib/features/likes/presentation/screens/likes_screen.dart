import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/widgets/watch_ads_dialog.dart';
import 'package:indira_love/core/widgets/shimmer_loading.dart';
import 'package:indira_love/core/widgets/empty_state_widget.dart';
import 'package:indira_love/core/widgets/app_snackbar.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';
import 'package:indira_love/features/likes/providers/likes_provider.dart';
import 'package:indira_love/features/likes/services/likes_service.dart';
import 'package:indira_love/core/services/profile_view_service.dart';
import 'package:indira_love/core/services/auth_service.dart';

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unrevealedCountAsync = ref.watch(unrevealedLikesCountProvider);
    final hasGoldAsync = ref.watch(hasGoldSubscriptionProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      l10n.likes,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Unrevealed count badge
                    unrevealedCountAsync.when(
                      data: (count) => count > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count New',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : const SizedBox(),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  labelColor: AppTheme.primaryRose,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(text: l10n.peopleWhoLikedYou),
                    Tab(text: l10n.sentLikes),
                    const Tab(text: 'Viewed You'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLikedYouTab(hasGoldAsync),
                    _buildYourLikesTab(),
                    _buildViewedYouTab(hasGoldAsync),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikedYouTab(AsyncValue<bool> hasGoldAsync) {
    final l10n = AppLocalizations.of(context);
    final likesReceivedAsync = ref.watch(likesReceivedProvider);

    return likesReceivedAsync.when(
      data: (likes) {
        if (likes.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.favorite_border,
            title: l10n.noLikesYet,
            subtitle: l10n.keepSwiping,
          );
        }

        final hasGold = hasGoldAsync.value ?? false;

        return AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final like = likes[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 2,
                duration: const Duration(milliseconds: 375),
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildLikedYouCard(like, hasGold),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => ShimmerLoading.profileGrid(count: 4),
      error: (error, stack) => Center(
        child: Text(
          'Error loading likes: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLikedYouCard(like, bool hasGold) {
    final isRevealed = like.isRevealed || hasGold;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(like.likerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final photos = (userData['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final photoUrl = photos.isNotEmpty ? photos[0] : null;
        final displayName = userData['displayName'] ?? 'User';
        final age = userData['age'] ?? 0;

        return GestureDetector(
          onTap: () {
            if (isRevealed) {
              context.push('/user-profile/${like.likerId}');
            } else {
              _showRevealDialog(like.id);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image
                  if (photoUrl != null)
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.secondaryPlum.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.secondaryPlum.withOpacity(0.3),
                        child: const Icon(Icons.person, color: Colors.white, size: 50),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.secondaryPlum.withOpacity(0.3),
                      child: const Icon(Icons.person, color: Colors.white, size: 50),
                    ),

                  // Blur effect if not revealed
                  if (!isRevealed)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  if (!isRevealed)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryRose,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              hasGold ? 'Tap to reveal' : 'Watch 2 ads',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$displayName, $age',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.favorite,
                            color: AppTheme.primaryRose,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildYourLikesTab() {
    final l10n = AppLocalizations.of(context);
    final likesSentAsync = ref.watch(likesSentProvider);

    return likesSentAsync.when(
      data: (likes) {
        if (likes.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.favorite_border,
            title: l10n.sentLikes,
            subtitle: l10n.keepSwiping,
          );
        }

        return AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: likes.length,
            itemBuilder: (context, index) {
              final like = likes[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 2,
                duration: const Duration(milliseconds: 375),
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildYourLikeCard(like),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => ShimmerLoading.profileGrid(count: 4),
      error: (error, stack) => Center(
        child: Text(
          'Error loading likes: $error',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildYourLikeCard(like) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(like.likedUserId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final photos = (userData['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final photoUrl = photos.isNotEmpty ? photos[0] : null;
        final displayName = userData['displayName'] ?? 'User';
        final age = userData['age'] ?? 0;

        return GestureDetector(
          onTap: () => context.push('/user-profile/${like.likedUserId}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image
                  if (photoUrl != null)
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.secondaryPlum.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.secondaryPlum.withOpacity(0.3),
                        child: const Icon(Icons.person, color: Colors.white, size: 50),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.secondaryPlum.withOpacity(0.3),
                      child: const Icon(Icons.person, color: Colors.white, size: 50),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Info
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$displayName, $age',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: AppTheme.primaryRose,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(like.timestamp),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewedYouTab(AsyncValue<bool> hasGoldAsync) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Please log in', style: TextStyle(color: Colors.white)));
    }

    final hasGold = hasGoldAsync.value ?? false;
    final viewService = ProfileViewService();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: viewService.getProfileViewers(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading.profileGrid(count: 4);
        }

        final views = snapshot.data ?? [];

        if (views.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.visibility_off,
            title: 'No profile views yet',
            subtitle: 'When someone views your profile, they\'ll appear here',
          );
        }

        return AnimationLimiter(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: views.length,
            itemBuilder: (context, index) {
              final view = views[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                columnCount: 2,
                duration: const Duration(milliseconds: 375),
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: _buildViewerCard(view, hasGold),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildViewerCard(Map<String, dynamic> view, bool hasGold) {
    final isRevealed = view['isRevealed'] == true || hasGold;
    final viewerId = view['viewerId'] as String;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(viewerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final photos = (userData['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final photoUrl = photos.isNotEmpty ? photos[0] : null;
        final displayName = userData['displayName'] ?? 'User';
        final age = userData['age'] ?? 0;

        return GestureDetector(
          onTap: () {
            if (isRevealed) {
              context.push('/user-profile/$viewerId');
            } else {
              _showViewerRevealDialog(view['id'] as String);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photoUrl != null)
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.secondaryPlum.withOpacity(0.3),
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.secondaryPlum.withOpacity(0.3),
                        child: const Icon(Icons.person, color: Colors.white, size: 50),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.secondaryPlum.withOpacity(0.3),
                      child: const Icon(Icons.person, color: Colors.white, size: 50),
                    ),

                  // Blur if not revealed
                  if (!isRevealed)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.black.withOpacity(0.3)),
                    ),

                  // Gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),

                  if (!isRevealed)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 36),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryPlum,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              hasGold ? 'Tap to reveal' : 'Watch 1 ad',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$displayName, $age',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.visibility, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Viewed your profile',
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showViewerRevealDialog(String viewId) {
    final hasGoldAsync = ref.read(hasGoldSubscriptionProvider);

    hasGoldAsync.when(
      data: (hasGold) {
        if (hasGold) {
          _revealViewer(viewId);
        } else {
          showWatchAdsDialog(
            context,
            type: 'reveal_viewer',
            adsRequired: 1,
            onComplete: () async {
              await _revealViewer(viewId);
            },
          );
        }
      },
      loading: () {},
      error: (_, __) {
        showWatchAdsDialog(
          context,
          type: 'reveal_viewer',
          adsRequired: 1,
          onComplete: () async {
            await _revealViewer(viewId);
          },
        );
      },
    );
  }

  Future<void> _revealViewer(String viewId) async {
    try {
      await ProfileViewService().revealViewer(viewId);
      if (mounted) {
        AppSnackBar.success(context, 'Profile revealed!');
        setState(() {}); // Refresh
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to reveal: $e');
      }
    }
  }

  void _showRevealDialog(String likeId) {
    final hasGoldAsync = ref.read(hasGoldSubscriptionProvider);

    hasGoldAsync.when(
      data: (hasGold) {
        if (hasGold) {
          // Gold users can reveal instantly
          _revealLike(likeId);
        } else {
          // Free/Silver users must watch 2 ads
          showWatchAdsDialog(
            context,
            type: 'reveal_like',
            adsRequired: 2,
            onComplete: () async {
              await _revealLike(likeId);
            },
          );
        }
      },
      loading: () {},
      error: (_, __) {
        // Default to showing ad dialog
        showWatchAdsDialog(
          context,
          type: 'reveal_like',
          adsRequired: 2,
          onComplete: () async {
            await _revealLike(likeId);
          },
        );
      },
    );
  }

  Future<void> _revealLike(String likeId) async {
    try {
      await ref.read(likesServiceProvider).revealLike(likeId);

      if (mounted) {
        AppSnackBar.success(context, 'Profile revealed!');
      }

      // Refresh the likes list
      ref.invalidate(likesReceivedProvider);
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to reveal: $e');
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
