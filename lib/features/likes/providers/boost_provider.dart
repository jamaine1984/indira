import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:indira_love/core/services/auth_service.dart';
import 'package:indira_love/features/likes/models/boost_model.dart';
import 'package:indira_love/features/likes/services/boost_service.dart';

final boostServiceProvider = Provider((ref) => BoostService());

// Stream of active boost
final activeBoostProvider = StreamProvider<BoostModel?>((ref) {
  final user = AuthService().currentUser;
  if (user == null) return Stream.value(null);

  return ref.read(boostServiceProvider).watchActiveBoost(user.uid);
});

// Check if user has Gold subscription
final hasGoldForBoostProvider = FutureProvider<bool>((ref) async {
  final user = AuthService().currentUser;
  if (user == null) return false;

  return ref.read(boostServiceProvider).hasGoldSubscription(user.uid);
});

// Get boost ad requirements
final boostAdRequirementsProvider = Provider<Map<int, int>>((ref) {
  return ref.read(boostServiceProvider).getBoostAdRequirements();
});
