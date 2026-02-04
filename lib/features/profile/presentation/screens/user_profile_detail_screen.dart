import 'package:flutter/material.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/profile/presentation/widgets/report_dialog.dart';
import 'package:indira_love/core/services/database_service.dart';

class UserProfileDetailScreen extends ConsumerWidget {
  final String userId;

  const UserProfileDetailScreen({super.key, required this.userId});

  void _showPhotoViewer(BuildContext context, List<dynamic> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildClickablePhoto(BuildContext context, String photoUrl, List<dynamic> allPhotos, int index) {
    return GestureDetector(
      onTap: () => _showPhotoViewer(context, allPhotos, index),
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Container(
              decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'User not found',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final photos = userData['photos'] as List<dynamic>? ?? [];
          final displayName = userData['displayName'] ?? 'Unknown';
          final age = userData['age'] ?? 0;
          final bio = userData['bio'] ?? '';
          // Location is GeoPoint from Firestore, get city/country string if available
          final location = userData['city'] as String? ?? userData['country'] as String? ?? '';
          final interests = userData['interests'] as List<dynamic>? ?? [];

          return CustomScrollView(
            slivers: [
              // App Bar with back button
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: photos.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _showPhotoViewer(context, photos, 0),
                          child: CachedNetworkImage(
                            imageUrl: photos[0].toString(),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.secondaryPlum.withOpacity(0.3),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.secondaryPlum.withOpacity(0.3),
                              child: const Center(
                                child: Icon(Icons.person, size: 100, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.secondaryPlum.withOpacity(0.3),
                          child: const Center(
                            child: Icon(Icons.person, size: 100, color: Colors.white),
                          ),
                        ),
                ),
              ),

              // Profile Info
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFFF5F5), // Very light pink
                        AppTheme.primaryRose.withOpacity(0.08), // Subtle rose
                        AppTheme.accentGold.withOpacity(0.12), // Light gold
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Age
                        Row(
                          children: [
                            Text(
                              '$displayName, $age',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (userData['isVerified'] == true)
                              const Icon(
                                Icons.verified,
                                color: AppTheme.primaryRose,
                                size: 28,
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Location
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Bio Section
                        if (bio.isNotEmpty) ...[
                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bio,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Interests Section
                        if (interests.isNotEmpty) ...[
                          const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRose.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.primaryRose.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  interest.toString(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryRose,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Cultural & Lifestyle Section
                        if (userData['culturalPreferences'] != null) ...[
                          const Text(
                            'Cultural & Lifestyle',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCulturalInfo(userData['culturalPreferences']),
                          const SizedBox(height: 24),
                        ],

                        // Photos Grid
                        if (photos.length > 1) ...[
                          const Text(
                            'Photos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: photos.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildClickablePhoto(
                                  context,
                                  photos[index].toString(),
                                  photos,
                                  index,
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 40),

                        // Action Buttons
                        Row(
                          children: [
                            // Report Button
                            OutlinedButton(
                              onPressed: () async {
                                await showReportDialog(
                                  context,
                                  userId: userId,
                                  userName: displayName,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                Icons.report,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Block Button
                            OutlinedButton(
                              onPressed: () async {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                if (currentUser == null) return;

                                // Show confirmation dialog
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Block User'),
                                    content: Text('Are you sure you want to block $displayName? You will not see each other anymore.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('Block'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true && context.mounted) {
                                  try {
                                    await DatabaseService().blockUser(userId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$displayName has been blocked'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      context.pop();
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to block user: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Icon(
                                Icons.block,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) return;

                                  String? matchId;
                                  try {
                                    // Create or get existing match
                                    final matchQuery = await FirebaseFirestore.instance
                                        .collection('matches')
                                        .where('users', arrayContains: currentUser.uid)
                                        .get();

                                    for (var doc in matchQuery.docs) {
                                      final users = List<String>.from(doc['users']);
                                      if (users.contains(userId)) {
                                        matchId = doc.id;
                                        break;
                                      }
                                    }
                                  } catch (e) {
                                    logger.error('Error querying matches: $e');
                                    // Continue to create new match if query fails
                                  }

                                  // If no match exists, create one
                                  if (matchId == null) {
                                    try {
                                      final newMatch = await FirebaseFirestore.instance
                                          .collection('matches')
                                          .add({
                                        'users': [currentUser.uid, userId],
                                        'timestamp': FieldValue.serverTimestamp(),
                                        'isActive': true,
                                        'lastMessage': '',
                                        'lastMessageTime': FieldValue.serverTimestamp(),
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      matchId = newMatch.id;
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to start conversation: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }
                                  }

                                  // Navigate to conversation
                                  if (context.mounted) {
                                    final userName = displayName.replaceAll(' ', '_');
                                    final photoParam = photos.isNotEmpty ? '?photo=${Uri.encodeComponent(photos[0].toString())}' : '';
                                    context.push('/conversation/$matchId/$userId/$userName$photoParam');
                                  }
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('Message'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppTheme.primaryRose,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCulturalInfo(Map<String, dynamic> culturalPrefs) {
    final List<Widget> items = [];

    // Religion & Diet
    if (culturalPrefs['religion'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.temple_hindu,
        label: culturalPrefs['religion'],
        color: AppTheme.secondaryPlum,
      ));
    }

    if (culturalPrefs['dietType'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.restaurant,
        label: culturalPrefs['dietType'],
        color: culturalPrefs['dietType'] == 'Vegetarian' ||
               culturalPrefs['dietType'] == 'Vegan' ||
               culturalPrefs['dietType'] == 'Jain'
               ? Colors.green
               : Colors.orange,
      ));
    }

    // Language
    if (culturalPrefs['motherTongue'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.language,
        label: culturalPrefs['motherTongue'],
        color: AppTheme.primaryRose,
      ));
    }

    // Family & Marriage
    if (culturalPrefs['marriageTimeline'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.favorite,
        label: culturalPrefs['marriageTimeline'],
        color: Colors.red,
      ));
    }

    if (culturalPrefs['familyValues'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.family_restroom,
        label: culturalPrefs['familyValues'],
        color: AppTheme.secondaryPlum,
      ));
    }

    // Education & Profession
    if (culturalPrefs['educationLevel'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.school,
        label: culturalPrefs['educationLevel'],
        color: Colors.blue,
      ));
    }

    if (culturalPrefs['profession'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.work,
        label: culturalPrefs['profession'],
        color: Colors.indigo,
      ));
    }

    // Location
    if (culturalPrefs['state'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.location_on,
        label: culturalPrefs['state'],
        color: Colors.teal,
      ));
    }

    if (culturalPrefs['isNRI'] == true) {
      items.add(_buildInfoChip(
        icon: Icons.flight,
        label: 'NRI',
        color: Colors.purple,
      ));
    }

    // Manglik Status
    if (culturalPrefs['manglik'] != null) {
      items.add(_buildInfoChip(
        icon: Icons.star,
        label: culturalPrefs['manglik'] == true ? 'Manglik' : 'Non-Manglik',
        color: culturalPrefs['manglik'] == true ? Colors.orange : Colors.green,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<dynamic> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo viewer with zoom and swipe
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[index].toString(),
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar with close button and photo counter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Photo counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} of ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
