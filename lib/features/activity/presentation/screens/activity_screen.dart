import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Activity feed showing recent likes, messages, and gifts
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view activity')),
      );
    }

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
                      'Activity',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Activity Feed
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _buildActivityFeed(context, currentUser.uid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(BuildContext context, String userId) {
    return StreamBuilder<List<ActivityItem>>(
      stream: _getCombinedActivityStream(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No activity yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your likes, messages, and gifts will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            return _buildActivityItem(context, activities[index]);
          },
        );
      },
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityItem activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(activity.userId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final photoUrl = userData?['photoUrl'] as String?;

              if (photoUrl != null && photoUrl.isNotEmpty) {
                return CircleAvatar(
                  radius: 28,
                  backgroundImage: CachedNetworkImageProvider(photoUrl),
                );
              }
            }

            return CircleAvatar(
              radius: 28,
              backgroundColor: activity.type == 'like'
                  ? Colors.pink
                  : activity.type == 'message'
                      ? Colors.blue
                      : Colors.purple,
              child: Icon(
                activity.type == 'like'
                    ? Icons.favorite
                    : activity.type == 'message'
                        ? Icons.message
                        : Icons.card_giftcard,
                color: Colors.white,
              ),
            );
          },
        ),
        title: Text(
          activity.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.subtitle),
            const SizedBox(height: 4),
            Text(
              timeago.format(activity.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          activity.type == 'like'
              ? Icons.favorite
              : activity.type == 'message'
                  ? Icons.message
                  : Icons.card_giftcard,
          color: activity.type == 'like'
              ? Colors.pink
              : activity.type == 'message'
                  ? Colors.blue
                  : Colors.purple,
        ),
      ),
    );
  }

  /// Combine likes, messages, and gifts into a single stream
  Stream<List<ActivityItem>> _getCombinedActivityStream(String userId) {
    final firestore = FirebaseFirestore.instance;

    // Get recent likes received
    final likesStream = firestore
        .collection('likes')
        .where('likedUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = <ActivityItem>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final likerId = data['likerId'] as String?;
        if (likerId == null) continue;

        final likerDoc = await firestore.collection('users').doc(likerId).get();
        final likerName = likerDoc.data()?['displayName'] ?? 'Someone';

        items.add(ActivityItem(
          type: 'like',
          userId: likerId,
          title: '$likerName liked you',
          subtitle: 'Tap to view their profile',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
      return items;
    });

    // Get recent gift notifications (gifts received)
    final giftsStream = firestore
        .collection('user_gifts')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = <ActivityItem>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String?;
        final giftName = data['giftName'] ?? 'a gift';

        if (senderId == null) continue;

        final senderDoc = await firestore.collection('users').doc(senderId).get();
        final senderName = senderDoc.data()?['displayName'] ?? 'Someone';

        items.add(ActivityItem(
          type: 'gift',
          userId: senderId,
          title: '$senderName sent you $giftName',
          subtitle: 'Open your messages to view',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ));
      }
      return items;
    });

    // Get recent chats (new messages)
    final messagesStream = firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final items = <ActivityItem>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final lastMessage = data['lastMessage'] as String?;
        final lastMessageTime = data['lastMessageTime'] as Timestamp?;

        // Find the other participant
        final otherUserId = participants.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty || lastMessage == null) continue;

        final otherUserDoc = await firestore.collection('users').doc(otherUserId).get();
        final otherUserName = otherUserDoc.data()?['displayName'] ?? 'Someone';

        items.add(ActivityItem(
          type: 'message',
          userId: otherUserId,
          title: 'New message from $otherUserName',
          subtitle: lastMessage,
          timestamp: lastMessageTime?.toDate() ?? DateTime.now(),
        ));
      }
      return items;
    });

    // Combine all streams and sort by timestamp
    return likesStream.asyncExpand((likes) {
      return giftsStream.asyncExpand((gifts) {
        return messagesStream.map((messages) {
          final allItems = [...likes, ...gifts, ...messages];
          allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return allItems.take(50).toList(); // Limit to 50 most recent items
        });
      });
    });
  }
}

/// Model for activity feed items
class ActivityItem {
  final String type; // 'like', 'message', or 'gift'
  final String userId;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  ActivityItem({
    required this.type,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}
