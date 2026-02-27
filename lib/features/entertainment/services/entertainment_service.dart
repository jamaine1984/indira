import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:indira_love/features/entertainment/models/love_language_result.dart';
import 'package:indira_love/features/entertainment/models/game_models.dart';
import 'package:indira_love/features/entertainment/data/would_you_rather_data.dart';
import 'package:indira_love/features/entertainment/data/compatibility_questions.dart';

class EntertainmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Love Language ──

  Future<void> saveLoveLanguageResult(LoveLanguageResult result) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('users').doc(_uid).update({
        'loveLanguage': {
          ...result.toMap(),
          'completedAt': FieldValue.serverTimestamp(),
        },
      });
      logger.info('Love language result saved');
    } catch (e) {
      logger.error('Error saving love language result: $e');
      rethrow;
    }
  }

  Future<LoveLanguageResult?> getLoveLanguageResult(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null || data['loveLanguage'] == null) return null;
      return LoveLanguageResult.fromMap(
        Map<String, dynamic>.from(data['loveLanguage'] as Map),
      );
    } catch (e) {
      logger.error('Error getting love language result: $e');
      return null;
    }
  }

  // ── Trivia ──

  Future<void> saveTriviaScore(int score) async {
    if (_uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      final currentHigh = (doc.data()?['triviaHighScore'] as int?) ?? 0;
      if (score > currentHigh) {
        await _firestore.collection('users').doc(_uid).update({
          'triviaHighScore': score,
        });
      }
    } catch (e) {
      logger.error('Error saving trivia score: $e');
    }
  }

  Future<int> getTriviaHighScore() async {
    if (_uid == null) return 0;
    try {
      final doc = await _firestore.collection('users').doc(_uid).get();
      return (doc.data()?['triviaHighScore'] as int?) ?? 0;
    } catch (e) {
      logger.error('Error getting trivia high score: $e');
      return 0;
    }
  }

  // ── This or That ──

  Future<Map<String, int>> getThisOrThatStats(String questionId) async {
    try {
      final doc = await _firestore
          .collection('this_or_that_stats')
          .doc(questionId)
          .get();
      if (!doc.exists) {
        return {'optionA_count': 0, 'optionB_count': 0};
      }
      final data = doc.data()!;
      return {
        'optionA_count': (data['optionA_count'] as int?) ?? 0,
        'optionB_count': (data['optionB_count'] as int?) ?? 0,
      };
    } catch (e) {
      logger.error('Error getting this or that stats: $e');
      return {'optionA_count': 0, 'optionB_count': 0};
    }
  }

  Future<void> voteThisOrThat(String questionId, String option) async {
    if (_uid == null) return;
    try {
      final field = option == 'A' ? 'optionA_count' : 'optionB_count';
      await _firestore
          .collection('this_or_that_stats')
          .doc(questionId)
          .set({field: FieldValue.increment(1)}, SetOptions(merge: true));
    } catch (e) {
      logger.error('Error voting this or that: $e');
    }
  }

  // ── Multiplayer Sessions ──

  Future<String> createGameSession({
    required String gameType,
    required String opponentId,
  }) async {
    if (_uid == null) throw Exception('Not logged in');
    try {
      final random = Random();
      List<int> questionIndices;
      if (gameType == 'would_you_rather') {
        final all = List<int>.generate(wouldYouRatherQuestions.length, (i) => i);
        all.shuffle(random);
        questionIndices = all.take(10).toList();
      } else {
        questionIndices =
            List<int>.generate(compatibilityQuestions.length, (i) => i);
      }

      final doc = await _firestore.collection('game_sessions').add({
        'gameType': gameType,
        'createdBy': _uid,
        'opponent': opponentId,
        'status': 'pending',
        'questionIndices': questionIndices,
        'answers': <String, dynamic>{},
        'result': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      logger.info('Game session created: ${doc.id}');
      return doc.id;
    } catch (e) {
      logger.error('Error creating game session: $e');
      rethrow;
    }
  }

  Stream<GameSession> watchGameSession(String sessionId) {
    return _firestore
        .collection('game_sessions')
        .doc(sessionId)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => GameSession.fromFirestore(snap));
  }

  Future<void> submitAnswer(String sessionId, int questionIndex, int answer) async {
    if (_uid == null) return;
    try {
      await _firestore.collection('game_sessions').doc(sessionId).update({
        'answers.$_uid': FieldValue.arrayUnion([answer]),
        'status': 'active',
      });
    } catch (e) {
      logger.error('Error submitting answer: $e');
    }
  }

  Future<void> completeSession(String sessionId, Map<String, dynamic> result) async {
    try {
      await _firestore.collection('game_sessions').doc(sessionId).update({
        'status': 'completed',
        'result': result,
      });
    } catch (e) {
      logger.error('Error completing session: $e');
    }
  }

  Stream<List<GameSession>> watchPendingSessions() {
    if (_uid == null) return const Stream.empty();
    return _firestore
        .collection('game_sessions')
        .where('opponent', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GameSession.fromFirestore(d)).toList());
  }

  // ── Matches list (for multiplayer hub) ──

  Future<List<Map<String, dynamic>>> getMatches() async {
    if (_uid == null) return [];
    try {
      final matchesSnap = await _firestore
          .collection('matches')
          .where('users', arrayContains: _uid)
          .orderBy('matchedAt', descending: true)
          .limit(50)
          .get();

      final List<Map<String, dynamic>> result = [];
      for (final doc in matchesSnap.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] as List? ?? []);
        final otherUid = users.firstWhere((u) => u != _uid, orElse: () => '');
        if (otherUid.isEmpty) continue;

        final userDoc =
            await _firestore.collection('users').doc(otherUid).get();
        if (!userDoc.exists) continue;
        final userData = userDoc.data()!;
        result.add({
          'uid': otherUid,
          'displayName': userData['displayName'] ?? 'User',
          'photoUrl': (userData['photos'] as List?)?.isNotEmpty == true
              ? (userData['photos'] as List).first
              : null,
        });
      }
      return result;
    } catch (e) {
      logger.error('Error getting matches: $e');
      return [];
    }
  }
}
