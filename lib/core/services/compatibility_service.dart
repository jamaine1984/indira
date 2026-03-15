import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Real compatibility score calculation based on cultural preferences,
/// interests, vedic astrology, and lifestyle factors.
class CompatibilityService {
  static final CompatibilityService _instance = CompatibilityService._internal();
  factory CompatibilityService() => _instance;
  CompatibilityService._internal();

  /// Calculate compatibility between two users (0-100).
  double calculateCompatibility(
    Map<String, dynamic> user1,
    Map<String, dynamic> user2,
  ) {
    double totalScore = 0;
    double totalWeight = 0;

    // 1. Interest Overlap (weight: 25)
    final score1 = _interestScore(user1, user2);
    totalScore += score1 * 25;
    totalWeight += 25;

    // 2. Cultural Preferences Match (weight: 30)
    final score2 = _culturalScore(user1, user2);
    totalScore += score2 * 30;
    totalWeight += 30;

    // 3. Vedic Astrology Compatibility (weight: 20)
    final score3 = _vedicScore(user1, user2);
    totalScore += score3 * 20;
    totalWeight += 20;

    // 4. Age Compatibility (weight: 10)
    final score4 = _ageScore(user1, user2);
    totalScore += score4 * 10;
    totalWeight += 10;

    // 5. Location Proximity (weight: 10)
    final score5 = _locationScore(user1, user2);
    totalScore += score5 * 10;
    totalWeight += 10;

    // 6. Education Level Match (weight: 5)
    final score6 = _educationScore(user1, user2);
    totalScore += score6 * 5;
    totalWeight += 5;

    final rawScore = totalWeight > 0 ? (totalScore / totalWeight) * 100 : 50;

    // Clamp between 20-99 (never show 0% or 100%)
    return rawScore.clamp(20.0, 99.0);
  }

