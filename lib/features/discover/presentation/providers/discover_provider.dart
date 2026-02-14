import 'package:cloud_firestore/cloud_firestore.dart';
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
  final DocumentSnapshot? lastDocument; // For pagination
  final bool hasMoreUsers; // Track if more users available
  final Map<String, dynamic>? currentFilters; // Active filters

  DiscoverState({
    this.potentialMatches = const [],
    this.isLoading = false,
    this.remainingLikes = 10,
    this.error,
    this.showLimitDialog = false,
    this.lastDocument,
    this.hasMoreUsers = true,
    this.currentFilters,
  });

  DiscoverState copyWith({
    List<Map<String, dynamic>>? potentialMatches,
    bool? isLoading,
    int? remainingLikes,
    String? error,
    bool? showLimitDialog,
    DocumentSnapshot? lastDocument,
    bool? hasMoreUsers,
    Map<String, dynamic>? currentFilters,
  }) {
    return DiscoverState(
      potentialMatches: potentialMatches ?? this.potentialMatches,
      isLoading: isLoading ?? this.isLoading,
      remainingLikes: remainingLikes ?? this.remainingLikes,
      error: error ?? this.error,
      showLimitDialog: showLimitDialog ?? this.showLimitDialog,
      lastDocument: lastDocument,
      hasMoreUsers: hasMoreUsers ?? this.hasMoreUsers,
      currentFilters: currentFilters ?? this.currentFilters,
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

  // Pagination configuration for 1M+ users
  static const int _pageSize = 50; // Fetch 50 users at a time
  static const int _prefetchThreshold = 10; // Prefetch when 10 users left

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

  /// Load potential matches with PAGINATION for 1M+ users scalability
  /// - Fetches 50 users at a time
  /// - Uses location filters to reduce dataset
  /// - Prefetches next batch when running low
  Future<void> loadPotentialMatches({bool loadMore = false}) async {
    // Prevent duplicate loading
    if (state.isLoading) return;

    // Don't load more if no more users available
    if (loadMore && !state.hasMoreUsers) {
      logger.info('[Discovery] No more users to load');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      logger.info('════════════════════════════════════════════════════════');
      logger.info('[Discovery] Starting loadPotentialMatches (Paginated)');
      logger.info('[Discovery] LoadMore: $loadMore, PageSize: $_pageSize');
      logger.info('════════════════════════════════════════════════════════');

      final user = _authService.currentUser;
      if (user == null) {
        logger.error('[Discovery] ERROR: No authenticated user found!');
        state = state.copyWith(isLoading: false, error: 'Not authenticated');
        return;
      }

      // Get current user's profile for location/preference filters
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

      // Build filters from user preferences
      Map<String, dynamic> filters = {};

      // Use location filters to reduce dataset
      if (currentUserData['city'] != null) {
        filters['city'] = currentUserData['city'];
      } else if (currentUserData['state'] != null) {
        filters['state'] = currentUserData['state'];
      } else if (currentUserData['country'] != null) {
        filters['country'] = currentUserData['country'];
      }

      // Add age preference filters
      if (currentUserData['agePreferenceMin'] != null &&
          currentUserData['agePreferenceMax'] != null) {
        filters['minAge'] = currentUserData['agePreferenceMin'];
        filters['maxAge'] = currentUserData['agePreferenceMax'];
      }

      // Get blocked users
      Set<String> blockedUserIds = {};
      try {
        blockedUserIds = await _databaseService.getAllBlockedUserIds();
        logger.info('[Discovery] Blocked users count: ${blockedUserIds.length}');
      } catch (e) {
        logger.warning('[Discovery] Warning: Could not get blocked users: $e');
      }

      // PAGINATED FETCH
      QuerySnapshot matchesQuery;

      if (loadMore && state.lastDocument != null) {
        // Load next page
        logger.info('[Discovery] Loading next page after document: ${state.lastDocument!.id}');
        matchesQuery = await _databaseService.getPotentialMatchesPaginated(
          currentUserId: user.uid,
          limit: _pageSize,
          startAfter: state.lastDocument,
          filters: filters,
        );
      } else {
        // Initial load or refresh
        logger.info('[Discovery] Loading first page with filters: $filters');
        matchesQuery = await _databaseService.getPotentialMatchesPaginated(
          currentUserId: user.uid,
          limit: _pageSize,
          filters: filters,
        );
      }

      logger.info('[Discovery] Fetched ${matchesQuery.docs.length} users from Firestore');

      if (matchesQuery.docs.isEmpty && !loadMore) {
        logger.warning('[Discovery] No users found with current filters');
        state = state.copyWith(
          isLoading: false,
          potentialMatches: [],
          error: 'No users found nearby. Try expanding your search area.',
          hasMoreUsers: false,
        );
        return;
      }

      // Convert to list
      final newProfiles = matchesQuery.docs
          .map((doc) => {
                'uid': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .where((profile) {
            // Client-side filtering for blocked users
            final userId = profile['uid'] as String?;
            return userId != null && !blockedUserIds.contains(userId);
          })
          .toList();

      // Cache these profiles
      if (newProfiles.isNotEmpty) {
        _cacheService.cachePaginatedProfiles(
          newProfiles,
          '${filters.toString()}_page_${state.lastDocument?.id ?? 'first'}',
        );
      }

      // Calculate compatibility scores
      for (var match in newProfiles) {
        try {
          final score = _matchingService.calculateCompatibilityScore(
            currentUser: currentUserData,
            potentialMatch: match,
          );
          match['compatibilityScore'] = score;
        } catch (e) {
          logger.warning('[Discovery] Could not calculate score: $e');
          match['compatibilityScore'] = 50.0;
        }
      }

      // Sort by compatibility (boosted profiles first)
      newProfiles.sort((a, b) {
        final isBoostedA = (a['isBoosted'] ?? false) as bool;
        final isBoostedB = (b['isBoosted'] ?? false) as bool;

        if (isBoostedA && !isBoostedB) return -1;
        if (!isBoostedA && isBoostedB) return 1;

        final scoreA = (a['compatibilityScore'] as num?)?.toDouble() ?? 0.0;
        final scoreB = (b['compatibilityScore'] as num?)?.toDouble() ?? 0.0;
        return scoreB.compareTo(scoreA);
      });

      // Update state
      final updatedMatches = loadMore
          ? [...state.potentialMatches, ...newProfiles]
          : newProfiles;

      final lastDoc = matchesQuery.docs.isNotEmpty
          ? matchesQuery.docs.last
          : state.lastDocument;

      final hasMore = matchesQuery.docs.length == _pageSize;

      logger.info('════════════════════════════════════════════════════════');
      logger.info('[Discovery] ✅ SUCCESS: ${newProfiles.length} new matches loaded');
      logger.info('[Discovery] Total matches: ${updatedMatches.length}');
      logger.info('[Discovery] Has more users: $hasMore');
      logger.info('════════════════════════════════════════════════════════');

      state = state.copyWith(
        potentialMatches: updatedMatches,
        isLoading: false,
        error: null,
        lastDocument: lastDoc,
        hasMoreUsers: hasMore,
        currentFilters: filters,
      );

      // Prefetch if running low
      if (updatedMatches.length < _prefetchThreshold && hasMore) {
        logger.info('[Discovery] Running low on users, prefetching next batch...');
        // Delay slightly to avoid rapid fetches
        Future.delayed(const Duration(milliseconds: 500), () {
          loadPotentialMatches(loadMore: true);
        });
      }
    } catch (e) {
      logger.error('[Discovery] ERROR: loadPotentialMatches failed: $e');
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

    // Rate limiting check
    final swipeLimit = await _rateLimiter.checkSwipeLimit(user.uid);
    if (!swipeLimit.allowed) {
      logger.info('[Discovery] Rate limit exceeded: ${swipeLimit.reason}');
      state = state.copyWith(
        error: 'Slow down! ${swipeLimit.reason} Upgrade to Premium for unlimited swipes!',
      );
      return;
    }

    try {
      // Remove user from list
      final updatedMatches = List<Map<String, dynamic>>.from(state.potentialMatches);
      updatedMatches.removeWhere((match) => match['uid'] == targetUserId);
      state = state.copyWith(potentialMatches: updatedMatches);

      // Check if we need to load more users
      if (updatedMatches.length < _prefetchThreshold && state.hasMoreUsers) {
        logger.info('[Discovery] Low on users, loading more...');
        loadPotentialMatches(loadMore: true);
      }

      // Handle like/pass logic
      if (direction == SwipeDirection.right) {
        // Check daily limit
        final canLike = await _usageService.canSendLike(user.uid);
        if (!canLike) {
          state = state.copyWith(showLimitDialog: true);
          return;
        }

        // Process like
        await _usageService.incrementLikeCount(user.uid);
        await _databaseService.likeUser(user.uid, targetUserId);

        // Check for match
        final isMatch = await _matchesService.checkAndCreateMatch(user.uid, targetUserId);
        if (isMatch) {
          state = state.copyWith(error: '🎉 It\'s a Match!');
        }

        // Update remaining likes
        final remaining = await _usageService.getRemainingLikes(user.uid);
        state = state.copyWith(remainingLikes: remaining);
      }

      // Record swipe
      await _databaseService.recordSwipe(
        user.uid,
        targetUserId,
        direction == SwipeDirection.right ? 'right' : 'left',
      );

      // Log action
      await _databaseService.logUserAction(
        user.uid,
        'swipe',
        {
          'direction': direction == SwipeDirection.right ? 'right' : 'left',
          'targetUserId': targetUserId,
        },
      );
    } catch (e) {
      logger.error('ERROR: Swipe handling failed: $e');
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

  /// Process a swipe without modifying the potentialMatches list.
  /// Used by the CardSwiper-based discover screen.
  /// Returns true if the swipe resulted in a match.
  Future<bool> processSwipe(SwipeDirection direction, String targetUserId) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    // Rate limiting check
    final swipeLimit = await _rateLimiter.checkSwipeLimit(user.uid);
    if (!swipeLimit.allowed) {
      state = state.copyWith(
        error: 'Slow down! ${swipeLimit.reason} Upgrade to Premium for unlimited swipes!',
      );
      return false;
    }

    try {
      bool isMatch = false;

      if (direction == SwipeDirection.right || direction == SwipeDirection.up) {
        // Check daily limit
        final canLike = await _usageService.canSendLike(user.uid);
        if (!canLike) {
          state = state.copyWith(showLimitDialog: true);
          return false;
        }

        // Process like
        await _usageService.incrementLikeCount(user.uid);
        await _databaseService.likeUser(user.uid, targetUserId);

        // Check for match
        isMatch = await _matchesService.checkAndCreateMatch(user.uid, targetUserId);

        // Update remaining likes
        final remaining = await _usageService.getRemainingLikes(user.uid);
        state = state.copyWith(remainingLikes: remaining);
      }

      // Record swipe direction
      final dirStr = switch (direction) {
        SwipeDirection.right => 'right',
        SwipeDirection.up => 'up',
        SwipeDirection.left => 'left',
      };

      await _databaseService.recordSwipe(user.uid, targetUserId, dirStr);
      await _databaseService.logUserAction(user.uid, 'swipe', {
        'direction': dirStr,
        'targetUserId': targetUserId,
      });

      return isMatch;
    } catch (e) {
      logger.error('ERROR: processSwipe failed: $e');
      return false;
    }
  }

  /// Apply new filters and reload users
  Future<void> applyFilters(Map<String, dynamic> filters) async {
    state = state.copyWith(
      currentFilters: filters,
      potentialMatches: [],
      lastDocument: null,
      hasMoreUsers: true,
    );
    await loadPotentialMatches();
  }

  /// Clear all filters and reload
  Future<void> clearFilters() async {
    state = state.copyWith(
      currentFilters: null,
      potentialMatches: [],
      lastDocument: null,
      hasMoreUsers: true,
    );
    await loadPotentialMatches();
  }
}