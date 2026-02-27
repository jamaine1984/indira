import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:indira_love/core/services/logger_service.dart';

class IcebreakerService {
  static final IcebreakerService _instance = IcebreakerService._();
  factory IcebreakerService() => _instance;
  IcebreakerService._();

  final _random = Random();

  /// Generate personalized icebreakers based on shared interests/profile data
  List<String> generateIcebreakers({
    required Map<String, dynamic> currentUser,
    required Map<String, dynamic> otherUser,
  }) {
    final icebreakers = <String>[];
    final otherName = otherUser['displayName'] ?? 'them';
    final firstName = otherName.toString().split(' ').first;

    // 1. Interest-based icebreakers
    final myInterests = List<String>.from(currentUser['interests'] ?? []);
    final theirInterests = List<String>.from(otherUser['interests'] ?? []);
    final shared = myInterests.where((i) => theirInterests.contains(i)).toList();

    if (shared.isNotEmpty) {
      final interest = shared[_random.nextInt(shared.length)];
      icebreakers.addAll([
        "I noticed we both love $interest! What's your favorite thing about it?",
        "A fellow $interest fan! We already have great taste in common \u{1F604}",
        "So you're into $interest too? Tell me your best $interest story!",
      ]);
    }

    // 2. Cultural preference based
    final myCultural = currentUser['culturalPreferences'] as Map<String, dynamic>? ?? {};
    final theirCultural = otherUser['culturalPreferences'] as Map<String, dynamic>? ?? {};

    if (myCultural['religion'] != null && myCultural['religion'] == theirCultural['religion']) {
      icebreakers.add("It's nice to connect with someone who shares the same faith. What traditions mean the most to you?");
    }

    if (myCultural['motherTongue'] != null && myCultural['motherTongue'] == theirCultural['motherTongue']) {
      final lang = myCultural['motherTongue'];
      icebreakers.add("So you speak $lang too! Do you prefer chatting in $lang or English? \u{1F60A}");
    }

    if (theirCultural['dietType'] != null) {
      final diet = theirCultural['dietType'];
      if (diet == 'Vegetarian' || diet == 'Vegan') {
        icebreakers.add("Fellow $diet here! What's your go-to restaurant recommendation?");
      }
    }

    if (theirCultural['state'] != null && myCultural['state'] == theirCultural['state']) {
      icebreakers.add("We're both from ${theirCultural['state']}! What do you miss most about home?");
    }

    // 3. Bio-based
    final bio = otherUser['bio']?.toString() ?? '';
    if (bio.length > 20) {
      icebreakers.add("Hey $firstName! I loved reading your bio. What inspired you to write that?");
    }

    // 4. General South Asian themed icebreakers
    icebreakers.addAll(_generalIcebreakers(firstName));

    // Shuffle and return top 5
    icebreakers.shuffle(_random);
    return icebreakers.take(5).toList();
  }

  /// General culturally relevant icebreakers
  List<String> _generalIcebreakers(String name) {
    return [
      "Hey $name! If you could have dinner with any Bollywood star, who would it be?",
      "Chai or coffee? This might determine our entire future \u{2615}",
      "What's your family's signature dish that nobody else can make as well?",
      "Mountains or beaches for our first weekend getaway? \u{1F3D4}\u{FE0F}",
      "If our families met tomorrow, what's the first thing your mom would ask me? \u{1F602}",
      "What's the one thing about your culture you'd never want to change?",
      "Biryani or butter chicken? Choose wisely, this is a dealbreaker \u{1F35B}",
      "What's your go-to song when you need to feel good?",
      "If we were in a Bollywood movie, what genre would it be?",
      "What's your idea of a perfect Sunday?",
      "Do you believe in astrology, or do you just read your horoscope for fun? \u{2728}",
      "What's the best trip you've ever taken?",
      "If you could learn any language, which would it be and why?",
      "What's your family's most unique tradition?",
      "Morning person or night owl? I need to know for future planning \u{1F60F}",
      "What's one thing on your bucket list you haven't done yet?",
      "Would you rather explore street food in Mumbai or fine dining in Delhi?",
      "What's the most adventurous thing you've ever done?",
      "Tell me about a book or movie that changed your perspective on life",
      "If you had to cook one dish to impress someone, what would it be?",
    ];
  }

  /// Get random icebreakers without profile context (fallback)
  List<String> getRandomIcebreakers({int count = 3}) {
    final all = _generalIcebreakers('there');
    all.shuffle(_random);
    return all.take(count).toList();
  }

  /// Log icebreaker usage for analytics
  Future<void> logIcebreakerUsed(String matchId, String icebreaker) async {
    try {
      await FirebaseFirestore.instance.collection('analytics').add({
        'type': 'icebreaker_used',
        'matchId': matchId,
        'icebreaker': icebreaker,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.error('Error logging icebreaker: $e');
    }
  }
}
