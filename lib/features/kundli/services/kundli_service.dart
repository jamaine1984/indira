import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Kundli Compatibility Service
/// Implements Gun Milan (36-point) scoring system for Hindu horoscope matching.
class KundliService {
  static final KundliService _instance = KundliService._();
  factory KundliService() => _instance;
  KundliService._();

  final _firestore = FirebaseFirestore.instance;

  // 27 Nakshatras
  static const List<String> nakshatras = [
    'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira',
    'Ardra', 'Punarvasu', 'Pushya', 'Ashlesha', 'Magha',
    'Purva Phalguni', 'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati',
    'Vishakha', 'Anuradha', 'Jyeshtha', 'Mula', 'Purva Ashadha',
    'Uttara Ashadha', 'Shravana', 'Dhanishta', 'Shatabhisha',
    'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati',
  ];

  // 12 Rashis (Moon Signs)
  static const List<String> rashis = [
    'Aries (Mesh)', 'Taurus (Vrishabh)', 'Gemini (Mithun)',
    'Cancer (Kark)', 'Leo (Simha)', 'Virgo (Kanya)',
    'Libra (Tula)', 'Scorpio (Vrishchik)', 'Sagittarius (Dhanu)',
    'Capricorn (Makar)', 'Aquarius (Kumbh)', 'Pisces (Meen)',
  ];

  // Nakshatra to Rashi mapping (which Rashi each Nakshatra belongs to)
  static int _nakshatraToRashi(int nakshatraIdx) {
    // Each Rashi covers 2.25 nakshatras (27/12)
    return ((nakshatraIdx * 4) ~/ 9) % 12;
  }

  // Nakshatra to Gana (Deva=0, Manushya=1, Rakshasa=2)
  static const List<int> _nakshatraGana = [
    0, 1, 2, 0, 0, 1, 0, 0, 2, // Ashwini-Ashlesha
    2, 1, 0, 0, 2, 0, 2, 0, 2, // Magha-Jyeshtha
    2, 1, 0, 0, 2, 2, 1, 0, 0, // Mula-Revati
  ];

  // Nakshatra to Yoni (animal pairing)
  static const List<int> _nakshatraYoni = [
    0, 1, 2, 3, 3, 4, 5, 2, 5, // Horse, Elephant, Sheep, Serpent...
    6, 6, 7, 7, 8, 7, 8, 9, 9,
    4, 10, 10, 10, 0, 0, 1, 7, 1,
  ];

