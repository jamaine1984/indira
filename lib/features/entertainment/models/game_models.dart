import 'package:cloud_firestore/cloud_firestore.dart';

class TriviaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category; // 'bollywood' or 'cricket'

  const TriviaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
  });
}

class ThisOrThatPair {
  final String id;
  final String optionA;
  final String optionB;
  final String emojiA;
  final String emojiB;

  const ThisOrThatPair({
    required this.id,
    required this.optionA,
    required this.optionB,
    required this.emojiA,
    required this.emojiB,
  });
}

class WouldYouRatherQuestion {
  final String optionA;
  final String optionB;

  const WouldYouRatherQuestion({
    required this.optionA,
    required this.optionB,
  });
}

class CompatibilityQuestion {
  final String question;
  final List<String> options;

  const CompatibilityQuestion({
    required this.question,
    required this.options,
  });
}

class GameSession {
  final String id;
  final String gameType; // 'would_you_rather' or 'compatibility'
  final String createdBy;
  final String opponent;
  final String status; // 'pending', 'active', 'completed'
  final List<int> questionIndices;
  final Map<String, List<int>> answers;
  final Map<String, dynamic>? result;
  final DateTime createdAt;

  const GameSession({
    required this.id,
    required this.gameType,
    required this.createdBy,
    required this.opponent,
    required this.status,
    required this.questionIndices,
    required this.answers,
    this.result,
    required this.createdAt,
  });

  factory GameSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameSession(
      id: doc.id,
      gameType: data['gameType'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      opponent: data['opponent'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      questionIndices: List<int>.from(data['questionIndices'] as List? ?? []),
      answers: (data['answers'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, List<int>.from(value as List? ?? [])),
      ),
      result: data['result'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'gameType': gameType,
        'createdBy': createdBy,
        'opponent': opponent,
        'status': status,
        'questionIndices': questionIndices,
        'answers': answers,
        'result': result,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
