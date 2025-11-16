import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final TextEditingController _postController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lovers Anonymous',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCreatePostDialog(context),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Social Feed
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('social_posts')
                        .orderBy('timestamp', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final posts = snapshot.data?.docs ?? [];

                      if (posts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.forum,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to share something!',
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
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return _buildPostItem(context, post);
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

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Post'),
        content: TextField(
          controller: _postController,
          decoration: const InputDecoration(
            hintText: 'Share your thoughts...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createPost(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost(BuildContext context) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    final content = _postController.text.trim();
    if (content.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('social_posts').add({
        'userId': currentUser.uid,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': [],
      });

      _postController.clear();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    }
  }

  Widget _buildPostItem(BuildContext context, DocumentSnapshot postDoc) {
    final postData = postDoc.data() as Map<String, dynamic>;
    final userId = postData['userId'] as String? ?? '';
    final content = postData['content'] as String? ?? '';
    final timestamp = (postData['timestamp'] as Timestamp?)?.toDate();
    final likes = List<String>.from(postData['likes'] ?? []);
    final currentUser = AuthService().currentUser;
    final isLiked = currentUser != null && likes.contains(currentUser.uid);
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final displayName = userData?['displayName'] ?? 'Anonymous User';
        final photos = (userData?['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        final photoUrl = photos.isNotEmpty ? photos[0] : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutralWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryRose.withOpacity(0.2),
                    backgroundImage: photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
                    child: photoUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppTheme.primaryRose,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          timestamp != null ? _formatTimestamp(timestamp) : 'Just now',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (currentUser?.uid == userId)
                    IconButton(
                      onPressed: () => _deletePost(postDoc.id),
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: Colors.red,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Post Content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _toggleLike(postDoc.id, likes),
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        iconSize: 20,
                      ),
                      Text(
                        '${likes.length}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(postData['comments'] as List?)?.length ?? 0}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Future<void> _toggleLike(String postId, List<String> currentLikes) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    try {
      if (currentLikes.contains(currentUser.uid)) {
        // Unlike
        await FirebaseFirestore.instance.collection('social_posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([currentUser.uid]),
        });
      } else {
        // Like
        await FirebaseFirestore.instance.collection('social_posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([currentUser.uid]),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('social_posts').doc(postId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }
}