  /// Calculate full Gun Milan score (simplified 36-point system)
  /// Factors: Varna(1), Vashya(2), Tara(3), Yoni(4), Graha Maitri(5), Gana(6), Bhakut(7), Nadi(8)
  Map<String, dynamic> calculateCompatibility({
    required String nakshatra1,
    required String nakshatra2,
    String? rashi1,
    String? rashi2,
    bool? manglik1,
    bool? manglik2,
  }) {
    final idx1 = nakshatras.indexOf(nakshatra1);
    final idx2 = nakshatras.indexOf(nakshatra2);

    if (idx1 == -1 || idx2 == -1) {
      return {'totalScore': 0, 'maxScore': 36, 'percentage': 0, 'details': {}};
    }

    final r1 = rashi1 != null ? rashis.indexOf(rashi1) : _nakshatraToRashi(idx1);
    final r2 = rashi2 != null ? rashis.indexOf(rashi2) : _nakshatraToRashi(idx2);

    double total = 0;
    final details = <String, Map<String, dynamic>>{};

    // 1. Varna (1 point) - Spiritual compatibility
    final varna1 = r1 % 4; // Brahmin, Kshatriya, Vaishya, Shudra
    final varna2 = r2 % 4;
    final varnaScore = varna1 >= varna2 ? 1.0 : 0.0;
    details['Varna'] = {'score': varnaScore, 'max': 1, 'desc': 'Spiritual compatibility'};
    total += varnaScore;

    // 2. Vashya (2 points) - Dominance/attraction
    final vashyaScore = (r1 - r2).abs() <= 1 || (r1 - r2).abs() >= 11 ? 2.0 : ((r1 - r2).abs() <= 3 ? 1.0 : 0.0);
    details['Vashya'] = {'score': vashyaScore, 'max': 2, 'desc': 'Mutual attraction'};
    total += vashyaScore;

    // 3. Tara (3 points) - Birth star compatibility
    final taraDiff = ((idx2 - idx1) % 27 + 27) % 27;
    final taraGroup = taraDiff % 9;
    final taraScore = [0, 3, 1, 1.5, 3, 0, 1.5, 3, 0][taraGroup].toDouble();
    details['Tara'] = {'score': taraScore, 'max': 3, 'desc': 'Destiny & health'};
    total += taraScore;

    // 4. Yoni (4 points) - Physical compatibility
    final y1 = _nakshatraYoni[idx1];
    final y2 = _nakshatraYoni[idx2];
    final yoniScore = y1 == y2 ? 4.0 : ((y1 - y2).abs() <= 2 ? 2.0 : 0.0);
    details['Yoni'] = {'score': yoniScore, 'max': 4, 'desc': 'Physical compatibility'};
    total += yoniScore;

    // 5. Graha Maitri (5 points) - Mental compatibility
    final maitriDiff = (r1 - r2).abs();
    final maitriScore = maitriDiff == 0 ? 5.0 : (maitriDiff <= 2 ? 4.0 : (maitriDiff <= 4 ? 2.0 : 0.0));
    details['Graha Maitri'] = {'score': maitriScore, 'max': 5, 'desc': 'Mental compatibility'};
    total += maitriScore;

    // 6. Gana (6 points) - Temperament
    final g1 = _nakshatraGana[idx1];
    final g2 = _nakshatraGana[idx2];
    final ganaScore = g1 == g2 ? 6.0 : ((g1 - g2).abs() == 1 ? 3.0 : 0.0);
    details['Gana'] = {'score': ganaScore, 'max': 6, 'desc': 'Temperament match'};
    total += ganaScore;

    // 7. Bhakut (7 points) - Love & family
    final bhakutDiff = ((r2 - r1) % 12 + 12) % 12;
    const goodBhakut = {1, 3, 4, 7, 10};
    final bhakutScore = bhakutDiff == 0 ? 7.0 : (goodBhakut.contains(bhakutDiff) ? 7.0 : 0.0);
    details['Bhakut'] = {'score': bhakutScore, 'max': 7, 'desc': 'Love & family harmony'};
    total += bhakutScore;

    // 8. Nadi (8 points) - Health & genes
    final nadi1 = idx1 % 3;
    final nadi2 = idx2 % 3;
    final nadiScore = nadi1 != nadi2 ? 8.0 : 0.0;
    details['Nadi'] = {'score': nadiScore, 'max': 8, 'desc': 'Health & progeny'};
    total += nadiScore;

    // Manglik check
    String manglikNote = '';
    if (manglik1 != null && manglik2 != null) {
      if (manglik1 == manglik2) {
        manglikNote = 'Both ${manglik1 ? "Manglik" : "Non-Manglik"} - Compatible';
      } else {
        manglikNote = 'Manglik mismatch - Consider consulting a pandit';
      }
    }

    final percentage = (total / 36 * 100).round();

    String verdict;
    if (percentage >= 75) {
      verdict = 'Excellent Match';
    } else if (percentage >= 50) {
      verdict = 'Good Match';
    } else if (percentage >= 33) {
      verdict = 'Average Match';
    } else {
      verdict = 'Below Average';
    }

    return {
      'totalScore': total,
      'maxScore': 36,
      'percentage': percentage,
      'verdict': verdict,
      'manglikNote': manglikNote,
      'details': details,
    };
  }

  /// Get user's astrology data
  Future<Map<String, dynamic>?> getUserAstroData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) return null;
      final cultural = data['culturalPreferences'] as Map<String, dynamic>?;
      if (cultural == null) return null;
      return {
        'nakshatra': cultural['nakshatra'],
        'rashi': cultural['rashi'],
        'manglik': cultural['manglik'],
      };
    } catch (e) {
      logger.error('Error getting astro data: $e');
      return null;
    }
  }
}
