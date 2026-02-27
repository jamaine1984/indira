import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/widgets/shimmer_loading.dart';
import 'package:indira_love/core/widgets/empty_state_widget.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = AuthService().currentUser;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header (no back arrow - this is a tab)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      l10n.matches,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('matches')
                          .where('users', arrayContains: currentUser?.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final matchCount = snapshot.data?.docs.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$matchCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Matches Grid
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('matches')
                        .where('users', arrayContains: currentUser?.uid)
                        .orderBy('lastMessageTime', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ShimmerLoading.profileGrid(count: 6);
                      }

                      final matches = snapshot.data?.docs ?? [];

                      if (matches.isEmpty) {
                        return EmptyStateWidget(
                          icon: Icons.favorite_border,
                          title: l10n.noMatches,
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
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final matchDoc = matches[index];
                            final matchData = matchDoc.data() as Map<String, dynamic>;
                            final users = List<String>.from(matchData['users'] ?? []);
                            final otherUserId = users.firstWhere(
                              (id) => id != currentUser?.uid,
                              orElse: () => '',
                            );

                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              columnCount: 2,
                              duration: const Duration(milliseconds: 375),
                              child: ScaleAnimation(
                                child: FadeInAnimation(
                                  child: _buildMatchCard(
                                    context,
                                    matchDoc.id,
                                    otherUserId,
                                    index,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, String matchId, String otherUserId, int index) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return ShimmerLoading.profileCard();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final displayName = userData?['displayName'] ?? 'User';
        final age = userData?['age'] ?? 0;
        final photos = (userData?['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final photoUrl = photos.isNotEmpty ? photos[0] : null;

        return GestureDetector(
          onTap: () {
            context.push('/user-profile/$otherUserId');
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                  // Profile Image
                  if (photoUrl != null)
                    CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppTheme.primaryRose.withOpacity(0.2),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.primaryRose.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          color: AppTheme.primaryRose,
                          size: 64,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.primaryRose.withOpacity(0.2),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.primaryRose,
                        size: 64,
                      ),
                    ),

                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (age > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$age years old',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Message icon - taps to open conversation
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        context.push('/conversation/$otherUserId');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRose,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.chat_bubble,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
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
}
