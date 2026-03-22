import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/kundli/services/kundli_service.dart';

enum SwipeDirection { left, right, up }

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
  });

  final Map<String, dynamic> user;
  final VoidCallback? onTap;

  int get _compatibilityPercent {
    final score = user['compatibilityScore'];
    if (score is int) return score;
    if (score is double) return score.round();
    if (score is num) return score.toInt();
    final uid = user['uid'] as String? ?? '';
    return 60 + Random(uid.hashCode).nextInt(40);
  }

  bool get _hasVedicData {
    final cultural = user['culturalPreferences'] as Map<String, dynamic>?;
    if (cultural == null) return false;
    final nakshatra = cultural['nakshatra'] as String?;
    return nakshatra != null && nakshatra.isNotEmpty;
  }

  String get _vedicLabel {
    final cultural = user['culturalPreferences'] as Map<String, dynamic>?;
    if (cultural == null) return '';
    final nakshatra = cultural['nakshatra'] as String? ?? '';
    final manglik = cultural['manglik'] as bool?;
    if (manglik == true) return '$nakshatra · Manglik';
    return nakshatra;
  }

  @override
  Widget build(BuildContext context) {
    final photos = user['photos'] as List<dynamic>? ?? [];
    final galleryCount = photos.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryPlum.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1: Background Photo with Hero
              Hero(
                tag: 'profile-${user['uid'] ?? ''}',
                child: _buildPhoto(photos),
              ),

              // Layer 2: Gradient Overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.4, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // Layer 3: Compatibility Badge (Top-Right)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryPlum.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite,
                          color: AppTheme.accentGold, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$_compatibilityPercent%',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Layer 4: Vedic Kundli Badge (Top-Left) - shows when user has astrology data
              if (_hasVedicData)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🕉️', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          _vedicLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Layer 4b: Boosted Indicator
              if (user['isBoosted'] == true && !_hasVedicData)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Boosted',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Layer 5: Bottom Info Section
              _buildBottomInfo(galleryCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(List<dynamic> photos) {
    final mainPhoto = photos.isNotEmpty ? photos[0].toString() : null;

    if (mainPhoto != null && mainPhoto.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: mainPhoto,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: AppTheme.secondaryPlum.withOpacity(0.15),
          child: const Center(
            child: Icon(Icons.person, size: 80, color: AppTheme.primaryRose),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppTheme.secondaryPlum.withOpacity(0.15),
          child: const Center(
            child: Icon(Icons.person, size: 80, color: AppTheme.primaryRose),
          ),
        ),
      );
    }

    return Container(
      color: AppTheme.secondaryPlum.withOpacity(0.15),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 80, color: AppTheme.primaryRose),
            const SizedBox(height: 16),
            Text(
              user['displayName'] ?? 'Unknown',
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo(int galleryCount) {
    final displayName = user['displayName'] ?? 'Unknown';
    final age = user['age'];
    final bio = user['bio'] as String? ?? '';
    final city = user['city'] as String? ?? '';
    final country = user['country'] as String? ?? '';
    final interests = user['interests'] as List<dynamic>? ?? [];
    final isVerified = user['isVerified'] == true;

    String locationText = '';
    if (city.isNotEmpty && country.isNotEmpty) {
      locationText = '$city, $country';
    } else if (city.isNotEmpty) {
      locationText = city;
    } else if (country.isNotEmpty) {
      locationText = country;
    }

    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name + Age + Verification
          Row(
            children: [
              Flexible(
                child: Text(
                  age != null ? '$displayName, $age' : displayName,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.verified,
                  color: AppTheme.accentGold,
                  size: 22,
                ),
              ],
              if (user['loveLanguage'] != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(user['loveLanguage'] as Map)['emoji'] ?? ''} ${(user['loveLanguage'] as Map)['shortName'] ?? ''}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.secondaryPlum,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),

          // Bio
          if (bio.isNotEmpty)
            Text(
              bio,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 10),

          // Location + Interests chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (locationText.isNotEmpty)
                _InfoChip(
                  icon: Icons.location_on_outlined,
                  label: locationText,
                ),
              // Vedic astrology info chips
              if (_hasVedicData) ...[
                _InfoChip(
                  icon: Icons.auto_awesome,
                  label: '☾ ${(user['culturalPreferences'] as Map?)?['nakshatra'] ?? ''}',
                ),
                if ((user['culturalPreferences'] as Map?)?['rashi'] != null)
                  _InfoChip(
                    icon: Icons.auto_awesome,
                    label: '♈ ${(user['culturalPreferences'] as Map)['rashi']}',
                  ),
              ],
              ...interests.take(_hasVedicData ? 1 : 2).map((interest) => _InfoChip(
                    icon: Icons.auto_awesome,
                    label: interest.toString(),
                  )),
            ],
          ),

          // Gallery dots
          if (galleryCount > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                galleryCount.clamp(0, 6),
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        i == 0 ? Colors.white : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withOpacity(0.9)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
