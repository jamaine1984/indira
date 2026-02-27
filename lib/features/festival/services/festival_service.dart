import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

class FestivalService {
  static final FestivalService _instance = FestivalService._();
  factory FestivalService() => _instance;
  FestivalService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Get upcoming and active festivals
  static List<Map<String, dynamic>> getFestivals() {
    final now = DateTime.now();
    return _allFestivals.where((f) {
      final start = f['startDate'] as DateTime;
      final end = f['endDate'] as DateTime;
      // Show festivals that are upcoming (within 30 days) or currently active
      return end.isAfter(now) && start.isBefore(now.add(const Duration(days: 30)));
    }).toList();
  }

  /// Get all festivals for the year
  static List<Map<String, dynamic>> getAllFestivals() {
    return _allFestivals;
  }

  /// Get currently active festival events
  static Map<String, dynamic>? getActiveFestival() {
    final now = DateTime.now();
    try {
      return _allFestivals.firstWhere((f) {
        final start = f['startDate'] as DateTime;
        final end = f['endDate'] as DateTime;
        return now.isAfter(start) && now.isBefore(end);
      });
    } catch (_) {
      return null;
    }
  }

  /// RSVP to a festival event
  Future<void> rsvpToEvent(String festivalId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('festival_events').doc(festivalId).set({
        'festivalId': festivalId,
        'rsvps': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      logger.info('RSVP to festival: $festivalId');
    } catch (e) {
      logger.error('Error RSVPing to festival: $e');
    }
  }

  /// Get RSVP count for a festival
  Future<int> getRsvpCount(String festivalId) async {
    try {
      final doc = await _firestore.collection('festival_events').doc(festivalId).get();
      if (!doc.exists) return 0;
      final rsvps = doc.data()?['rsvps'] as List<dynamic>? ?? [];
      return rsvps.length;
    } catch (e) {
      return 0;
    }
  }

  /// Check if user has RSVPd
  Future<bool> hasRsvpd(String festivalId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('festival_events').doc(festivalId).get();
      if (!doc.exists) return false;
      final rsvps = doc.data()?['rsvps'] as List<dynamic>? ?? [];
      return rsvps.contains(user.uid);
    } catch (e) {
      return false;
    }
  }

