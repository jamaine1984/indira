import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/features/likes/models/like_model.dart';
import 'package:indira_love/features/likes/services/likes_service.dart';

final likesServiceProvider = Provider((ref) => LikesService());

// Stream of likes you sent
final likesSentProvider = StreamProvider<List<LikeModel>>((ref) {
  final user = AuthService().currentUser;
  if (user == null) return Stream.value([]);

  return ref.read(likesServiceProvider).getLikesSent(user.uid);
});

// Stream of likes you received (who liked you)
final likesReceivedProvider = StreamProvider<List<LikeModel>>((ref) {
  final user = AuthService().currentUser;
  if (user == null) return Stream.value([]);

  return ref.read(likesServiceProvider).getLikesReceived(user.uid);
});

// Count of unrevealed likes
final unrevealedLikesCountProvider = FutureProvider<int>((ref) async {
  final user = AuthService().currentUser;
  if (user == null) return 0;

  return ref.read(likesServiceProvider).getUnrevealedLikesCount(user.uid);
});

// Check if user has Gold subscription (ad-free)
final hasGoldSubscriptionProvider = FutureProvider<bool>((ref) async {
  final user = AuthService().currentUser;
  if (user == null) return false;

  return ref.read(likesServiceProvider).canRevealWithoutAds(user.uid);
});
