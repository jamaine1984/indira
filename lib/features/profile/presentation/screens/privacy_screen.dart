import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:indira_love/core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
                      'Privacy Policy',
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
                      // Last Updated
                      Text(
                        'Last Updated: November 2025',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildSection(
                        title: '1. Introduction',
                        content:
                            'Welcome to Indira Love. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you use our app and tell you about your privacy rights.',
                      ),

                      _buildSection(
                        title: '2. Data We Collect',
                        content:
                            'We collect and process the following types of data:\n\n'
                            '• Account Information: Name, email address, date of birth, gender, sexual orientation\n'
                            '• Profile Information: Photos, bio, interests, preferences\n'
                            '• Usage Data: How you interact with our service, matches, messages\n'
                            '• Device Information: Device type, operating system, unique device identifiers\n'
                            '• Location Data: Approximate location based on IP address or precise location if you enable it\n'
                            '• Communications: Messages you send and receive through the app',
                      ),

                      _buildSection(
                        title: '3. How We Use Your Data',
                        content:
                            'We use your data to:\n\n'
                            '• Provide and improve our dating services\n'
                            '• Show you potential matches based on your preferences\n'
                            '• Enable communication between users\n'
                            '• Ensure safety and security of our platform\n'
                            '• Send you service updates and promotional communications\n'
                            '• Analyze usage patterns to improve user experience\n'
                            '• Comply with legal obligations',
                      ),

                      _buildSection(
                        title: '4. Data Sharing',
                        content:
                            'We may share your information with:\n\n'
                            '• Other Users: Your profile information is visible to other users\n'
                            '• Service Providers: Third parties who help us operate our service\n'
                            '• Law Enforcement: When required by law or to protect safety\n'
                            '• Business Transfers: In case of merger, acquisition, or sale\n\n'
                            'We do NOT sell your personal information to third parties for marketing purposes.',
                      ),

                      _buildSection(
                        title: '5. Your Privacy Rights',
                        content:
                            'You have the right to:\n\n'
                            '• Access your personal data\n'
                            '• Correct inaccurate data\n'
                            '• Request deletion of your data\n'
                            '• Object to processing of your data\n'
                            '• Data portability\n'
                            '• Withdraw consent at any time\n\n'
                            'To exercise these rights, contact us at privacy@indiralove.com',
                      ),

                      _buildSection(
                        title: '6. Data Retention',
                        content:
                            'We retain your personal data only as long as necessary for the purposes outlined in this policy. When you delete your account, we will delete or anonymize your personal data within 30 days, except where we need to retain it for legal compliance.',
                      ),

                      _buildSection(
                        title: '7. Children\'s Privacy',
                        content:
                            'Our service is not directed to individuals under the age of 18. We do not knowingly collect personal information from children. If we become aware that a child has provided us with personal data, we will take steps to delete such information.',
                      ),

                      _buildSection(
                        title: '8. Security',
                        content:
                            'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction. However, no internet transmission is completely secure, and we cannot guarantee absolute security.',
                      ),

                      _buildSection(
                        title: '9. International Data Transfers',
                        content:
                            'Your data may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with this privacy policy.',
                      ),

                      _buildSection(
                        title: '10. Cookies and Tracking',
                        content:
                            'We use cookies and similar tracking technologies to improve your experience, analyze usage, and deliver personalized content. You can manage cookie preferences through your device settings.',
                      ),

                      _buildSection(
                        title: '11. Changes to This Policy',
                        content:
                            'We may update this privacy policy from time to time. We will notify you of any significant changes by email or through the app. Continued use of our service after changes constitutes acceptance of the updated policy.',
                      ),

                      _buildSection(
                        title: '12. Contact Us',
                        content:
                            'If you have questions about this privacy policy or our privacy practices, please contact us:\n\n'
                            'Email: privacy@indiralove.com\n'
                            'Address: Indira Love Privacy Team\n'
                            '123 Dating Street, Love City, LC 12345',
                      ),

                      const SizedBox(height: 32),

                      // GDPR Notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'GDPR & CCPA Compliance',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Indira Love complies with GDPR (General Data Protection Regulation) and CCPA (California Consumer Privacy Act). You have specific rights regarding your personal data under these regulations.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
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
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
