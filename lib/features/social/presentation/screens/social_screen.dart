import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final TextEditingController _postController = TextEditingController();
  String? _cachedDisplayName;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadUserDisplayName();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadUserDisplayName() async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          _cachedDisplayName = userDoc.data()?['displayName'] ?? 'Anonymous';
        });
      }
    } catch (e) {
      logger.error('Failed to load display name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - Fixed size to prevent overflow
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Lovers Anonymous',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCreatePostDialog(context),
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.white,
                        size: 32,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    _postController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Post'),
        content: TextField(
          controller: _postController,
          decoration: const InputDecoration(
            hintText: 'Share your thoughts anonymously...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 500,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isPosting ? null : () => _createPost(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRose,
            ),
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createPost(BuildContext dialogContext) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      logger.error('ERROR: No current user for post creation');
      return;
    }

    final content = _postController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something to post')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      String displayName = _cachedDisplayName ?? 'Anonymous';

      // Create post
      await FirebaseFirestore.instance.collection('social_posts').add({
        'userId': currentUser.uid,
        'displayName': displayName,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      });

      logger.info('Post created successfully');
      _postController.clear();

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post shared!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.error('Failed to create post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Widget _buildPostItem(BuildContext context, DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox();

    final userId = data['userId'] ?? '';
    final displayName = data['displayName'] ?? 'Anonymous';
    final content = data['content'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final likes = data['likes'] ?? 0;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final currentUser = AuthService().currentUser;
    final hasLiked = currentUser != null && likedBy.contains(currentUser.uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user photo
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.hasData && userSnapshot.data != null) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      final photoUrl = userData?['photoUrl'] as String?;

                      if (photoUrl != null && photoUrl.isNotEmpty) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: CachedNetworkImageProvider(photoUrl),
                        );
                      }
                    }

                    // Fallback to initial
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryRose,
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
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
                          fontSize: 16,
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          timeago.format(timestamp.toDate()),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Content
            Text(
              content,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),

            // Actions - Only like button, no comments
            Row(
              children: [
                IconButton(
                  onPressed: () => _toggleLike(post.id, hasLiked),
                  icon: Icon(
                    hasLiked ? Icons.favorite : Icons.favorite_border,
                    color: hasLiked ? Colors.red : Colors.grey,
                  ),
                ),
                Text('$likes'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(String postId, bool hasLiked) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) return;

    try {
      if (hasLiked) {
        await FirebaseFirestore.instance.collection('social_posts').doc(postId).update({
          'likes': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([currentUser.uid]),
        });
      } else {
        await FirebaseFirestore.instance.collection('social_posts').doc(postId).update({
          'likes': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }
    } catch (e) {
      logger.error('Failed to toggle like: $e');
    }
  }
}
