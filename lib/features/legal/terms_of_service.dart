import 'package:flutter/material.dart';

/// Terms of Service page
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Last Updated',
              'January 15, 2025',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Acceptance of Terms',
              '''By accessing or using Indira Love ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.

The App is intended for users who are at least 18 years old. By using the App, you represent that you are at least 18 years of age.''',
            ),
            _buildSection(
              '2. Account Registration',
              '''To use the App, you must create an account and provide accurate, complete information. You are responsible for:
• Maintaining the confidentiality of your account credentials
• All activities that occur under your account
• Immediately notifying us of any unauthorized use

We reserve the right to suspend or terminate accounts that violate these terms or for any reason at our discretion.''',
            ),
            _buildSection(
              '3. User Conduct',
              '''You agree NOT to:
• Harass, abuse, or harm other users
• Post false, misleading, or fraudulent content
• Impersonate any person or entity
• Use the App for commercial purposes without authorization
• Transmit viruses, malware, or harmful code
• Scrape, harvest, or collect user data
• Create multiple accounts or fake profiles
• Engage in financial scams or solicitation
• Share explicit content without consent
• Discriminate based on race, religion, gender, or orientation

Violation of these rules may result in immediate account termination and legal action.''',
            ),
            _buildSection(
              '4. Content',
              '''You retain ownership of content you post, but grant us a worldwide, non-exclusive, royalty-free license to use, display, and distribute your content within the App.

We reserve the right to remove any content that violates these terms or for any other reason. You are solely responsible for all content you post.''',
            ),
            _buildSection(
              '5. Subscription and Payments',
              '''Premium subscriptions are billed on a recurring basis. By subscribing, you authorize us to charge your payment method.

• Subscriptions automatically renew unless canceled
• Refunds are provided only as required by law
• Prices may change with 30 days notice
• Virtual items (coins, gifts) have no real-world value
• All sales are final unless otherwise stated''',
            ),
            _buildSection(
              '6. Privacy and Data',
              '''Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your data.

We implement industry-standard security measures, but cannot guarantee absolute security. You use the App at your own risk.''',
            ),
            _buildSection(
              '7. Safety and Verification',
              '''While we implement safety measures including:
• Photo verification
• ID verification
• Scam detection algorithms
• User reporting system

We cannot guarantee the identity or intentions of other users. You are responsible for your own safety when meeting people from the App.

NEVER send money to people you meet on the App. Report suspicious behavior immediately.''',
            ),
            _buildSection(
              '8. Third-Party Services',
              '''The App may integrate with third-party services (payment processors, social media, etc.). We are not responsible for third-party services or their terms.''',
            ),
            _buildSection(
              '9. Intellectual Property',
              '''All App content, features, and functionality (including but not limited to software, text, graphics, logos) are owned by us and protected by copyright, trademark, and other laws.

You may not copy, modify, distribute, or reverse engineer any part of the App.''',
            ),
            _buildSection(
              '10. Disclaimers',
              '''THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.

We do not warrant that:
• The App will be uninterrupted or error-free
• Defects will be corrected
• The App is free of viruses or harmful components
• Results obtained from the App will be accurate or reliable''',
            ),
            _buildSection(
              '11. Limitation of Liability',
              '''TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR:
• Indirect, incidental, special, or consequential damages
• Loss of profits, data, or goodwill
• Damages arising from your use or inability to use the App
• Damages from unauthorized access to your account
• Damages from interactions with other users

Our total liability shall not exceed the amount you paid us in the past 12 months.''',
            ),
            _buildSection(
              '12. Indemnification',
              '''You agree to indemnify and hold us harmless from any claims, damages, or expenses arising from:
• Your violation of these terms
• Your violation of any law or regulation
• Your violation of third-party rights
• Your use of the App''',
            ),
            _buildSection(
              '13. Dispute Resolution',
              '''Any disputes arising from these terms or the App shall be resolved through:

1. Good faith negotiation
2. Mediation (if negotiation fails)
3. Binding arbitration (if mediation fails)

You waive your right to participate in class actions or jury trials.''',
            ),
            _buildSection(
              '14. Termination',
              '''We may terminate or suspend your account at any time for:
• Violation of these terms
• Fraudulent or illegal activity
• Inactivity for extended periods
• Any other reason at our discretion

Upon termination, your right to use the App ceases immediately. We may delete your data as described in our Privacy Policy.''',
            ),
            _buildSection(
              '15. Changes to Terms',
              '''We may modify these terms at any time. Continued use of the App after changes constitutes acceptance of new terms.

Material changes will be communicated via:
• In-app notification
• Email to your registered address
• Notice on our website''',
            ),
            _buildSection(
              '16. Governing Law',
              '''These terms are governed by the laws of [Your Jurisdiction], without regard to conflict of law provisions.''',
            ),
            _buildSection(
              '17. Severability',
              '''If any provision of these terms is found to be unenforceable, the remaining provisions shall remain in full effect.''',
            ),
            _buildSection(
              '18. Contact Us',
              '''For questions about these Terms of Service, contact us at:

Email: legal@indiralove.com
Address: [Your Company Address]
Phone: [Your Phone Number]''',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'By using Indira Love, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
