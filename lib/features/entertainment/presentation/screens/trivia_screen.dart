import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/entertainment/data/trivia_questions.dart';
import 'package:indira_love/features/entertainment/models/game_models.dart';
import 'package:indira_love/features/entertainment/services/entertainment_service.dart';

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  late List<TriviaQuestion> _questions;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _finished = false;
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _startRound();
    _loadHighScore();
  }

  void _startRound() {
    final random = Random();
    final all = List<TriviaQuestion>.from(triviaQuestions);
    all.shuffle(random);
    _questions = all.take(10).toList();
    _currentIndex = 0;
    _score = 0;
    _selectedAnswer = null;
    _answered = false;
    _finished = false;
  }

  Future<void> _loadHighScore() async {
    final high = await EntertainmentService().getTriviaHighScore();
    if (!mounted) return;
    setState(() => _highScore = high);
  }

  void _onSelect(int index) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (index == _questions[_currentIndex].correctIndex) {
        _score++;
      }
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _selectedAnswer = null;
          _answered = false;
        });
      } else {
        _finishRound();
      }
    });
  }

  Future<void> _finishRound() async {
    await EntertainmentService().saveTriviaScore(_score);
    await _loadHighScore();
    if (!mounted) return;
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return _buildResultView();
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Score: $_score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Category badge
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: question.category == 'bollywood'
                        ? Colors.orange.withOpacity(0.8)
                        : Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question.category == 'bollywood' ? '\u{1F3AC} Bollywood' : '\u{1F3CF} Cricket',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                    Color bgColor = Colors.white.withOpacity(0.9);
                    Color textColor = AppTheme.textCharcoal;

                    if (_answered) {
                      if (index == question.correctIndex) {
                        bgColor = Colors.green.withOpacity(0.9);
                        textColor = Colors.white;
                      } else if (index == _selectedAnswer) {
                        bgColor = Colors.red.withOpacity(0.9);
                        textColor = Colors.white;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _answered ? null : () => _onSelect(index),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: textColor.withOpacity(0.5)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      question.options[index],
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  if (_answered && index == question.correctIndex)
                                    const Icon(Icons.check_circle, color: Colors.white),
                                  if (_answered &&
                                      index == _selectedAnswer &&
                                      index != question.correctIndex)
                                    const Icon(Icons.cancel, color: Colors.white),
                                ],
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
  }

  Widget _buildResultView() {
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
                  Text(
                    _score >= 8 ? '\u{1F3C6}' : _score >= 5 ? '\u{1F44F}' : '\u{1F4AA}',
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _score >= 8
                        ? 'Amazing!'
                        : _score >= 5
                            ? 'Well Done!'
                            : 'Keep Trying!',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You scored $_score out of ${_questions.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'High Score: $_highScore',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _startRound());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.secondaryPlum,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Back to Games',
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
}
