import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';

class PreferenceLearningService {
  static final PreferenceLearningService _instance =
      PreferenceLearningService._();
  factory PreferenceLearningService() => _instance;
  PreferenceLearningService._();

  final _firestore = FirebaseFirestore.instance;

  // In-memory cache
  Map<String, dynamic>? _cachedWeights;
  DateTime? _cacheTime;
  String? _cachedUserId;

  /// Learn preference weights by analyzing last 200 swipe decisions
  Future<Map<String, dynamic>> learnPreferenceWeights(String userId) async {
    // Check in-memory cache (24h TTL)
    if (_cachedUserId == userId &&
        _cachedWeights != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!).inHours < 24) {
      return _cachedWeights!;
    }

    // Check Firestore cache
    try {
      final cached = await _firestore
          .collection('users')
          .doc(userId)
          .collection('aiPreferences')
          .doc('weights')
          .get();

      if (cached.exists) {
        final data = cached.data()!;
        final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
        if (updatedAt != null &&
            DateTime.now().difference(updatedAt).inHours < 24) {
          _cachedWeights = Map<String, dynamic>.from(data['weights'] ?? {});
          _cacheTime = updatedAt;
          _cachedUserId = userId;
          return _cachedWeights!;
        }
      }
    } catch (e) {
      logger.error('Failed to read cached preferences', error: e);
    }

