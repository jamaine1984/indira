import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:indira_love/core/theme/app_theme.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.romanticGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Safety & Security',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        icon: Icons.shield,
                        title: 'Safety Tips',
                        items: [
                          'Never share personal information like your address, phone number, or financial details in early conversations',
                          'Always meet in public places for first dates',
                          'Tell a friend or family member about your plans when meeting someone new',
                          'Trust your instincts - if something feels wrong, it probably is',
                          'Video chat before meeting in person to verify identity',
                          'Keep conversations on the Indira Love platform until you feel comfortable',
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        icon: Icons.report,
                        title: 'Report & Block',
                        items: [
                          'Report suspicious profiles or inappropriate behavior immediately',
                          'Block users who make you uncomfortable',
                          'Our moderation team reviews all reports within 24 hours',
                          'Harassment, scams, and fake profiles are not tolerated',
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        icon: Icons.verified_user,
                        title: 'Account Security',
                        items: [
                          'Use a strong, unique password for your account',
                          'Enable two-factor authentication when available',
                          'Never share your login credentials with anyone',
                          'Log out from shared or public devices',
                          'Review your account activity regularly',
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        icon: Icons.camera_alt,
                        title: 'Photo & Video Safety',
                        items: [
                          'Only share photos you\'re comfortable with others seeing',
                          'Be cautious about sharing photos that reveal your location',
                          'Report users who request inappropriate photos',
                          'Screenshots are not allowed - report violations',
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        icon: Icons.attach_money,
                        title: 'Financial Safety',
                        items: [
                          'Never send money to someone you haven\'t met in person',
                          'Be wary of sob stories or urgent requests for financial help',
                          'Indira Love staff will never ask for payment outside the app',
                          'Report suspected romance scams immediately',
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Contact Support
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.support_agent,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Need Help?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Our safety team is here to help 24/7',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'safety@indiralove.com',
                                  queryParameters: {
                                    'subject': 'Safety Concern',
                                  },
                                );
                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.email, color: AppTheme.primaryRose),
                              label: const Text(
                                'Contact Safety Team',
                                style: TextStyle(
                                  color: AppTheme.primaryRose,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Emergency Resources
                      _buildSection(
                        icon: Icons.emergency,
                        title: 'Emergency Resources',
                        items: [
                          'If you are in immediate danger, call local emergency services (911 in US)',
                          'National Domestic Violence Hotline: 1-800-799-7233',
                          'National Sexual Assault Hotline: 1-800-656-4673',
                          'Crisis Text Line: Text HOME to 741741',
                        ],
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