  // All South Asian festivals with dating-themed events
  static final List<Map<String, dynamic>> _allFestivals = [
    {
      'id': 'diwali_2026',
      'name': 'Diwali Spark',
      'emoji': '\u{1F386}',
      'tagline': 'Light up your love life this Diwali',
      'description': 'Send special Diwali greetings, share your diya photos, and find someone whose light matches yours. Special festive profile frames and themed icebreakers.',
      'activities': ['Festive profile frames', 'Diwali greeting cards', 'Rangoli photo challenge', 'Festival match boost'],
      'color': 0xFFFF9800,
      'startDate': DateTime(2026, 10, 17),
      'endDate': DateTime(2026, 10, 25),
      'icon': 'diya',
    },
    {
      'id': 'holi_2026',
      'name': 'Holi Colors of Love',
      'emoji': '\u{1F308}',
      'tagline': 'Add color to your connections',
      'description': 'Celebrate the festival of colors with special colorful profile themes, Holi-themed conversations, and community events.',
      'activities': ['Color splash profile frames', 'Holi photo contest', 'Festive match party', 'Gulal greeting cards'],
      'color': 0xFFE91E63,
      'startDate': DateTime(2026, 3, 10),
      'endDate': DateTime(2026, 3, 17),
      'icon': 'palette',
    },
    {
      'id': 'eid_2026',
      'name': 'Eid Mubarak Connections',
      'emoji': '\u{1F319}',
      'tagline': 'Find your soulmate this Eid',
      'description': 'Celebrate Eid with special themed profiles, send Eid greetings to your matches, and join community iftaar meetup events.',
      'activities': ['Eid greeting cards', 'Crescent moon profile frames', 'Iftaar meetup events', 'Festive conversation starters'],
      'color': 0xFF4CAF50,
      'startDate': DateTime(2026, 3, 20),
      'endDate': DateTime(2026, 3, 27),
      'icon': 'crescent',
    },
    {
      'id': 'navratri_2026',
      'name': 'Navratri Nights',
      'emoji': '\u{1F483}',
      'tagline': 'Dance your way to love',
      'description': 'Nine nights of connection! Share your Garba moves, find dance partners, and celebrate Navratri with themed matching events.',
      'activities': ['Garba partner finder', 'Daily color themes', 'Dance photo challenge', 'Dandiya match events'],
      'color': 0xFF9C27B0,
      'startDate': DateTime(2026, 10, 2),
      'endDate': DateTime(2026, 10, 11),
      'icon': 'dance',
    },
    {
      'id': 'pongal_2026',
      'name': 'Pongal Parivu',
      'emoji': '\u{1F33E}',
      'tagline': 'Harvest a beautiful connection',
      'description': 'Celebrate the Tamil harvest festival with traditional themed profiles and community events celebrating South Indian culture.',
      'activities': ['Traditional kolam designs', 'Pongal recipe sharing', 'Cultural match boost', 'Harvest photo frames'],
      'color': 0xFFFFC107,
      'startDate': DateTime(2026, 1, 14),
      'endDate': DateTime(2026, 1, 18),
      'icon': 'harvest',
    },
    {
      'id': 'valentines_2026',
      'name': 'Valentine\'s Week',
      'emoji': '\u{2764}\u{FE0F}',
      'tagline': 'Seven days of love',
      'description': 'Special Valentine\'s Week events from Rose Day to Valentine\'s Day. Daily themed activities, special gifts, and love-themed games.',
      'activities': ['Rose Day greetings', 'Promise Day cards', 'Valentine\'s match boost', 'Love letter challenge'],
      'color': 0xFFE91E63,
      'startDate': DateTime(2026, 2, 7),
      'endDate': DateTime(2026, 2, 15),
      'icon': 'heart',
    },
    {
      'id': 'lohri_2026',
      'name': 'Lohri Warmth',
      'emoji': '\u{1F525}',
      'tagline': 'Warm hearts, warm connections',
      'description': 'Celebrate Lohri with bonfire-themed profiles and Punjabi cultural events. Find someone who shares your warmth.',
      'activities': ['Bonfire themed cards', 'Bhangra challenge', 'Punjabi match night', 'Winter warmth frames'],
      'color': 0xFFFF5722,
      'startDate': DateTime(2026, 1, 13),
      'endDate': DateTime(2026, 1, 15),
      'icon': 'bonfire',
    },
    {
      'id': 'baisakhi_2026',
      'name': 'Baisakhi Bloom',
      'emoji': '\u{1F33B}',
      'tagline': 'New beginnings, new connections',
      'description': 'Celebrate the Punjabi new year and harvest festival. Fresh starts deserve fresh connections.',
      'activities': ['New year profile refresh', 'Bhangra video challenge', 'Spring match boost', 'Harvest celebration'],
      'color': 0xFFFF9800,
      'startDate': DateTime(2026, 4, 13),
      'endDate': DateTime(2026, 4, 16),
      'icon': 'bloom',
    },
    {
      'id': 'onam_2026',
      'name': 'Onam Onnu',
      'emoji': '\u{1F6F6}',
      'tagline': 'Row together towards love',
      'description': 'Celebrate the Kerala harvest festival. Share your Onam sadhya, pookalam designs, and find your perfect Kerala match.',
      'activities': ['Pookalam photo contest', 'Sadhya recipe sharing', 'Kerala cultural match', 'Boat race challenge'],
      'color': 0xFFFFC107,
      'startDate': DateTime(2026, 9, 5),
      'endDate': DateTime(2026, 9, 12),
      'icon': 'boat',
    },
    {
      'id': 'durga_puja_2026',
      'name': 'Durga Puja Connect',
      'emoji': '\u{1F3E9}',
      'tagline': 'Pandal hopping, heart shopping',
      'description': 'Celebrate Bengal\'s biggest festival. Share your pandal visits, mishti doings, and find your perfect Bengali match.',
      'activities': ['Pandal photo contest', 'Sindoor khela frames', 'Bengali match night', 'Dhunuchi dance challenge'],
      'color': 0xFFF44336,
      'startDate': DateTime(2026, 10, 5),
      'endDate': DateTime(2026, 10, 12),
      'icon': 'temple',
    },
    {
      'id': 'karwa_chauth_2026',
      'name': 'Karwa Chauth Special',
      'emoji': '\u{1F315}',
      'tagline': 'Find your moonlight',
      'description': 'Special event for those looking for a committed relationship. Themed around devotion, love, and lifelong partnership.',
      'activities': ['Moonlit profile frames', 'Devotion letters', 'Commitment match event', 'Mehndi photo sharing'],
      'color': 0xFFE91E63,
      'startDate': DateTime(2026, 10, 25),
      'endDate': DateTime(2026, 10, 28),
      'icon': 'moon',
    },
    {
      'id': 'raksha_bandhan_2026',
      'name': 'Friendship Bonds',
      'emoji': '\u{1F91D}',
      'tagline': 'Celebrate meaningful bonds',
      'description': 'While Raksha Bandhan celebrates sibling bonds, we celebrate all meaningful connections. Find friends and partners who value family.',
      'activities': ['Family values highlight', 'Friendship match event', 'Bond of trust badges', 'Family-first profiles'],
      'color': 0xFF2196F3,
      'startDate': DateTime(2026, 8, 19),
      'endDate': DateTime(2026, 8, 22),
      'icon': 'bond',
    },
  ];
}
