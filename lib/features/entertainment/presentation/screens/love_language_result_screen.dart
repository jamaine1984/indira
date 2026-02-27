import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/entertainment/models/love_language_result.dart';
import 'package:indira_love/features/entertainment/services/entertainment_service.dart';

class LoveLanguageResultScreen extends StatefulWidget {
  const LoveLanguageResultScreen({super.key});

  @override
  State<LoveLanguageResultScreen> createState() =>
      _LoveLanguageResultScreenState();
}

class _LoveLanguageResultScreenState extends State<LoveLanguageResultScreen> {
  LoveLanguageResult? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final result = await EntertainmentService().getLoveLanguageResult(uid);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_result == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No result found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => context.go('/entertainment'),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(height: 8),
                // Badge emoji
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _result!.emoji,
                      style: const TextStyle(fontSize: 48),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Love Language is',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _result!.primaryLanguage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _result!.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Score breakdown
                const Text(
                  'Your Scores',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ..._result!.scores.entries.map((entry) {
                  final info = LoveLanguageResult.languageInfo[entry.key];
                  if (info == null) return const SizedBox.shrink();
                  final maxScore = _result!.scores.values
                      .reduce((a, b) => a > b ? a : b);
                  final fraction = maxScore > 0 ? entry.value / maxScore : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(info['emoji']!,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              info['name']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                // Badge info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppTheme.secondaryPlum),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your ${_result!.emoji} ${_result!.shortName} badge is now visible on your profile!',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppTheme.textCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.push('/love-language-quiz'),
                  child: const Text(
                    'Retake Quiz',
                    style: TextStyle(color: Colors.white70, fontFamily: 'Inter'),
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
