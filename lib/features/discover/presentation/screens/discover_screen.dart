import 'package:flutter/material.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/widgets/watch_ads_dialog.dart';
import 'package:indira_love/core/services/location_service.dart';
import 'package:indira_love/features/discover/presentation/widgets/swipe_card.dart';
import 'package:indira_love/features/discover/presentation/providers/discover_provider.dart';
import 'package:indira_love/features/auth/presentation/providers/auth_provider.dart';
import 'package:indira_love/features/likes/presentation/widgets/boost_timer_widget.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Filter state
  RangeValues _ageRange = const RangeValues(18, 99);
  double _distance = 100;
  Set<String> _selectedGenders = {'Male', 'Female', 'Other'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(discoverProvider);
      if (state.potentialMatches.isEmpty && !state.isLoading) {
        logger.debug('DEBUG DISCOVER: No users loaded on init, loading now...');
        ref.read(discoverProvider.notifier).loadPotentialMatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProvider);
    final currentUser = ref.watch(authProvider).user;

    // Show ad dialog when limit is reached
    if (discoverState.showLimitDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showWatchAdsDialog(
          context,
          type: 'likes',
          adsRequired: 3,
          onComplete: () {
            ref.read(discoverProvider.notifier).refillLikesAfterAds(3);
          },
        );
        ref.read(discoverProvider.notifier).dismissLimitDialog();
      });
    }

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildHamburgerMenu(context),
      body: Column(
        children: [
          // Top bar with logo and hamburger menu
          Container(
            color: Colors.black.withOpacity(0.3),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // App Logo/Name
                    Text(
                      'Indira Love',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                    ),

                    // Hamburger Menu Icon
                    IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Boost timer widget
          const BoostTimerWidget(),

          // Swipe cards area - 90% of remaining screen
          Expanded(
            child: discoverState.isLoading
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: AppTheme.romanticGradient,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : discoverState.potentialMatches.isEmpty
                    ? _buildEmptyState()
                    : discoverState.potentialMatches.isNotEmpty
                        ? SwipeCard(
                            key: ValueKey(discoverState.potentialMatches.first['uid']),
                            user: discoverState.potentialMatches.first,
                            isActive: true,
                            onSwipe: (direction) {
                              logger.debug('DEBUG: onSwipe callback triggered for user: ${discoverState.potentialMatches.first['uid']}');
                              ref.read(discoverProvider.notifier).handleSwipe(
                                    direction,
                                    discoverState.potentialMatches.first['uid'],
                                  );
                            },
                            onTap: () {
                              // Navigate to user profile
                              context.push('/user-profile/${discoverState.potentialMatches.first['uid']}');
                            },
                          )
                        : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildHamburgerMenu(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(color: Colors.white30, thickness: 1),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildMenuItem(
                      icon: Icons.explore,
                      title: 'Discover',
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.thumb_up,
                      title: 'Likes',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/likes');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.filter_list,
                      title: 'Filters',
                      onTap: () {
                        Navigator.pop(context);
                        _showFiltersDialog(context);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.location_on,
                      title: 'Location Settings',
                      onTap: () {
                        Navigator.pop(context);
                        _showLocationDialog(context);
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.chat_bubble,
                      title: 'Messages',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/messages');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.favorite,
                      title: 'Matches',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/matches');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.people,
                      title: 'Social',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/social');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.card_giftcard,
                      title: 'Gifts',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/gifts');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.workspace_premium,
                      title: 'Premium',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/subscription');
                      },
                    ),
                    const Divider(color: Colors.white30, height: 32),
                    _buildMenuItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/welcome');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  Widget _buildEmptyState() {
    final discoverState = ref.watch(discoverProvider);
    final hasError = discoverState.error != null && discoverState.error!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.romanticGradient,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.refresh,
                size: 100,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 32),
              Text(
                hasError ? 'Oops!' : 'Loading Users...',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  discoverState.error ?? 'Finding potential matches for you',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Troubleshooting:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Check your internet connection\n'
                        '• Make sure there are users in the database\n'
                        '• Try logging out and back in\n'
                        '• Contact support if issue persists',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(discoverProvider.notifier).loadPotentialMatches();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFiltersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Matches', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Age Range
                const Text('Age Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                  style: TextStyle(color: AppTheme.secondaryPlum, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 99,
                  divisions: 81,
                  activeColor: AppTheme.primaryRose,
                  inactiveColor: AppTheme.accentGold,
                  labels: RangeLabels(
                    _ageRange.start.round().toString(),
                    _ageRange.end.round().toString(),
                  ),
                  onChanged: (RangeValues values) {
                    setDialogState(() {
                      _ageRange = values;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Distance
                const Text('Maximum Distance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  '${_distance.round()} km',
                  style: TextStyle(color: AppTheme.secondaryPlum, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Slider(
                  value: _distance,
                  min: 1,
                  max: 500,
                  divisions: 99,
                  activeColor: AppTheme.primaryRose,
                  inactiveColor: AppTheme.accentGold,
                  label: '${_distance.round()} km',
                  onChanged: (double value) {
                    setDialogState(() {
                      _distance = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // Gender
                const Text('Show me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Men'),
                  value: _selectedGenders.contains('Male'),
                  activeColor: AppTheme.primaryRose,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        _selectedGenders.add('Male');
                      } else {
                        _selectedGenders.remove('Male');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Women'),
                  value: _selectedGenders.contains('Female'),
                  activeColor: AppTheme.primaryRose,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        _selectedGenders.add('Female');
                      } else {
                        _selectedGenders.remove('Female');
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Other'),
                  value: _selectedGenders.contains('Other'),
                  activeColor: AppTheme.primaryRose,
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        _selectedGenders.add('Other');
                      } else {
                        _selectedGenders.remove('Other');
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Apply filters and reload matches
                ref.read(discoverProvider.notifier).loadPotentialMatches();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Filters applied: Age ${_ageRange.start.round()}-${_ageRange.end.round()}, ${_distance.round()}km, ${_selectedGenders.join(", ")}',
                    ),
                    backgroundColor: AppTheme.secondaryPlum,
                  ),
                );
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context) async {
    final locationService = LocationService();
    final currentUser = ref.read(authProvider).user;

    // Check current permission status
    final permission = await locationService.checkPermission();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Settings'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Allow Indira Love to access your location to find matches nearby.'),
              const SizedBox(height: 16),
              if (permission == LocationPermission.deniedForever) ...[
                const Text(
                  'Location permission is permanently denied. Please enable it in app settings.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await locationService.openSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                  ),
                  icon: const Icon(Icons.settings),
                  label: const Text('Open Settings'),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    if (currentUser?.uid == null) return;

                    // Request and update location
                    final success = await locationService.updateUserLocation(currentUser!.uid);

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to get location. Please check your settings.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                  ),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Enable Location'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
