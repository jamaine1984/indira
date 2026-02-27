import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/entertainment/data/would_you_rather_data.dart';
import 'package:indira_love/features/entertainment/models/game_models.dart';
import 'package:indira_love/features/entertainment/services/entertainment_service.dart';

class WouldYouRatherScreen extends StatefulWidget {
  final String sessionId;

  const WouldYouRatherScreen({super.key, required this.sessionId});

  @override
  State<WouldYouRatherScreen> createState() => _WouldYouRatherScreenState();
}

class _WouldYouRatherScreenState extends State<WouldYouRatherScreen> {
  final _service = EntertainmentService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _currentQuestionIdx = 0;
  final List<int> _myAnswers = [];
  bool _waitingForOpponent = false;

  void _selectOption(int option) {
    setState(() {
      _myAnswers.add(option);
    });

    _service.submitAnswer(widget.sessionId, _currentQuestionIdx, option);

    if (_currentQuestionIdx < 9) {
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
        if (session.status == 'completed' || _checkBothDone(session)) {
          return _buildResultsView(session);
        }

        if (_waitingForOpponent) {
          return _buildWaitingView();
        }

        final qIndices = session.questionIndices;
        if (_currentQuestionIdx >= qIndices.length) {
          return _buildWaitingView();
        }

        final qIndex = qIndices[_currentQuestionIdx];
        if (qIndex >= wouldYouRatherQuestions.length) {
          return _buildWaitingView();
        }

        final question = wouldYouRatherQuestions[qIndex];
        final progress = (_currentQuestionIdx + 1) / qIndices.length.clamp(1, 10);

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_currentQuestionIdx + 1}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Would You Rather...',
                    style: TextStyle(
                      fontFamily: 'DancingScript',
                      fontSize: 28,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  // Option A
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => _selectOption(0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          question.optionA,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'OR',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Option B
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GestureDetector(
                      onTap: () => _selectOption(1),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          question.optionB,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
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
    final opponentId = session.createdBy == _uid ? session.opponent : session.createdBy;
    final opponentAnswers = session.answers[opponentId];
    return (myAnswers != null && myAnswers.length >= 10) &&
        (opponentAnswers != null && opponentAnswers.length >= 10);
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
                    'You\'ve finished! Once your match completes their answers, you\'ll see the results.',
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
                      style: TextStyle(color: Colors.white70, fontFamily: 'Inter'),
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

  Widget _buildResultsView(GameSession session) {
    final opponentId =
        session.createdBy == _uid ? session.opponent : session.createdBy;
    final myAnswers = session.answers[_uid] ?? [];
    final opponentAnswers = session.answers[opponentId] ?? [];

    int matches = 0;
    final minLen = myAnswers.length < opponentAnswers.length
        ? myAnswers.length
        : opponentAnswers.length;
    for (int i = 0; i < minLen; i++) {
      if (myAnswers[i] == opponentAnswers[i]) matches++;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text('\u{1F46B}', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'Results!',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You matched on $matches out of $minLen questions!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                // Show each question comparison
                ...List.generate(minLen, (i) {
                  final qIndex = session.questionIndices[i];
                  if (qIndex >= wouldYouRatherQuestions.length) {
                    return const SizedBox.shrink();
                  }
                  final question = wouldYouRatherQuestions[qIndex];
                  final same = myAnswers[i] == opponentAnswers[i];
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(same ? 0.9 : 0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              same ? '\u{2705}' : '\u{274C}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Q${i + 1}: ${myAnswers[i] == 0 ? question.optionA : question.optionB}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textCharcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!same)
                          Padding(
                            padding: const EdgeInsets.only(left: 32, top: 4),
                            child: Text(
                              'They chose: ${opponentAnswers[i] == 0 ? question.optionA : question.optionB}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
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
    );
  }
}
