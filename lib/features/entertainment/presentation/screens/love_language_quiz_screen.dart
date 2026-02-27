import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/entertainment/data/love_language_questions.dart';
import 'package:indira_love/features/entertainment/models/love_language_result.dart';
import 'package:indira_love/features/entertainment/services/entertainment_service.dart';

class LoveLanguageQuizScreen extends StatefulWidget {
  const LoveLanguageQuizScreen({super.key});

  @override
  State<LoveLanguageQuizScreen> createState() => _LoveLanguageQuizScreenState();
}

class _LoveLanguageQuizScreenState extends State<LoveLanguageQuizScreen> {
  int _currentIndex = 0;
  final Map<String, int> _scores = {
    'wordsOfAffirmation': 0,
    'actsOfService': 0,
    'receivingGifts': 0,
    'qualityTime': 0,
    'physicalTouch': 0,
  };
  bool _saving = false;

  void _selectOption(LoveLanguageOption option) {
    setState(() {
      _scores[option.language] = (_scores[option.language] ?? 0) + 1;
    });

    if (_currentIndex < loveLanguageQuestions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    // Determine primary language
    String primaryKey = 'wordsOfAffirmation';
    int maxScore = 0;
    _scores.forEach((key, value) {
      if (value > maxScore) {
        maxScore = value;
        primaryKey = key;
      }
    });

    final info = LoveLanguageResult.languageInfo[primaryKey]!;
    final result = LoveLanguageResult(
      primaryLanguage: info['name']!,
      emoji: info['emoji']!,
      shortName: info['short']!,
      description: info['description']!,
      scores: Map<String, int>.from(_scores),
    );

    setState(() => _saving = true);
    try {
      await EntertainmentService().saveLoveLanguageResult(result);
      if (!mounted) return;
      context.pushReplacement('/love-language-result');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving result: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saving) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Discovering your love language...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = loveLanguageQuestions[_currentIndex];
    final progress = (_currentIndex + 1) / loveLanguageQuestions.length;

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
                      '${_currentIndex + 1}/${loveLanguageQuestions.length}',
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
                    final option = question.options[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _selectOption(option),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Text(
                              option.text,
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
  }
}
