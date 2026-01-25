import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/core/services/database_service.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/services/usage_service.dart';
import 'package:indira_love/core/services/matches_service.dart';
import 'package:indira_love/core/services/matching_algorithm_service.dart';
import 'package:indira_love/core/services/profile_cache_service.dart';
import 'package:indira_love/core/services/rate_limiter_service.dart';
import 'package:indira_love/features/discover/presentation/widgets/swipe_card.dart';

final discoverProvider = StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier(
    DatabaseService(),
    AuthService(),
    UsageService(),
    MatchesService(),
  );
});

class DiscoverState {
  final List<Map<String, dynamic>> potentialMatches;
  final bool isLoading;
  final int remainingLikes;
  final String? error;
  final bool showLimitDialog;

  DiscoverState({
    this.potentialMatches = const [],
    this.isLoading = false,
    this.remainingLikes = 10,
    this.error,
    this.showLimitDialog = false,
  });

  DiscoverState copyWith({
    List<Map<String, dynamic>>? potentialMatches,
    bool? isLoading,
    int? remainingLikes,
    String? error,
    bool? showLimitDialog,
  }) {
    return DiscoverState(
      potentialMatches: potentialMatches ?? this.potentialMatches,
      isLoading: isLoading ?? this.isLoading,
      remainingLikes: remainingLikes ?? this.remainingLikes,
      error: error ?? this.error,
      showLimitDialog: showLimitDialog ?? this.showLimitDialog,
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final DatabaseService _databaseService;
  final AuthService _authService;
  final UsageService _usageService;
  final MatchesService _matchesService;
  final MatchingAlgorithmService _matchingService = MatchingAlgorithmService();
  final ProfileCacheService _cacheService = ProfileCacheService();
  final RateLimiterService _rateLimiter = RateLimiterService();

  DiscoverNotifier(
    this._databaseService,
    this._authService,
    this._usageService,
    this._matchesService,
  ) : super(DiscoverState()) {
    _loadRemainingLikes();
  }

  Future<void> _loadRemainingLikes() async {
    final user = _authService.currentUser;
    if (user != null) {
      final remaining = await _usageService.getRemainingLikes(user.uid);
      state = state.copyWith(remainingLikes: remaining);
    }
  }

  /// Load potential matches with smart caching (95% cost reduction)
  /// Based on Velvet Connect's proven pattern:
  /// - Checks cache first (30-min expiry)
  /// - If fresh: uses cached profiles (ZERO Firebase cost)
  /// - If stale: fetches ALL users ONCE and caches
  /// - Applies filters client-side
  /// - Sorts by compatibility score
  Future<void> loadPotentialMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      logger.info('════════════════════════════════════════════════════════');
      logger.info('[Discovery] Starting loadPotentialMatches()');
      logger.info('[Discovery] Cache stats: ${_cacheService.getCacheStats()}'); // TODO: Use logger.logNetworkRequest if network call
      logger.info('════════════════════════════════════════════════════════');

      final user = _authService.currentUser;
      if (user == null) {
        logger.error('[Discovery] ERROR: No authenticated user found!');
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }

      logger.info('[Discovery] Current user ID: ${user.uid}');

      // Get current user's full profile
      final currentUserDoc = await _databaseService.getUserProfileOnce(user.uid);
      if (!currentUserDoc.exists) {
        logger.error('[Discovery] ERROR: Current user profile does not exist!');
        state = state.copyWith(isLoading: false, error: 'Profile not found');
        return;
      }

      final currentUserData = {
        'uid': user.uid,
        ...currentUserDoc.data() as Map<String, dynamic>,
      };
      logger.info('[Discovery] Current user profile loaded');

      // Get blocked users (bidirectional blocking)
      Set<String> blockedUserIds = {};
      try {
        blockedUserIds = await _databaseService.getAllBlockedUserIds();
        logger.logSecurityEvent('[Discovery] Blocked users count: ${blockedUserIds.length}');
      } catch (e) {
        logger.warning('[Discovery] Warning: Could not get blocked users: $e');
      }

      // SMART CACHING: Check cache first
      List<Map<String, dynamic>> allProfiles;

      if (_cacheService.isFullCacheFresh() && _cacheService.cachedCount > 0) {
        // ✅ CACHE HIT - Use cached data (ZERO Firebase cost!)
        logger.info('[Discovery] 🎯 CACHE HIT! Using cached profiles (zero Firebase cost)');
        logger.info('[Discovery] Cached profiles: ${_cacheService.cachedCount}');
        allProfiles = _cacheService.getAllCachedProfiles();
      } else {
        // ❌ CACHE MISS - Fetch ALL users from Firestore (one-time, no stream)
        logger.info('[Discovery] 💰 CACHE MISS - Fetching all users from Firestore...'); // TODO: Use logger.logNetworkRequest if network call

        final matchesQuery = await _databaseService.getPotentialMatchesOnce(user.uid);
        logger.info('[Discovery] Fetched ${matchesQuery.docs.length} total users from Firestore'); // TODO: Use logger.logNetworkRequest if network call

        if (matchesQuery.docs.isEmpty) {
          logger.warning('[Discovery] WARNING: No users found in Firestore!');
          state = state.copyWith(
            isLoading: false,
            potentialMatches: [],
            error: 'No users available. Please try again later.',
          );
          return;
        }

        // Convert to list
        allProfiles = matchesQuery.docs
            .map((doc) => {
                  'uid': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();

        // Cache for next 30 minutes (95% cost reduction on next load!)
        _cacheService.cacheFullUserList(allProfiles);
        logger.info('[Discovery] ✅ Cached ${allProfiles.length} users for 30 minutes');
      }

      // CLIENT-SIDE FILTERING (fast, no Firebase cost)
      logger.info('[Discovery] Applying client-side filters...');

      var filteredMatches = allProfiles.where((profile) {
        final userId = profile['uid'] as String?;
        if (userId == null) return false;

        // Filter out current user
        if (userId == user.uid) return false;

        // Filter out blocked users (bidirectional)
        if (blockedUserIds.contains(userId)) return false;

        return true;
      }).toList();

      logger.info('[Discovery] After filtering: ${filteredMatches.length} users');

      if (filteredMatches.isEmpty) {
        logger.warning('[Discovery] WARNING: No users after filtering');
        state = state.copyWith(
          isLoading: false,
          potentialMatches: [],
          error: 'No users available to show',
        );
        return;
      }

      // Calculate compatibility scores
      logger.info('[Discovery] Calculating compatibility scores...');
      for (var match in filteredMatches) {
        try {
          final score = _matchingService.calculateCompatibilityScore(
            currentUser: currentUserData,
            potentialMatch: match,
          );
          match['compatibilityScore'] = score;
        } catch (e) {
          logger.warning('[Discovery] Warning: Could not calculate score for ${match['uid']}: $e');
          match['compatibilityScore'] = 50.0; // Default score
        }
      }

      // Sort by compatibility (highest first)
      filteredMatches.sort((a, b) {
        final scoreA = (a['compatibilityScore'] as num?)?.toDouble() ?? 0.0;
        final scoreB = (b['compatibilityScore'] as num?)?.toDouble() ?? 0.0;

        // Boosted profiles appear first
        final isBoostedA = (a['isBoosted'] ?? false) as bool;
        final isBoostedB = (b['isBoosted'] ?? false) as bool;

        if (isBoostedA && !isBoostedB) return -1;
        if (!isBoostedA && isBoostedB) return 1;

        return scoreB.compareTo(scoreA);
      });

      logger.info('════════════════════════════════════════════════════════');
      logger.info('[Discovery] ✅ SUCCESS: ${filteredMatches.length} matches loaded');
      logger.info('[Discovery] Top 3 matches:');
      for (var i = 0; i < filteredMatches.length && i < 3; i++) {
        final match = filteredMatches[i];
        logger.info('  ${i + 1}. ${match['displayName'] ?? 'Unknown'} (${match['compatibilityScore']}% match)');
      }
      logger.info('════════════════════════════════════════════════════════');

      state = state.copyWith(
        potentialMatches: filteredMatches,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      logger.error('[Discovery] ERROR: loadPotentialMatches failed: $e');
      logger.info('[Discovery] Stack trace: ${StackTrace.current}');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load users. Please try again.',
      );
    }
  }

  Future<void> handleSwipe(SwipeDirection direction, String targetUserId) async {
    final user = _authService.currentUser;
    if (user == null) {
      logger.error('[Discovery] ERROR: No authenticated user found for swipe');
      return;
    }

    // RATE LIMITING: Check if user can swipe
    final swipeLimit = await _rateLimiter.checkSwipeLimit(user.uid);
    if (!swipeLimit.allowed) {
      logger.info('[Discovery] Rate limit exceeded: ${swipeLimit.reason}');
      state = state.copyWith(
        error: 'Slow down! ${swipeLimit.reason} Upgrade to Premium for unlimited swipes!',
      );
      return;
    }

    logger.info('[Discovery] Swipe allowed - direction: $direction, targetUserId: $targetUserId'); // TODO: Use logger.logNetworkRequest if network call

    try {
      // CHECK: If we're on the last user, reload all users for continuous swiping
      logger.debug('DEBUG: Current matches count: ${state.potentialMatches.length}');
      if (state.potentialMatches.length <= 1) {
        logger.debug('DEBUG: On last user! Reloading all users for continuous swiping...');
        await loadPotentialMatches();

        // After reload, make sure we don't remove the current user from the new batch
        // This ensures seamless transition
        final reloadedMatches = List<Map<String, dynamic>>.from(state.potentialMatches);
        if (reloadedMatches.any((match) => match['uid'] == targetUserId)) {
          logger.debug('DEBUG: Current user found in reloaded batch, will be removed');
        }
        logger.debug('DEBUG: Reload complete. Now have ${state.potentialMatches.length} matches');
      }

      // CRITICAL: Remove user from list FIRST before any async operations
      // This ensures UI updates immediately
      logger.debug('DEBUG: Current matches before removal: ${state.potentialMatches.length}');
      logger.info('DEBUG: Removing user: $targetUserId'); // TODO: Use logger.logNetworkRequest if network call
      final updatedMatches = List<Map<String, dynamic>>.from(state.potentialMatches);
      updatedMatches.removeWhere((match) => match['uid'] == targetUserId);
      logger.debug('DEBUG: Removed user from list. Remaining: ${updatedMatches.length}');

      if (updatedMatches.isNotEmpty) {
        logger.debug('DEBUG: Next user will be: ${updatedMatches.first['uid']} (${updatedMatches.first['displayName']})');
      }

      // Update state IMMEDIATELY - this will force UI to show next user
      state = state.copyWith(potentialMatches: updatedMatches);
      logger.debug('DEBUG: State updated with ${state.potentialMatches.length} matches');

      // Now handle the like/pass logic asynchronously in background
      if (direction == SwipeDirection.right) {
        logger.debug('DEBUG: Processing right swipe (like) in background');

        // Check if user can send a like
        final canLike = await _usageService.canSendLike(user.uid);
        logger.debug('DEBUG: Can send like: $canLike');

        if (!canLike) {
          logger.debug('DEBUG: Like limit reached, showing dialog');
          state = state.copyWith(showLimitDialog: true);
          return;
        }

        // User liked - increment usage
        logger.debug('DEBUG: Incrementing like count');
        await _usageService.incrementLikeCount(user.uid);

        // Create like in database (allow multiple likes to same person)
        logger.debug('DEBUG: Creating like in database');
        await _databaseService.likeUser(user.uid, targetUserId);

        // Check if it's a mutual match
        logger.debug('DEBUG: Checking for mutual match');
        final isMatch = await _matchesService.checkAndCreateMatch(user.uid, targetUserId);
        logger.debug('DEBUG: Is match: $isMatch');

        if (isMatch) {
          // Show match notification
          logger.debug('DEBUG: Mutual match found!');
          state = state.copyWith(error: '🎉 It\'s a Match!');
        }

        // Update remaining likes
        final remaining = await _usageService.getRemainingLikes(user.uid);
        logger.debug('DEBUG: Remaining likes: $remaining');
        state = state.copyWith(remainingLikes: remaining);
      } else {
        logger.debug('DEBUG: Processing left swipe (pass)');
      }

      // Record the swipe for analytics (both left and right)
      logger.debug('DEBUG: Recording swipe in database');
      await _databaseService.recordSwipe(
        user.uid,
        targetUserId,
        direction == SwipeDirection.right ? 'right' : 'left',
      );

      // Log the action
      await _databaseService.logUserAction(
        user.uid,
        'swipe',
        {
          'direction': direction == SwipeDirection.right ? 'right' : 'left',
          'targetUserId': targetUserId,
        },
      );

      logger.debug('DEBUG: Swipe handling completed successfully');
    } catch (e) {
      logger.error('ERROR: Swipe handling failed: $e');
      logger.error('ERROR Stack trace: ${StackTrace.current}');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refillLikesAfterAds(int adsWatched) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _usageService.refillLikes(user.uid, adsWatched);

      // Update remaining likes
      final remaining = await _usageService.getRemainingLikes(user.uid);
      state = state.copyWith(
        remainingLikes: remaining,
        showLimitDialog: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void dismissLimitDialog() {
    state = state.copyWith(showLimitDialog: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reload all users without filtering by swipe history (uses cache)
  Future<void> _reloadAllUsers() async {
    // Simply call the main load function which now uses caching
    await loadPotentialMatches();
  }
}
