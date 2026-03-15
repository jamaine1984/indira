import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/theme/app_theme.dart';

class SuccessStoriesScreen extends StatelessWidget {
  const SuccessStoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Success Stories',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Real couples who found love on Indira',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Stories list from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('success_stories')
                      .orderBy('createdAt', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final stories = snapshot.data?.docs ?? [];

                    if (stories.isEmpty) {
                      return _buildPlaceholderStories();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stories.length,
                      itemBuilder: (context, index) {
                        final story = stories[index].data() as Map<String, dynamic>;
                        return _buildStoryCard(story);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder stories when Firestore collection is empty
  Widget _buildPlaceholderStories() {
    final placeholders = [
      {
        'names': 'Priya & Arjun',
        'location': 'Mumbai, India',
        'story': 'We matched on Indira during Diwali and bonded over our shared love of Bollywood classics. Our Kundli compatibility was 92%! We got married last spring.',
        'emoji': '\u{1F490}',
        'months': '8 months',
      },
      {
        'names': 'Ananya & Rahul',
        'location': 'Delhi, India',
        'story': 'The compatibility quiz showed us we were perfect for each other. After weeks of video calls through the app, we finally met in person. It was magic!',
        'emoji': '\u{1F496}',
        'months': '6 months',
      },
      {
        'names': 'Meera & Vikram',
        'location': 'Bangalore, India',
        'story': 'I almost swiped left but the Vedic astrology badge caught my eye. Our nakshatras were a perfect match. Two years later, we are engaged!',
        'emoji': '\u{1F48D}',
        'months': '24 months',
      },
      {
        'names': 'Sita & Dev',
        'location': 'Chennai, India',
        'story': 'We started as friends playing Would You Rather on the app. The more we talked, the more we realized how much we had in common. Now planning our wedding!',
        'emoji': '\u{1F389}',
        'months': '12 months',
      },
      {
        'names': 'Kavya & Aditya',
        'location': 'Hyderabad, India',
        'story': 'Our families were skeptical about online dating, but when they saw our Kundli match and cultural compatibility, they gave their blessings immediately.',
        'emoji': '\u{1F64F}',
        'months': '10 months',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: placeholders.length,
      itemBuilder: (context, index) {
        return _buildPlaceholderCard(placeholders[index]);
      },
    );
  }

  Widget _buildPlaceholderCard(Map<String, String> story) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with emoji and names
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryRose, AppTheme.secondaryPlum],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      story['emoji']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['names']!,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textCharcoal,
                        ),
                      ),
                      Text(
                        story['location']!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    story['months']!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryRose,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Story text
            Text(
              story['story']!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.6,
                color: AppTheme.textCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final photos = story['photos'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Couple photo
          if (photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: photos[0].toString(),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  story['names'] ?? 'A Beautiful Couple',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textCharcoal,
                  ),
                ),
                if (story['location'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    story['location'],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  story['story'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.6,
                    color: AppTheme.textCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