  /// Interest overlap score (0.0 - 1.0)
  double _interestScore(Map<String, dynamic> u1, Map<String, dynamic> u2) {
    final interests1 = (u1['interests'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toSet() ?? {};
    final interests2 = (u2['interests'] as List<dynamic>?)?.map((e) => e.toString().toLowerCase()).toSet() ?? {};

    if (interests1.isEmpty || interests2.isEmpty) return 0.5; // Neutral if no data

    final overlap = interests1.intersection(interests2).length;
    final total = interests1.union(interests2).length;

    return total > 0 ? overlap / total : 0.5;
  }

  /// Cultural preferences compatibility (0.0 - 1.0)
  double _culturalScore(Map<String, dynamic> u1, Map<String, dynamic> u2) {
    final c1 = u1['culturalPreferences'] as Map<String, dynamic>? ?? {};
    final c2 = u2['culturalPreferences'] as Map<String, dynamic>? ?? {};

    if (c1.isEmpty || c2.isEmpty) return 0.5;

    double matches = 0;
    double total = 0;

    // Religion match (high weight)
    if (c1['religion'] != null && c2['religion'] != null) {
      total += 3;
      if (c1['religion'] == c2['religion']) matches += 3;
    }

    // Diet type match
    if (c1['dietType'] != null && c2['dietType'] != null) {
      total += 2;
      if (c1['dietType'] == c2['dietType']) matches += 2;
    }

    // Mother tongue match
    if (c1['motherTongue'] != null && c2['motherTongue'] != null) {
      total += 2;
      if (c1['motherTongue'] == c2['motherTongue']) matches += 2;
    }

    // Marriage timeline alignment
    if (c1['marriageTimeline'] != null && c2['marriageTimeline'] != null) {
      total += 2;
      if (c1['marriageTimeline'] == c2['marriageTimeline']) matches += 2;
      else matches += 0.5; // Partial credit
    }

    // Family values
    if (c1['familyValues'] != null && c2['familyValues'] != null) {
      total += 1;
      if (c1['familyValues'] == c2['familyValues']) matches += 1;
    }

    return total > 0 ? matches / total : 0.5;
  }

  /// Vedic astrology compatibility (simplified Gun Milan) (0.0 - 1.0)
  double _vedicScore(Map<String, dynamic> u1, Map<String, dynamic> u2) {
    final c1 = u1['culturalPreferences'] as Map<String, dynamic>? ?? {};
    final c2 = u2['culturalPreferences'] as Map<String, dynamic>? ?? {};

    final nakshatra1 = c1['nakshatra'] as String?;
    final nakshatra2 = c2['nakshatra'] as String?;
    final rashi1 = c1['rashi'] as String?;
    final rashi2 = c2['rashi'] as String?;
    final manglik1 = c1['manglik'] as bool?;
    final manglik2 = c2['manglik'] as bool?;

    if (nakshatra1 == null && rashi1 == null) return 0.5; // No data

    double score = 0.5; // Base

    // Manglik compatibility (important in Indian marriage)
    if (manglik1 != null && manglik2 != null) {
      if (manglik1 == manglik2) {
        score += 0.2; // Both manglik or both non-manglik is good
      } else {
        score -= 0.1; // Mismatch is a concern for some
      }
    }

    // Rashi compatibility (simplified - same element rashis are more compatible)
    if (rashi1 != null && rashi2 != null) {
      final element1 = _rashiElement(rashi1);
      final element2 = _rashiElement(rashi2);
      if (element1 == element2) {
        score += 0.15; // Same element
      } else if (_areCompatibleElements(element1, element2)) {
        score += 0.1; // Compatible elements
      }
    }

    // Nakshatra compatibility (simplified)
    if (nakshatra1 != null && nakshatra2 != null) {
      if (nakshatra1 == nakshatra2) {
        score += 0.1; // Same nakshatra
      }
    }

    return score.clamp(0.0, 1.0);
  }

  String _rashiElement(String rashi) {
    const fireRashis = ['Aries', 'Leo', 'Sagittarius', 'Mesha', 'Simha', 'Dhanu'];
    const earthRashis = ['Taurus', 'Virgo', 'Capricorn', 'Vrishabha', 'Kanya', 'Makara'];
    const airRashis = ['Gemini', 'Libra', 'Aquarius', 'Mithuna', 'Tula', 'Kumbha'];
    const waterRashis = ['Cancer', 'Scorpio', 'Pisces', 'Karka', 'Vrishchika', 'Meena'];

    if (fireRashis.contains(rashi)) return 'fire';
    if (earthRashis.contains(rashi)) return 'earth';
    if (airRashis.contains(rashi)) return 'air';
    if (waterRashis.contains(rashi)) return 'water';
    return 'unknown';
  }

  bool _areCompatibleElements(String e1, String e2) {
    // Fire + Air, Earth + Water are compatible
    return (e1 == 'fire' && e2 == 'air') ||
        (e1 == 'air' && e2 == 'fire') ||
        (e1 == 'earth' && e2 == 'water') ||
        (e1 == 'water' && e2 == 'earth');
  }

  /// Age compatibility (0.0 - 1.0)
  double _ageScore(Map<String, dynamic> u1, Map<String, dynamic> u2) {
    final age1 = u1['age'] as int?;
    final age2 = u2['age'] as int?;

    if (age1 == null || age2 == null) return 0.5;

    final diff = (age1 - age2).abs();
    if (diff <= 2) return 1.0;
    if (diff <= 5) return 0.8;
    if (diff <= 10) return 0.6;
    if (diff <= 15) return 0.3;
    return 0.1;
  }

  /// Location proximity (0.0 - 1.0)
  double _locationScore(Map<String, dynamic> u1, Map<String, dynamic> u2) {
    final country1 = u1['country'] as String? ?? '';
    final country2 = u2['country'] as String? ?? '';
    final city1 = u1['city'] as String? ?? '';
    final city2 = u2['city'] as String? ?? '';

    if (city1.isNotEmpty && city2.isNotEmpty && city1 == city2) return 1.0;
    if (country1.isNotEmpty && country2.isNotEmpty && country1 == country2) return 0.7;

    // Check state match from cultural preferences
    final state1 = (u1['culturalPreferences'] as Map<String, dynamic>?)?['state'] as String? ?? '';
    final state2 = (u2['culturalPreferences'] as Map<String, dynamic>?)?['state'] as String? ?? '';
    if (state1.isNotEmpty && state2.isNotEmpty && state1 == state2) return 0.8;

    return 0.3;
  }

  /// Education level compatibility (0.0 - 1.0)
  double _educationScore(Map<String, dynamic> u1, Map<String, dynamic> u2) {
    final edu1 = u1['education'] as String? ?? '';
    final edu2 = u2['education'] as String? ?? '';

    if (edu1.isEmpty || edu2.isEmpty) return 0.5;
    if (edu1 == edu2) return 1.0;

    final levels = ['None', 'High School', "Associate's", "Bachelor's", "Master's", 'PhD', 'Professional'];
    final idx1 = levels.indexOf(edu1);
    final idx2 = levels.indexOf(edu2);

    if (idx1 == -1 || idx2 == -1) return 0.5;

    final diff = (idx1 - idx2).abs();
    if (diff <= 1) return 0.8;
    if (diff <= 2) return 0.6;
    return 0.4;
  }

  /// Calculate and store compatibility score between two users
  Future<double> getOrCalculateCompatibility(
    String userId1,
    String userId2,
  ) async {
    try {
      final docs = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(userId1).get(),
        FirebaseFirestore.instance.collection('users').doc(userId2).get(),
      ]);

      if (!docs[0].exists || !docs[1].exists) return 50.0;

      final user1Data = docs[0].data()!;
      final user2Data = docs[1].data()!;

      return calculateCompatibility(user1Data, user2Data);
    } catch (e) {
      logger.error('Error calculating compatibility: $e');
      return 50.0;
    }
  }
}

final compatibilityService = CompatibilityService();