    // Analyze swipe history
    return _computeWeights(userId);
  }

  Future<Map<String, dynamic>> _computeWeights(String userId) async {
    try {
      // Fetch last 200 swipes
      final swipes = await _firestore
          .collection('swipes')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      if (swipes.docs.length < 10) {
        // Not enough data for meaningful learning, return defaults
        final defaults = _defaultWeights();
        _cachedWeights = defaults;
        _cacheTime = DateTime.now();
        _cachedUserId = userId;
        return defaults;
      }

      // Separate right (liked) and left (passed) swipes
      final liked = <Map<String, dynamic>>[];
      final passed = <Map<String, dynamic>>[];

      for (final doc in swipes.docs) {
        final data = doc.data();
        if (data['direction'] == 'right') {
          liked.add(data);
        } else {
          passed.add(data);
        }
      }

      // Fetch profiles of liked users to analyze patterns
      final likedUserIds = liked
          .map((s) => s['targetId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .take(50)
          .toList();

      final likedProfiles = <Map<String, dynamic>>[];
      // Batch fetch in groups of 10 (Firestore limitation)
      for (var i = 0; i < likedUserIds.length; i += 10) {
        final batch = likedUserIds.sublist(
          i,
          i + 10 > likedUserIds.length ? likedUserIds.length : i + 10,
        );
        if (batch.isEmpty) continue;

        final profiles = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        likedProfiles.addAll(profiles.docs.map((d) => d.data()));
      }

      // Analyze age preference patterns
      final ageWeight = _analyzeAgePattern(likedProfiles);

      // Analyze interest overlap patterns
      final interestWeight = _analyzeInterestPattern(likedProfiles);

      // Analyze cultural patterns (religion, diet, language)
      final culturalWeight = _analyzeCulturalPattern(likedProfiles);

      // Analyze distance tolerance
      final distanceWeight = _analyzeDistancePattern(liked);

      // Normalize weights to sum to 100
      final total = ageWeight + interestWeight + culturalWeight + distanceWeight;
      final normalizer = total > 0 ? 100.0 / total : 1.0;

      final weights = {
        'age': (ageWeight * normalizer).round(),
        'interests': (interestWeight * normalizer).round(),
        'cultural': (culturalWeight * normalizer).round(),
        'distance': (distanceWeight * normalizer).round(),
        'swipeCount': swipes.docs.length,
        'likeRate': liked.length / swipes.docs.length,
      };

      // Cache results
      _cachedWeights = weights;
      _cacheTime = DateTime.now();
      _cachedUserId = userId;

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('aiPreferences')
          .doc('weights')
          .set({
        'weights': weights,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return weights;
    } catch (e) {
      logger.error('Failed to compute preference weights', error: e);
      return _defaultWeights();
    }
  }

  double _analyzeAgePattern(List<Map<String, dynamic>> profiles) {
    if (profiles.isEmpty) return 15.0;

    final ages = profiles
        .map((p) => p['age'] as int?)
        .where((a) => a != null)
        .cast<int>()
        .toList();

    if (ages.isEmpty) return 15.0;

    // Calculate standard deviation - lower = strong preference
    final mean = ages.reduce((a, b) => a + b) / ages.length;
    final variance =
        ages.map((a) => (a - mean) * (a - mean)).reduce((a, b) => a + b) /
            ages.length;
    final stdDev = variance > 0 ? _sqrt(variance) : 0.0;

    // Low std dev = strong age preference = higher weight
    if (stdDev < 2) return 25.0;
    if (stdDev < 4) return 20.0;
    if (stdDev < 6) return 15.0;
    return 10.0;
  }

  double _analyzeInterestPattern(List<Map<String, dynamic>> profiles) {
    if (profiles.isEmpty) return 30.0;

    // Count how often specific interests appear in liked profiles
    final interestCounts = <String, int>{};
    for (final profile in profiles) {
      final interests = (profile['interests'] as List<dynamic>?) ?? [];
      for (final interest in interests) {
        final key = interest.toString();
        interestCounts[key] = (interestCounts[key] ?? 0) + 1;
      }
    }

    if (interestCounts.isEmpty) return 25.0;

    // If certain interests dominate, it's a strong signal
    final maxCount = interestCounts.values.reduce((a, b) => a > b ? a : b);
    final dominanceRatio = maxCount / profiles.length;

    if (dominanceRatio > 0.7) return 40.0;
    if (dominanceRatio > 0.5) return 35.0;
    return 25.0;
  }

  double _analyzeCulturalPattern(List<Map<String, dynamic>> profiles) {
    if (profiles.isEmpty) return 25.0;

    // Check religion consistency in liked profiles
    final religions = profiles
        .map((p) => p['religion']?.toString())
        .where((r) => r != null && r.isNotEmpty)
        .toList();

    if (religions.isEmpty) return 20.0;

    final religionCounts = <String, int>{};
    for (final r in religions) {
      religionCounts[r!] = (religionCounts[r] ?? 0) + 1;
    }

    final maxReligionCount =
        religionCounts.values.reduce((a, b) => a > b ? a : b);
    final religionConsistency = maxReligionCount / religions.length;

    // High consistency = strong cultural preference
    if (religionConsistency > 0.8) return 35.0;
    if (religionConsistency > 0.6) return 30.0;
    return 20.0;
  }

  double _analyzeDistancePattern(List<Map<String, dynamic>> swipes) {
    // Analyze if user tends to like nearby or far profiles
    // For now, return moderate weight
    return 20.0;
  }

  Map<String, dynamic> _defaultWeights() {
    return {
      'age': 15,
      'interests': 35,
      'cultural': 30,
      'distance': 20,
      'swipeCount': 0,
      'likeRate': 0.0,
    };
  }

  /// Get AI-adjusted score blending base algorithm + learned weights
  double getAIAdjustedScore({
    required double baseScore,
    required Map<String, dynamic> learnedWeights,
    required Map<String, dynamic> candidateProfile,
    required Map<String, dynamic> currentUserProfile,
  }) {
    // Blend: 60% base algorithm + 40% learned weights
    const baseRatio = 0.6;
    const learnedRatio = 0.4;

    double learnedScore = 0;

    // Age component
    final ageWeight = (learnedWeights['age'] as int? ?? 15) / 100;
    final ageDiff = ((candidateProfile['age'] as int? ?? 25) -
            (currentUserProfile['age'] as int? ?? 25))
        .abs();
    final ageScore = ageDiff <= 2
        ? 1.0
        : ageDiff <= 5
            ? 0.8
            : ageDiff <= 10
                ? 0.5
                : 0.2;
    learnedScore += ageScore * ageWeight * 100;

    // Interest component
    final interestWeight =
        (learnedWeights['interests'] as int? ?? 35) / 100;
    final userInterests =
        Set<String>.from((currentUserProfile['interests'] as List?) ?? []);
    final candidateInterests =
        Set<String>.from((candidateProfile['interests'] as List?) ?? []);
    final interestOverlap = userInterests.isEmpty || candidateInterests.isEmpty
        ? 0.0
        : userInterests.intersection(candidateInterests).length /
            userInterests.union(candidateInterests).length;
    learnedScore += interestOverlap * interestWeight * 100;

    // Cultural component
    final culturalWeight =
        (learnedWeights['cultural'] as int? ?? 30) / 100;
    double culturalScore = 0;
    if (candidateProfile['religion'] == currentUserProfile['religion'] &&
        currentUserProfile['religion'] != null) {
      culturalScore += 0.5;
    }
    if (candidateProfile['diet'] == currentUserProfile['diet'] &&
        currentUserProfile['diet'] != null) {
      culturalScore += 0.3;
    }
    if (candidateProfile['motherTongue'] ==
            currentUserProfile['motherTongue'] &&
        currentUserProfile['motherTongue'] != null) {
      culturalScore += 0.2;
    }
    learnedScore += culturalScore * culturalWeight * 100;

    // Distance component - uses base score's distance component
    final distanceWeight =
        (learnedWeights['distance'] as int? ?? 20) / 100;
    learnedScore += baseScore * distanceWeight;

    return (baseScore * baseRatio) + (learnedScore * learnedRatio);
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    double x = value;
    for (int i = 0; i < 20; i++) {
      x = (x + value / x) / 2;
    }
    return x;
  }
}
