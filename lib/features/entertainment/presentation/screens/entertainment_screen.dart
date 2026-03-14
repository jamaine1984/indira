import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/l10n/app_localizations.dart';

class EntertainmentScreen extends StatelessWidget {
  const EntertainmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.romanticGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          context.go('/discover');
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        l10n.entertainment,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Games grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _GameCard(
                        title: l10n.loveLanguageQuiz.replaceAll(' ', '\n'),
                        emoji: '\u{1F495}',
                        description: 'Discover your love language & earn a badge!',
                        color: const Color(0xFFE91E63),
                        onTap: () => context.push('/love-language-quiz'),
                      ),
                      _GameCard(
                        title: l10n.triviaGame.replaceAll(' ', '\n'),
                        emoji: '\u{1F3AC}',
                        description: 'Test your knowledge in 10-question rounds',
                        color: const Color(0xFFFF9800),
                        onTap: () => context.push('/trivia'),
                      ),
                      _GameCard(
                        title: l10n.thisOrThat.replaceAll(' ', '\n'),
                        emoji: '\u{1F914}',
                        description: 'Pick your preference & see what others chose',
                        color: const Color(0xFF9C27B0),
                        onTap: () => context.push('/this-or-that'),
                      ),
                      _GameCard(
                        title: l10n.wouldYouRather.replaceAll(' ', '\n'),
                        emoji: '\u{1F46B}',
                        description: 'Play with a match & compare answers',
                        color: const Color(0xFF2196F3),
                        badge: 'MULTIPLAYER',
                        onTap: () => context.push('/multiplayer-hub?game=would_you_rather'),
                      ),
                      _GameCard(
                        title: l10n.compatibilityGame.replaceAll(' ', '\n'),
                        emoji: '\u{1F4AF}',
                        description: '10 questions to find your compatibility %',
                        color: const Color(0xFF4CAF50),
                        badge: 'MULTIPLAYER',
                        onTap: () => context.push('/multiplayer-hub?game=compatibility'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String emoji;
  final String description;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.emoji,
    required this.description,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
