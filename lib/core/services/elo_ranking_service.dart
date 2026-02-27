import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';

class EloRankingService {
  static final EloRankingService _instance = EloRankingService._();
  factory EloRankingService() => _instance;
  EloRankingService._();

  final _firestore = FirebaseFirestore.instance;

  static const int _defaultElo = 1000;
  static const int _kFactorNew = 32; // New profiles (<50 swipes)
  static const int _kFactorEstablished = 16; // Established profiles

  /// Update ELO score when a profile receives a swipe
  /// rightSwipe = true means the profile was liked (ELO goes up)
  /// rightSwipe = false means the profile was passed (ELO goes down)
  Future<void> updateElo(String targetUserId, bool rightSwipe) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(targetUserId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return;

        final data = userDoc.data()!;
        final currentElo = (data['eloScore'] as int?) ?? _defaultElo;
        final totalSwipes =
            (data['totalSwipesReceived'] as int?) ?? 0;

        // Determine K-factor based on profile maturity
        final kFactor = totalSwipes < 50 ? _kFactorNew : _kFactorEstablished;

        // Expected score (against average profile at 1000)
        final expected = 1.0 / (1.0 + _pow10((1000 - currentElo) / 400.0));

        // Actual score: 1 for right swipe, 0 for left
        final actual = rightSwipe ? 1.0 : 0.0;

        // ELO update
        final newElo = (currentElo + kFactor * (actual - expected)).round();

        // Clamp ELO to reasonable range (200-2000)
        final clampedElo = newElo.clamp(200, 2000);

        transaction.update(userRef, {
          'eloScore': clampedElo,
          'totalSwipesReceived': totalSwipes + 1,
        });
      });
    } catch (e) {
      logger.error('Failed to update ELO for $targetUserId', error: e);
    }
  }

  /// Get ELO multiplier for scoring (elo/1000, clamped 0.8-1.3)
  double getEloMultiplier(int? eloScore) {
    final elo = eloScore ?? _defaultElo;
    final multiplier = elo / 1000.0;
    return multiplier.clamp(0.8, 1.3);
  }

  /// Get cold start boost multiplier
  /// First 48h = 1.2x, first week = 1.1x, after = 1.0x
  double getColdStartMultiplier(dynamic createdAt) {
    if (createdAt == null) return 1.0;

    DateTime createdDate;
    if (createdAt is Timestamp) {
      createdDate = createdAt.toDate();
    } else if (createdAt is DateTime) {
      createdDate = createdAt;
    } else {
      return 1.0;
    }

    final age = DateTime.now().difference(createdDate);

    if (age.inHours < 48) return 1.2;
    if (age.inDays < 7) return 1.1;
    return 1.0;
  }

  /// Initialize ELO for a new user
  Future<void> initializeElo(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'eloScore': _defaultElo,
        'totalSwipesReceived': 0,
      });
    } catch (e) {
      logger.error('Failed to initialize ELO for $userId', error: e);
    }
  }

  double _pow10(double exponent) {
    // 10^x approximation
    double result = 1.0;
    double base = 10.0;
    double exp = exponent;

    if (exp < 0) {
      base = 0.1;
      exp = -exp;
    }

    int intPart = exp.floor();
    double fracPart = exp - intPart;

    // Integer power
    for (int i = 0; i < intPart; i++) {
      result *= base;
    }

    // Fractional power approximation using ln(10) * frac
    // e^(ln(10) * frac) ≈ 1 + ln(10)*frac + (ln(10)*frac)^2/2
    if (fracPart > 0) {
      final lnTerm = 2.302585 * fracPart;
      result *= (1 + lnTerm + lnTerm * lnTerm / 2 + lnTerm * lnTerm * lnTerm / 6);
    }

    return result;
  }
}
