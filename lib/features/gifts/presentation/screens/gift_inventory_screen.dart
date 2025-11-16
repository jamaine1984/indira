import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/models/gift_model.dart';
import 'package:indira_love/core/services/auth_service.dart';

class GiftInventoryScreen extends ConsumerWidget {
  const GiftInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = AuthService().currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Gifts'),
          backgroundColor: AppTheme.primaryRose,
        ),
        body: const Center(
          child: Text('Please log in to view your gifts'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gift Inventory'),
        backgroundColor: AppTheme.primaryRose,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_gifts')
            .where('receiverId', isEqualTo: currentUser.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final gifts = snapshot.data?.docs ?? [];

          if (gifts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No gifts received yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gifts you receive will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index].data() as Map<String, dynamic>;
              final giftId = gift['giftId'] as String? ?? '';
              final giftName = gift['giftName'] as String? ?? 'Gift';
              final giftEmoji = gift['giftEmoji'] as String? ?? '🎁';
              final senderId = gift['senderId'] as String? ?? '';
              final timestamp = (gift['timestamp'] as Timestamp?)?.toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(senderId)
                    .get(),
                builder: (context, userSnapshot) {
                  String senderName = 'Someone';
                  if (userSnapshot.hasData && userSnapshot.data != null) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    senderName = userData?['displayName'] as String? ?? 'Someone';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRose.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            giftEmoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      title: Text(
                        giftName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'From: $senderName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (timestamp != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatTimestamp(timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
