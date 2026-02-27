import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/features/entertainment/data/this_or_that_data.dart';
import 'package:indira_love/features/entertainment/services/entertainment_service.dart';

class ThisOrThatScreen extends StatefulWidget {
  const ThisOrThatScreen({super.key});

  @override
  State<ThisOrThatScreen> createState() => _ThisOrThatScreenState();
}

class _ThisOrThatScreenState extends State<ThisOrThatScreen> {
  final _service = EntertainmentService();
  int _currentIndex = 0;
  String? _selected; // 'A' or 'B'
  Map<String, int>? _stats;
  bool _loading = false;
  int _answered = 0;

  void _selectOption(String option) async {
    if (_selected != null) return;
    final pair = thisOrThatPairs[_currentIndex];

    setState(() {
      _selected = option;
      _loading = true;
    });

    await _service.voteThisOrThat(pair.id, option);
    final stats = await _service.getThisOrThatStats(pair.id);

    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
      _answered++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < thisOrThatPairs.length - 1) {
      setState(() {
        _currentIndex++;
        _selected = null;
        _stats = null;
      });
    } else {
      // Loop back
      setState(() {
        _currentIndex = 0;
        _selected = null;
        _stats = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pair = thisOrThatPairs[_currentIndex];
    final total = (_stats != null)
        ? ((_stats!['optionA_count'] ?? 0) + (_stats!['optionB_count'] ?? 0))
        : 0;
    final pctA = total > 0
        ? ((_stats!['optionA_count'] ?? 0) / total * 100).round()
        : 50;
    final pctB = total > 0 ? 100 - pctA : 50;

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
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'This or That',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_answered done',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Option A
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => _selectOption('A'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _selected == 'A'
                          ? Colors.orange.withOpacity(0.9)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(pair.emojiA, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          pair.optionA,
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _selected == 'A' ? Colors.white : AppTheme.textCharcoal,
                          ),
                        ),
                        if (_selected != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$pctA%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _selected == 'A' ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // VS divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.secondaryPlum,
                      ),
                    ),
                  ),
                ),
              ),
              // Option B
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => _selectOption('B'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _selected == 'B'
                          ? Colors.purple.withOpacity(0.9)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(pair.emojiB, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          pair.optionB,
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _selected == 'B' ? Colors.white : AppTheme.textCharcoal,
                          ),
                        ),
                        if (_selected != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '$pctB%',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _selected == 'B' ? Colors.white : Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Next button
              if (_selected != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.secondaryPlum,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
