import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/features/messaging/presentation/screens/conversation_screen.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Messages',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Messages List
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
                    stream: _getMatchesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final matches = snapshot.data?.docs ?? [];

                      if (matches.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No matches yet',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start swiping to find your matches!',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index].data() as Map<String, dynamic>;
                          final matchId = matches[index].id;
                          return _buildConversationItem(context, ref, match, matchId);
                        },
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

  Stream<QuerySnapshot> _getMatchesStream() {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('matches')
        .where('users', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Widget _buildConversationItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> match,
    String matchId,
  ) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return const SizedBox();

    final users = (match['users'] as List<dynamic>?) ?? [];
    final otherUserId = users.firstWhere(
      (id) => id != currentUser.uid,
      orElse: () => '',
    );

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const SizedBox();
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final userName = userData?['displayName'] ?? 'Unknown User';
        final photos = (userData?['photos'] as List<dynamic>?) ?? [];
        final userPhoto = photos.isNotEmpty ? photos[0] as String? : null;
        final lastMessage = match['lastMessage'] ?? 'No messages yet';
        final timestamp = match['lastMessageTime'] as Timestamp?;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
            backgroundColor: AppTheme.primaryRose.withOpacity(0.2),
            child: userPhoto == null
                ? const Icon(
                    Icons.person,
                    color: AppTheme.primaryRose,
                    size: 32,
                  )
                : null,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textCharcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (timestamp != null)
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              lastMessage,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConversationScreen(
                  matchId: matchId,
                  otherUserId: otherUserId,
                  otherUserName: userName,
                  otherUserPhoto: userPhoto,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}
