import 'package:flutter/material.dart';

/// Privacy Policy page
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
              'Introduction',
              '''Indira Love ("we", "us", "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our dating application.

By using Indira Love, you consent to the practices described in this Privacy Policy.''',
            ),
            _buildSection(
              '1. Information We Collect',
              '''We collect several types of information:

A. Information You Provide:
• Name, age, gender, and date of birth
• Email address and phone number (optional)
• Profile photos and bio
• Location data (city, country)
• Interests, preferences, and dating criteria
• Messages and communications with other users
• Payment information (processed by third-party payment providers)

B. Automatically Collected Information:
• Device information (model, OS, unique identifiers)
• IP address and location data
• App usage data and analytics
• Crash reports and error logs
• Cookies and similar technologies

C. Information from Other Sources:
• Social media profiles (if you choose to connect)
• Third-party authentication services
• Public databases for verification purposes''',
            ),
            _buildSection(
              '2. How We Use Your Information',
              '''We use your information to:

• Create and manage your account
• Match you with compatible users
• Facilitate communication between users
• Process payments and subscriptions
• Send notifications and updates
• Improve app functionality and user experience
• Detect and prevent fraud, scams, and abuse
• Comply with legal obligations
• Conduct research and analytics
• Personalize your experience
• Send marketing communications (with your consent)''',
            ),
            _buildSection(
              '3. How We Share Your Information',
              '''We may share your information with:

A. Other Users:
• Your public profile information (photos, bio, age, location)
• Your messages and interactions
• Your verification status

B. Service Providers:
• Cloud hosting providers (Firebase/Google Cloud)
• Payment processors (for subscriptions)
• Analytics providers
• Customer support tools
• Marketing and advertising partners

C. Legal Requirements:
• Law enforcement or government agencies
• Court orders or legal processes
• Protection of our rights and safety
• Prevention of fraud or illegal activity

D. Business Transfers:
• Merger, acquisition, or sale of assets

We NEVER sell your personal data to third parties for their marketing purposes.''',
            ),
            _buildSection(
              '4. Data Retention',
              '''We retain your information:

• Active accounts: For as long as your account is active
• Deleted accounts: 30 days after deletion request (grace period)
• Legal compliance: As required by law (e.g., financial records)
• Anonymized data: May be retained indefinitely for analytics

You can request deletion of your data at any time through the app settings.''',
            ),
            _buildSection(
              '5. Your Privacy Rights',
              '''Depending on your location, you may have the following rights:

• Right to Access: Request a copy of your data
• Right to Rectification: Correct inaccurate data
• Right to Erasure: Delete your account and data
• Right to Portability: Export your data in machine-readable format
• Right to Object: Opt-out of certain data processing
• Right to Restrict Processing: Limit how we use your data
• Right to Withdraw Consent: Opt-out of optional data collection

To exercise these rights, contact us at privacy@indiralove.com or use the in-app data export/deletion features.''',
            ),
            _buildSection(
              '6. GDPR Compliance (EU Users)',
              '''If you are in the European Union:

• Legal basis for processing: Consent, contract performance, legitimate interests
• Data controller: Indira Love
• Data transfers: We use standard contractual clauses for international transfers
• Supervisory authority: You can lodge complaints with your local data protection authority
• Right to object: You can object to processing based on legitimate interests''',
            ),
            _buildSection(
              '7. CCPA Compliance (California Users)',
              '''If you are a California resident:

• Categories of data collected: See Section 1
• Purpose of collection: See Section 2
• Third parties we share with: See Section 3
• Right to know: Request what data we collected about you
• Right to delete: Request deletion of your data
• Right to opt-out: We don\'t sell your data, so no opt-out needed
• Non-discrimination: We won\'t discriminate for exercising your rights''',
            ),
            _buildSection(
              '8. Children\'s Privacy',
              '''The App is NOT intended for users under 18 years old. We do not knowingly collect data from children.

If we discover that we have collected data from a child, we will delete it immediately. If you believe we have data from a child, contact us at privacy@indiralove.com.''',
            ),
            _buildSection(
              '9. Security Measures',
              '''We implement industry-standard security measures:

• End-to-end encryption for messages
• HTTPS/TLS for data transmission
• Encrypted data storage
• Regular security audits
• Access controls and authentication
• Firewall protection
• Intrusion detection systems

However, no method of transmission or storage is 100% secure. You use the App at your own risk.''',
            ),
            _buildSection(
              '10. Cookies and Tracking',
              '''We use cookies and similar technologies for:

• Authentication and session management
• Analytics and performance monitoring
• Personalization and preferences
• Advertising and marketing

You can control cookies through your browser settings, but this may limit app functionality.''',
            ),
            _buildSection(
              '11. Third-Party Services',
              '''The App integrates with third-party services:

• Firebase (Google): Cloud hosting and analytics
• Payment processors: Subscription and payment processing
• Social media platforms: Optional account linking
• Advertising networks: Ad serving

These services have their own privacy policies. We are not responsible for their practices.''',
            ),
            _buildSection(
              '12. International Data Transfers',
              '''Your data may be transferred to and stored in countries outside your residence, including the United States.

We ensure adequate protection through:
• Standard contractual clauses
• Privacy Shield certification (where applicable)
• Data processing agreements with service providers''',
            ),
            _buildSection(
              '13. Location Data',
              '''We collect location data to:

• Show you nearby matches
• Display your city/country on your profile
• Improve matching algorithms
• Provide location-based features

You can control location permissions through your device settings. Disabling location may limit app functionality.''',
            ),
            _buildSection(
              '14. Marketing Communications',
              '''We may send you:

• Promotional emails and notifications
• Product updates and new features
• Special offers and discounts
• Surveys and feedback requests

You can opt-out of marketing communications at any time through:
• Email unsubscribe links
• App notification settings
• Account settings''',
            ),
            _buildSection(
              '15. Data Breach Notification',
              '''In the event of a data breach that compromises your personal information:

• We will notify affected users within 72 hours
• We will notify relevant authorities as required by law
• We will provide details about the breach and remediation steps
• We will offer assistance (e.g., credit monitoring if applicable)''',
            ),
            _buildSection(
              '16. Changes to Privacy Policy',
              '''We may update this Privacy Policy periodically. Changes will be communicated through:

• In-app notification
• Email to registered users
• Notice on our website

Continued use of the App after changes constitutes acceptance of the updated policy.''',
            ),
            _buildSection(
              '17. Contact Information',
              '''For privacy-related questions or to exercise your rights:

Email: privacy@indiralove.com
Data Protection Officer: dpo@indiralove.com
Address: [Your Company Address]
Phone: [Your Phone Number]

Response time: We respond to requests within 30 days.''',
            ),
            _buildSection(
              '18. California Shine the Light Law',
              '''California residents can request information about personal information disclosed to third parties for direct marketing purposes.

Contact us at privacy@indiralove.com with "California Shine the Light" in the subject line.''',
            ),
            _buildSection(
              '19. Do Not Track',
              '''Some browsers have "Do Not Track" features. We currently do not respond to Do Not Track signals because there is no industry standard for compliance.''',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'By using Indira Love, you acknowledge that you have read and understood this Privacy Policy.',
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
