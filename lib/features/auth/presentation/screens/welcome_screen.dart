import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isFading = false;
  String _fadeTarget = '/signup';

  void _navigateWithFade(String route) {
    setState(() {
      _isFading = true;
      _fadeTarget = route;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _isFading ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 500),
        child: Stack(
          children: [
            // Full-screen welcome image
            Positioned.fill(
              child: Image.asset(
                'assets/images/indira_welcome.png',
                fit: BoxFit.cover,
              ),
            ),

            // Gradient at bottom for button visibility
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons at bottom
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // Create Account button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => _navigateWithFade('/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A843),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 16),

                  // Sign In
                  GestureDetector(
                    onTap: () => _navigateWithFade('/login'),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 600.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
