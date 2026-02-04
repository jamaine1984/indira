import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:indira_love/core/theme/app_theme.dart';
import 'package:indira_love/core/services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // No auto-login - removed to prevent app from getting stuck

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_background.png',
              fit: BoxFit.cover,
            ),
          ),

          // Gradient Overlay for better text visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo at the top
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                      const SizedBox(height: 24),
                      Text(
                        'Indira Love',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.3, end: 0),
                    ],
                  ),

                  // Bottom section with tagline and button
                  Column(
                    children: [
                      // Tagline
                      Text(
                        'Find Your Perfect Match',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 800.ms, delay: 400.ms).slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Discover meaningful connections with\nverified profiles & cultural compatibility',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(duration: 800.ms, delay: 600.ms),

                      const SizedBox(height: 48),

                      // Get Started Button
                      ElevatedButton(
                        onPressed: () => context.go('/signup'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 64),
                          backgroundColor: AppTheme.primaryRose,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 8,
                          shadowColor: AppTheme.primaryRose.withOpacity(0.5),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms, delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),

                      const SizedBox(height: 16),

                      // Already have account button
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(
                          'Already have an account? Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms, delay: 1000.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
