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
      final user = _authService.currentUser;
      if (user == null) return;

      // Get current user's full profile
      final currentUserDoc = await _databaseService.getUserProfileOnce(user.uid);
      final currentUserData = {
        'uid': user.uid,
        ...currentUserDoc.data() as Map<String, dynamic>,
      };

      // Get blocked users (but don't fail if this errors)
      Set<String> blockedUserIds = {};
      try {
        blockedUserIds = await _databaseService.getAllBlockedUserIds();
      } catch (e) {
        print('Warning: Could not get blocked users: $e');
      }

      // Get potential matches from Firestore
      final matchesQuery = await _databaseService.getPotentialMatches(user.uid).first;

      // Filter out ONLY current user and blocked users (show all other users)
      var filteredMatches = matchesQuery.docs
          .where((doc) {
            final docId = doc.id;
            final isCurrentUser = docId == user.uid;
            final isBlocked = blockedUserIds.contains(docId);

            // Only filter out current user and blocked users
            return !isCurrentUser && !isBlocked;
          })
          .map((doc) => {
                'uid': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      // Try smart matching, but don't fail if it errors
      try {
        filteredMatches = await _matchingService.getSmartRecommendations(
          currentUser: currentUserData,
          allPotentialMatches: filteredMatches,
        );
      } catch (e) {
        print('Warning: Smart matching failed, using basic list: $e');
        // Keep filteredMatches as is
      }

      print('Loaded ${filteredMatches.length} potential matches');

      state = state.copyWith(
        potentialMatches: filteredMatches,
        isLoading: false,
      );
    } catch (e) {
      print('Error loading potential matches: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> handleSwipe(SwipeDirection direction, String targetUserId) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      if (direction == SwipeDirection.right) {
        // Check if user can send a like
        final canLike = await _usageService.canSendLike(user.uid);

        if (!canLike) {
          state = state.copyWith(showLimitDialog: true);
          return;
        }

        // User liked - increment usage
        await _usageService.incrementLikeCount(user.uid);

        // Create like in database (allow multiple likes to same person)
        await _databaseService.likeUser(user.uid, targetUserId);

        // Check if it's a mutual match
        final isMatch = await _matchesService.checkAndCreateMatch(user.uid, targetUserId);

        if (isMatch) {
          // Show match notification
          state = state.copyWith(error: '🎉 It\'s a Match!');
        }

        // Update remaining likes
        final remaining = await _usageService.getRemainingLikes(user.uid);
        state = state.copyWith(remainingLikes: remaining);
      }

      // Record the swipe for analytics (both left and right)
      await _databaseService.recordSwipe(
        user.uid,
        targetUserId,
        direction == SwipeDirection.right ? 'right' : 'left',
      );

      // Remove the swiped user from the list
      final updatedMatches = List<Map<String, dynamic>>.from(state.potentialMatches);
      updatedMatches.removeWhere((match) => match['uid'] == targetUserId);

      state = state.copyWith(potentialMatches: updatedMatches);

      // If we have less than 5 matches, load more
      if (updatedMatches.length < 5) {
        loadPotentialMatches();
      }

      // Log the action
      await _databaseService.logUserAction(
        user.uid,
        'swipe',
        {
          'direction': direction == SwipeDirection.right ? 'right' : 'left',
          'targetUserId': targetUserId,
        },
      );
    } catch (e) {
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
}
