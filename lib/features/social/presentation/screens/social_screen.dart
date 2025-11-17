import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedImagePath;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      print('DEBUG: Starting image picker...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      print('DEBUG: Image picker returned: ${image?.path}');
      if (image != null) {
        print('DEBUG: Setting image path to state: ${image.path}');
        setState(() {
          _selectedImagePath = image.path;
        });
        print('DEBUG: Image path set successfully: $_selectedImagePath');
      } else {
        print('DEBUG: No image selected');
      }
    } catch (e) {
      print('ERROR: Failed to pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImage(String imagePath) async {
    try {
      print('DEBUG: Starting image upload for path: $imagePath');
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        print('ERROR: No current user for image upload');
        return null;
      }

      final fileName = '${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('DEBUG: Uploading to: social_posts/$fileName');
      final storageRef = FirebaseStorage.instance.ref().child('social_posts/$fileName');

      print('DEBUG: Uploading file...');
      final uploadTask = await storageRef.putFile(File(imagePath));
      print('DEBUG: Upload complete, getting download URL...');
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('DEBUG: Download URL obtained: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('ERROR: Failed to upload image: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      return null;
    }
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
                        .where('timestamp', isGreaterThan: Timestamp.fromDate(
                          DateTime.now().subtract(const Duration(days: 30)),
                        ))
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Post'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _postController,
                  decoration: const InputDecoration(
                    hintText: 'Share your thoughts...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  maxLength: 500,
                ),
                const SizedBox(height: 16),
                // Image preview
                if (_selectedImagePath != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImagePath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              _selectedImagePath = null;
                            });
                            setState(() {
                              _selectedImagePath = null;
                            });
                          },
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () async {
                      print('DEBUG: Add Image button pressed');
                      await _pickImage();
                      print('DEBUG: After _pickImage, path = $_selectedImagePath');
                      // Force both dialog and main widget to rebuild
                      if (mounted) {
                        setDialogState(() {
                          print('DEBUG: Updating dialog state');
                        });
                        setState(() {
                          print('DEBUG: Updating main state');
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Add Image'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImagePath = null;
                });
                Navigator.pop(context);
              },
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
      ),
    );
  }

  Future<void> _createPost(BuildContext context) async {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      print('ERROR: No current user for post creation');
      return;
    }

    final content = _postController.text.trim();
    if (content.isEmpty && _selectedImagePath == null) {
      print('DEBUG: No content or image, skipping post creation');
      return;
    }

    print('DEBUG: Creating post with content length: ${content.length}, has image: ${_selectedImagePath != null}');

    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      String? imageUrl;

      // Upload image if selected
      if (_selectedImagePath != null) {
        print('DEBUG: Uploading image from path: $_selectedImagePath');
        try {
          imageUrl = await _uploadImage(_selectedImagePath!).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('ERROR: Image upload timed out after 30 seconds');
              return null;
            },
          );
          if (imageUrl == null) {
            throw Exception('Failed to upload image - timeout or network error');
          }
          print('DEBUG: Image uploaded successfully: $imageUrl');
        } catch (uploadError) {
          print('ERROR: Image upload failed: $uploadError');
          if (context.mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: $uploadError'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return; // Exit early on upload failure
        }
      }

      // Create post with or without image
      print('DEBUG: Creating Firestore document...');
      await FirebaseFirestore.instance.collection('social_posts').add({
        'userId': currentUser.uid,
        'content': content,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': [],
      });
      print('DEBUG: Post created successfully');

      _postController.clear();
      if (mounted) {
        setState(() {
          _selectedImagePath = null;
        });
      }

      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);
        // Close create post dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('ERROR: Failed to create post: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPostItem(BuildContext context, DocumentSnapshot postDoc) {
    final postData = postDoc.data() as Map<String, dynamic>;
    final userId = postData['userId'] as String? ?? '';
    final content = postData['content'] as String? ?? '';
    final imageUrl = postData['imageUrl'] as String?;
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
              if (content.isNotEmpty)
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),

              // Post Image
              if (imageUrl != null) ...[
                if (content.isNotEmpty) const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ],

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
