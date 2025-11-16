import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GiftLeaderboardScreen extends ConsumerStatefulWidget {
  const GiftLeaderboardScreen({super.key});

  @override
  ConsumerState<GiftLeaderboardScreen> createState() => _GiftLeaderboardScreenState();
}

class _GiftLeaderboardScreenState extends ConsumerState<GiftLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Leaderboard'),
        backgroundColor: AppTheme.primaryRose,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.send),
              text: 'Top Senders',
            ),
            Tab(
              icon: Icon(Icons.star),
              text: 'Top Receivers',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryRose,
              Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTopSenders(),
            _buildTopReceivers(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSenders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('user_gifts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRose),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No gifts sent yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Calculate sender statistics
        final Map<String, int> senderCounts = {};
        for (var doc in snapshot.data!.docs) {
          final senderId = doc['senderId'] as String;
          senderCounts[senderId] = (senderCounts[senderId] ?? 0) + 1;
        }

        // Sort by count
        final sortedSenders = senderCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedSenders.length,
          itemBuilder: (context, index) {
            final entry = sortedSenders[index];
            return _buildLeaderboardCard(
              userId: entry.key,
              count: entry.value,
              rank: index + 1,
              isReceiver: false,
            );
          },
        );
      },
    );
  }

  Widget _buildTopReceivers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('user_gifts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryRose),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No gifts received yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Calculate receiver statistics
        final Map<String, int> receiverCounts = {};
        for (var doc in snapshot.data!.docs) {
          final receiverId = doc['receiverId'] as String;
          receiverCounts[receiverId] = (receiverCounts[receiverId] ?? 0) + 1;
        }

        // Sort by count
        final sortedReceivers = receiverCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedReceivers.length,
          itemBuilder: (context, index) {
            final entry = sortedReceivers[index];
            return _buildLeaderboardCard(
              userId: entry.key,
              count: entry.value,
              rank: index + 1,
              isReceiver: true,
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardCard({
    required String userId,
    required int count,
    required int rank,
    required bool isReceiver,
  }) {
    Color rankColor;
    IconData rankIcon;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = Colors.grey[600]!;
      rankIcon = Icons.person;
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox();
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox();

        final displayName = userData['displayName'] ?? 'Unknown';
        final photos = userData['photos'] as List<dynamic>? ?? [];
        final photoUrl = photos.isNotEmpty ? photos[0] : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: rank <= 3
                        ? Icon(rankIcon, color: rankColor, size: 24)
                        : Text(
                            '#$rank',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: rankColor,
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundImage: photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl.toString())
                      : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 28)
                      : null,
                ),

                const SizedBox(width: 16),

                // Name and stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isReceiver
                            ? '$count gifts received'
                            : '$count gifts sent',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Gift icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppTheme.primaryRose,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
