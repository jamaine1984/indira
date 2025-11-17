import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:indira_love/core/theme/app_theme.dart';

enum SwipeDirection { left, right }

class SwipeCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isActive;
  final Function(SwipeDirection) onSwipe;
  final VoidCallback? onTap;

  const SwipeCard({
    super.key,
    required this.user,
    required this.isActive,
    required this.onSwipe,
    this.onTap,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _positionAnimation;

  double _dragStartX = 0;
  double _dragCurrentX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_animationController);

    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isActive) return;
    setState(() {
      _isDragging = true;
      _dragStartX = details.localPosition.dx;
      _dragCurrentX = details.localPosition.dx;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isActive || !_isDragging) return;
    setState(() {
      _dragCurrentX = details.localPosition.dx;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isActive || !_isDragging) return;

    final dragDistance = _dragCurrentX - _dragStartX;
    const swipeThreshold = 150.0; // Increased from 100 to make swipe harder

    print('DEBUG: Pan ended, drag distance: $dragDistance, threshold: $swipeThreshold');

    if (dragDistance.abs() > swipeThreshold) {
      final direction = dragDistance > 0 ? SwipeDirection.right : SwipeDirection.left;
      print('DEBUG: Swipe detected! Direction: $direction');

      // Animate card off screen
      _animateCardOffScreen(direction).then((_) {
        print('DEBUG: Animation complete, calling onSwipe callback');
        widget.onSwipe(direction);
      });
    } else {
      // Return to center
      print('DEBUG: Swipe too short, returning to center');
      setState(() {
        _isDragging = false;
        _dragCurrentX = _dragStartX;
      });
    }
  }

  Future<void> _animateCardOffScreen(SwipeDirection direction) async {
    print('DEBUG: Starting off-screen animation for direction: $direction');
    final screenWidth = MediaQuery.of(context).size.width;
    final endX = direction == SwipeDirection.right ? screenWidth * 2 : -screenWidth * 2;

    setState(() {
      _isDragging = false;
    });

    _rotationAnimation = Tween<double>(
      begin: _rotation,
      end: direction == SwipeDirection.right ? 0.3 : -0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _positionAnimation = Tween<Offset>(
      begin: _position,
      end: Offset(endX, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.reset();
    await _animationController.forward();
    print('DEBUG: Off-screen animation completed');
  }

  double get _rotation {
    if (_animationController.isAnimating) {
      return _rotationAnimation.value;
    }
    if (!_isDragging || !widget.isActive) return 0;
    final dragDistance = _dragCurrentX - _dragStartX;
    return dragDistance * 0.0005; // Reduced from 0.001 for slower rotation
  }

  Offset get _position {
    if (_animationController.isAnimating) {
      return _positionAnimation.value;
    }
    if (!_isDragging || !widget.isActive) return Offset.zero;
    final dragDistance = _dragCurrentX - _dragStartX;
    return Offset(dragDistance * 0.3, 0); // Reduced from 0.5 for slower movement
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.isActive && widget.onTap != null ? widget.onTap : null,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: _position,
            child: Transform.rotate(
              angle: _rotation,
              child: Container(
            width: screenSize.width,
            height: screenSize.height,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Image
                  _buildProfileImage(),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),

                  // Swipe Indicators
                  if (_isDragging && widget.isActive) _buildSwipeIndicators(),

                  // Profile Info
                  _buildProfileInfo(),
                ],
              ),
            ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    final photos = widget.user['photos'] as List<dynamic>? ?? [];
    final mainPhoto = photos.isNotEmpty ? photos[0] : null;

    print('DEBUG: User ${widget.user['displayName']} photos: $photos');
    print('DEBUG: Main photo URL: $mainPhoto');

    if (mainPhoto != null && mainPhoto.toString().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: mainPhoto.toString(),
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppTheme.secondaryPlum.withOpacity(0.3),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorWidget: (context, url, error) {
          print('DEBUG: Error loading image: $error');
          print('DEBUG: URL was: $url');
          return Container(
            color: AppTheme.secondaryPlum.withOpacity(0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Photo Error',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      print('DEBUG: No photo available for ${widget.user['displayName']}');
      return Container(
        color: AppTheme.secondaryPlum.withOpacity(0.3),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                widget.user['displayName'] ?? 'Unknown',
                style: const TextStyle(
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
  }

  Widget _buildSwipeIndicators() {
    final dragDistance = _dragCurrentX - _dragStartX;
    final isLike = dragDistance > 50;
    final isPass = dragDistance < -50;

    return Positioned(
      top: 50,
      left: isPass ? 20 : null,
      right: isLike ? 20 : null,
      child: Transform.rotate(
        angle: isPass ? -0.2 : 0.2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLike ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: Text(
            isLike ? 'LIKE' : 'PASS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final displayName = widget.user['displayName'] ?? 'Unknown';
    final age = widget.user['age'] ?? 0;
    final bio = widget.user['bio'] ?? '';
    // Location is GeoPoint from Firestore, get city/country string if available
    final locationString = widget.user['city'] as String? ?? widget.user['country'] as String? ?? '';
    final interests = widget.user['interests'] as List<dynamic>? ?? [];
    final compatibilityScore = widget.user['compatibilityScore'] as double?;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match percentage badge (if available)
            if (compatibilityScore != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryRose,
                        AppTheme.secondaryPlum,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRose.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${compatibilityScore.round()}% Match',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Name and Age
            Row(
              children: [
                Text(
                  '$displayName, $age',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.user['isVerified'] == true)
                  const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 24,
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // Location (only show if we have a string location)
            if (locationString.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locationString,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Bio
            if (bio.isNotEmpty)
              Text(
                bio,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 12),

            // Interests
            if (interests.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: interests.take(3).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      interest.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
