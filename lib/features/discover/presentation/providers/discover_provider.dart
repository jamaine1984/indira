import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/services/database_service.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/core/services/usage_service.dart';
import 'package:indira_love/core/services/matches_service.dart';
import 'package:indira_love/core/services/matching_algorithm_service.dart';
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

  Future<void> loadPotentialMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('════════════════════════════════════════════════════════');
      print('DEBUG: Starting loadPotentialMatches()');
      print('════════════════════════════════════════════════════════');

      final user = _authService.currentUser;
      if (user == null) {
        print('ERROR: No authenticated user found!');
        return;
      }

      print('DEBUG: Current user ID: ${user.uid}');
      print('DEBUG: Current user email: ${user.email}');

      // Get current user's full profile
      final currentUserDoc = await _databaseService.getUserProfileOnce(user.uid);
      final currentUserData = {
        'uid': user.uid,
        ...currentUserDoc.data() as Map<String, dynamic>,
      };
      print('DEBUG: Current user profile loaded');
      print('DEBUG: User has location: ${currentUserData['location'] != null}');
      print('DEBUG: User interests: ${currentUserData['interests']?.length ?? 0}');

      // Get blocked users (but don't fail if this errors)
      Set<String> blockedUserIds = {};
      try {
        blockedUserIds = await _databaseService.getAllBlockedUserIds();
        print('DEBUG: Blocked users count: ${blockedUserIds.length}');
        if (blockedUserIds.isNotEmpty) {
          print('DEBUG: Blocked user IDs: $blockedUserIds');
        }
      } catch (e) {
        print('Warning: Could not get blocked users: $e');
      }

      // Get potential matches from Firestore
      print('DEBUG: Fetching potential matches from Firestore...');
      final matchesQuery = await _databaseService.getPotentialMatches(user.uid).first;
      print('DEBUG: Total documents from Firestore: ${matchesQuery.docs.length}');

      // Log all user IDs from Firestore
      print('DEBUG: All user IDs in Firestore:');
      for (var doc in matchesQuery.docs) {
        print('  - ${doc.id} (${(doc.data() as Map<String, dynamic>)['displayName'] ?? 'No name'})');
      }

      // Filter out ONLY current user and blocked users (show all other users)
      var filteredMatches = matchesQuery.docs
          .where((doc) {
            final docId = doc.id;
            final isCurrentUser = docId == user.uid;
            final isBlocked = blockedUserIds.contains(docId);

            if (isCurrentUser) {
              print('DEBUG: Filtering out current user: $docId');
            }
            if (isBlocked) {
              print('DEBUG: Filtering out blocked user: $docId');
            }

            // Only filter out current user and blocked users
            return !isCurrentUser && !isBlocked;
          })
          .map((doc) => {
                'uid': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      print('DEBUG: After basic filtering: ${filteredMatches.length} users');
      print('DEBUG: Filtered user IDs:');
      for (var match in filteredMatches) {
        print('  - ${match['uid']} (${match['displayName'] ?? 'No name'})');
      }

      // Get all users current user has already interacted with (swiped or liked)
      print('DEBUG: Fetching interaction history...');
      final interactedUserIds = await _databaseService.getAllInteractedUserIds(user.uid);
      print('DEBUG: Already interacted with ${interactedUserIds.length} users');
      if (interactedUserIds.isNotEmpty && interactedUserIds.length <= 10) {
        print('DEBUG: Interacted user IDs: $interactedUserIds');
      }

      // Filter out already-interacted users
      filteredMatches = filteredMatches.where((match) {
        final hasInteracted = interactedUserIds.contains(match['uid']);
        if (hasInteracted) {
          print('DEBUG: Filtering out already-interacted user: ${match['uid']} (${match['displayName'] ?? 'No name'})');
        }
        return !hasInteracted;
      }).toList();

      print('DEBUG: After interaction filtering: ${filteredMatches.length} users');

      // RANDOMIZE THE ORDER - Critical to prevent always showing same users in same order
      print('DEBUG: Randomizing user order...');
      filteredMatches.shuffle();

      // Try smart matching, but don't fail if it errors
      final beforeSmartMatching = filteredMatches.length;
      try {
        print('DEBUG: Running smart matching algorithm...');
        filteredMatches = await _matchingService.getSmartRecommendations(
          currentUser: currentUserData,
          allPotentialMatches: filteredMatches,
        );
        print('DEBUG: Smart matching complete: ${filteredMatches.length} users (was $beforeSmartMatching)');
      } catch (e) {
        print('Warning: Smart matching failed, using basic list: $e');
        print('Warning: Stack trace: ${StackTrace.current}');
        // Keep filteredMatches as is
      }

      // Calculate and add compatibility score to each match if not already present
      print('DEBUG: Calculating compatibility scores...');
      for (var match in filteredMatches) {
        if (match['compatibilityScore'] == null) {
          final score = _matchingService.calculateCompatibilityScore(
            currentUser: currentUserData,
            potentialMatch: match,
          );
          match['compatibilityScore'] = score;
          print('DEBUG: ${match['displayName'] ?? match['uid']}: ${score}% match');
        }
      }

      print('════════════════════════════════════════════════════════');
      print('DEBUG: FINAL RESULT: ${filteredMatches.length} potential matches loaded');
      print('════════════════════════════════════════════════════════');

      state = state.copyWith(
        potentialMatches: filteredMatches,
        isLoading: false,
      );
    } catch (e) {
      print('ERROR: loadPotentialMatches failed: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> handleSwipe(SwipeDirection direction, String targetUserId) async {
    final user = _authService.currentUser;
    if (user == null) {
      print('ERROR: No authenticated user found for swipe');
      return;
    }

    print('DEBUG: handleSwipe called - direction: $direction, targetUserId: $targetUserId');

    try {
      // PRELOAD CHECK: If we have 3 or fewer matches, preload more BEFORE removing
      // This prevents showing "no more matches" screen during processing
      print('DEBUG: Current matches count: ${state.potentialMatches.length}');
      if (state.potentialMatches.length <= 3) {
        print('DEBUG: Low on matches (${state.potentialMatches.length}), preloading more users...');
        await loadPotentialMatches();
        print('DEBUG: Preload complete. Now have ${state.potentialMatches.length} matches');
      }

      // CRITICAL: Remove user from list FIRST before any async operations
      // This ensures UI updates immediately
      print('DEBUG: Current matches before removal: ${state.potentialMatches.length}');
      print('DEBUG: Removing user: $targetUserId');
      final updatedMatches = List<Map<String, dynamic>>.from(state.potentialMatches);
      updatedMatches.removeWhere((match) => match['uid'] == targetUserId);
      print('DEBUG: Removed user from list. Remaining: ${updatedMatches.length}');

      if (updatedMatches.isNotEmpty) {
        print('DEBUG: Next user will be: ${updatedMatches.first['uid']} (${updatedMatches.first['displayName']})');
      }

      // Update state IMMEDIATELY - this will force UI to show next user
      state = state.copyWith(potentialMatches: updatedMatches);
      print('DEBUG: State updated with ${state.potentialMatches.length} matches');

      // Now handle the like/pass logic asynchronously in background
      if (direction == SwipeDirection.right) {
        print('DEBUG: Processing right swipe (like) in background');

        // Check if user can send a like
        final canLike = await _usageService.canSendLike(user.uid);
        print('DEBUG: Can send like: $canLike');

        if (!canLike) {
          print('DEBUG: Like limit reached, showing dialog');
          state = state.copyWith(showLimitDialog: true);
          return;
        }

        // User liked - increment usage
        print('DEBUG: Incrementing like count');
        await _usageService.incrementLikeCount(user.uid);

        // Create like in database (allow multiple likes to same person)
        print('DEBUG: Creating like in database');
        await _databaseService.likeUser(user.uid, targetUserId);

        // Check if it's a mutual match
        print('DEBUG: Checking for mutual match');
        final isMatch = await _matchesService.checkAndCreateMatch(user.uid, targetUserId);
        print('DEBUG: Is match: $isMatch');

        if (isMatch) {
          // Show match notification
          print('DEBUG: Mutual match found!');
          state = state.copyWith(error: '🎉 It\'s a Match!');
        }

        // Update remaining likes
        final remaining = await _usageService.getRemainingLikes(user.uid);
        print('DEBUG: Remaining likes: $remaining');
        state = state.copyWith(remainingLikes: remaining);
      } else {
        print('DEBUG: Processing left swipe (pass)');
      }

      // Record the swipe for analytics (both left and right)
      print('DEBUG: Recording swipe in database');
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

      print('DEBUG: Swipe handling completed successfully');
    } catch (e) {
      print('ERROR: Swipe handling failed: $e');
      print('ERROR Stack trace: ${StackTrace.current}');
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

  /// Reload all users without filtering by swipe history (for when all users have been swiped)
  Future<void> _reloadAllUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      print('════════════════════════════════════════════════════════');
      print('DEBUG: RELOADING ALL USERS (ignoring swipe history)');
      print('════════════════════════════════════════════════════════');

      // Get current user's full profile
      final currentUserDoc = await _databaseService.getUserProfileOnce(user.uid);
      final currentUserData = {
        'uid': user.uid,
        ...currentUserDoc.data() as Map<String, dynamic>,
      };

      // Get blocked users (still respect blocks)
      Set<String> blockedUserIds = {};
      try {
        blockedUserIds = await _databaseService.getAllBlockedUserIds();
        print('DEBUG: Blocked users count: ${blockedUserIds.length}');
      } catch (e) {
        print('Warning: Could not get blocked users: $e');
      }

      // Get potential matches from Firestore
      print('DEBUG: Fetching all users from Firestore...');
      final matchesQuery = await _databaseService.getPotentialMatches(user.uid).first;
      print('DEBUG: Total documents from Firestore: ${matchesQuery.docs.length}');

      // Filter out ONLY current user and blocked users (IGNORE swipe history)
      var filteredMatches = matchesQuery.docs
          .where((doc) {
            final docId = doc.id;
            final isCurrentUser = docId == user.uid;
            final isBlocked = blockedUserIds.contains(docId);
            return !isCurrentUser && !isBlocked;
          })
          .map((doc) => {
                'uid': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      print('DEBUG: After basic filtering: ${filteredMatches.length} users');

      // RANDOMIZE THE ORDER - Show users in completely different order
      print('DEBUG: Randomizing user order...');
      filteredMatches.shuffle();

      // Calculate compatibility scores
      print('DEBUG: Calculating compatibility scores...');
      for (var match in filteredMatches) {
        try {
          final score = _matchingService.calculateCompatibilityScore(
            currentUser: currentUserData,
            potentialMatch: match,
          );
          match['compatibilityScore'] = score;
          print('DEBUG: ${match['displayName'] ?? match['uid']}: ${score}% match');
        } catch (e) {
          print('Warning: Could not calculate score for ${match['uid']}: $e');
          match['compatibilityScore'] = 50; // Default score
        }
      }

      print('════════════════════════════════════════════════════════');
      print('DEBUG: RELOAD COMPLETE: ${filteredMatches.length} users loaded');
      print('════════════════════════════════════════════════════════');

      state = state.copyWith(
        potentialMatches: filteredMatches,
        isLoading: false,
      );
    } catch (e) {
      print('ERROR: _reloadAllUsers failed: $e');
      print('ERROR: Stack trace: ${StackTrace.current}');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}
