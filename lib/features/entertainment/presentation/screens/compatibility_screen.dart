import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/entertainment/data/compatibility_questions.dart';
import 'package:indira_love/features/entertainment/models/game_models.dart';
import 'package:indira_love/features/entertainment/services/entertainment_service.dart';

class CompatibilityScreen extends StatefulWidget {
  final String sessionId;

  const CompatibilityScreen({super.key, required this.sessionId});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final _service = EntertainmentService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _currentQuestionIdx = 0;
  bool _waitingForOpponent = false;
  bool _completionSent = false;

  void _selectOption(int option) {
    _service.submitAnswer(widget.sessionId, _currentQuestionIdx, option);

    if (_currentQuestionIdx < compatibilityQuestions.length - 1) {
      setState(() => _currentQuestionIdx++);
    } else {
      setState(() => _waitingForOpponent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameSession>(
      stream: _service.watchGameSession(widget.sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        final session = snapshot.data!;

        // Check if both players are done
        if (session.status == 'completed') {
          return _buildResultView(session);
        }

        if (_checkBothDone(session)) {
          _completeAndShowResult(session);
          return _buildResultView(session);
        }

        if (_waitingForOpponent) {
          return _buildWaitingView();
        }

        final qIndex = session.questionIndices[_currentQuestionIdx];
        if (qIndex >= compatibilityQuestions.length) {
          return _buildWaitingView();
        }

        final question = compatibilityQuestions[qIndex];
        final progress =
            (_currentQuestionIdx + 1) / compatibilityQuestions.length;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor:
                                  const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_currentQuestionIdx + 1}/${compatibilityQuestions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Question
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      question.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Options
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => _selectOption(index),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                child: Text(
                                  question.options[index],
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    color: AppTheme.textCharcoal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _checkBothDone(GameSession session) {
    final myAnswers = session.answers[_uid];
    final opponentId =
        session.createdBy == _uid ? session.opponent : session.createdBy;
    final opponentAnswers = session.answers[opponentId];
    return (myAnswers != null &&
            myAnswers.length >= compatibilityQuestions.length) &&
        (opponentAnswers != null &&
            opponentAnswers.length >= compatibilityQuestions.length);
  }

  void _completeAndShowResult(GameSession session) {
    if (_completionSent) return;
    _completionSent = true;

    final opponentId =
        session.createdBy == _uid ? session.opponent : session.createdBy;
    final myAnswers = session.answers[_uid] ?? [];
    final opponentAnswers = session.answers[opponentId] ?? [];

    int matches = 0;
    final len = myAnswers.length < opponentAnswers.length
        ? myAnswers.length
        : opponentAnswers.length;
    for (int i = 0; i < len; i++) {
      if (myAnswers[i] == opponentAnswers[i]) matches++;
    }
    final score = len > 0 ? (matches / len * 100).round() : 0;

    _service.completeSession(widget.sessionId, {
      'compatibilityScore': score,
      'matchingAnswers': matches,
      'totalQuestions': len,
    });
  }

  Widget _buildWaitingView() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u{23F3}', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 24),
                  const Text(
                    'Waiting for your match...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Once your match finishes, you\'ll see your compatibility score!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                          color: Colors.white70, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultView(GameSession session) {
    final result = session.result;
    final score = result?['compatibilityScore'] as int? ?? 0;

    String emoji;
    String label;
    if (score >= 80) {
      emoji = '\u{1F525}';
      label = 'Amazing Match!';
    } else if (score >= 60) {
      emoji = '\u{2764}';
      label = 'Great Compatibility!';
    } else if (score >= 40) {
      emoji = '\u{1F60A}';
      label = 'Good Potential!';
    } else {
      emoji = '\u{1F914}';
      label = 'Opposites Attract?';
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 24),
                  Text(
                    '$score%',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You matched on ${result?['matchingAnswers'] ?? 0} out of ${result?['totalQuestions'] ?? 0} questions',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/entertainment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.secondaryPlum,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Back to Games',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
