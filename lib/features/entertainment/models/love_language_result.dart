class LoveLanguageResult {
  final String primaryLanguage;
  final String emoji;
  final String shortName;
  final String description;
  final Map<String, int> scores;

  const LoveLanguageResult({
    required this.primaryLanguage,
    required this.emoji,
    required this.shortName,
    required this.description,
    required this.scores,
  });

  Map<String, dynamic> toMap() => {
        'primaryLanguage': primaryLanguage,
        'emoji': emoji,
        'shortName': shortName,
        'description': description,
        'scores': scores,
      };

  factory LoveLanguageResult.fromMap(Map<String, dynamic> map) {
    return LoveLanguageResult(
      primaryLanguage: map['primaryLanguage'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '',
      shortName: map['shortName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      scores: Map<String, int>.from(map['scores'] as Map? ?? {}),
    );
  }

  static const Map<String, Map<String, String>> languageInfo = {
    'wordsOfAffirmation': {
      'name': 'Words of Affirmation',
      'emoji': '\u{1F4AC}',
      'short': 'Words',
      'description':
          'You feel most loved when your partner expresses their feelings through compliments, encouragement, and verbal appreciation.',
    },
    'actsOfService': {
      'name': 'Acts of Service',
      'emoji': '\u{1F91D}',
      'short': 'Service',
      'description':
          'You feel most loved when your partner shows care through helpful actions and going out of their way to make your life easier.',
    },
    'receivingGifts': {
      'name': 'Receiving Gifts',
      'emoji': '\u{1F381}',
      'short': 'Gifts',
      'description':
          'You feel most loved when your partner gives thoughtful gifts that show they were thinking of you.',
    },
    'qualityTime': {
      'name': 'Quality Time',
      'emoji': '\u{1F495}',
      'short': 'Time',
      'description':
          'You feel most loved when your partner gives you their undivided attention and spends meaningful time together.',
    },
    'physicalTouch': {
      'name': 'Physical Touch',
      'emoji': '\u{1FAF6}',
      'short': 'Touch',
      'description':
          'You feel most loved through physical expressions of love like hugs, holding hands, and closeness.',
    },
  };
}
