import 'package:flutter/material.dart';

/// Community Guidelines page
class CommunityGuidelinesPage extends StatelessWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Guidelines'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Indira Love',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Our community guidelines are designed to ensure a safe, respectful, and positive experience for everyone. By using Indira Love, you agree to follow these guidelines.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Be Authentic',
              '''• Use real photos of yourself
• Provide accurate information about your age, location, and identity
• Don\'t impersonate others or create fake profiles
• Use your real name or a recognizable nickname
• Complete photo verification to build trust

Fake profiles will be permanently banned.''',
              Icons.verified_user,
              Colors.blue,
            ),
            _buildSection(
              '2. Be Respectful',
              '''• Treat all users with kindness and respect
• Accept rejection gracefully
• Respect boundaries and consent
• No harassment, bullying, or hate speech
• No discriminatory language or behavior
• Respect cultural and religious differences

Everyone deserves to feel safe and respected.''',
              Icons.favorite,
              Colors.pink,
            ),
            _buildSection(
              '3. Be Safe',
              '''• Never share financial information
• Don\'t send money to people you meet online
• Meet in public places for first dates
• Tell friends/family about your plans
• Trust your instincts - if something feels wrong, it probably is
• Report suspicious behavior immediately
• Use the app\'s verification features

Your safety is our top priority.''',
              Icons.security,
              Colors.green,
            ),
            _buildSection(
              '4. Prohibited Content',
              '''DO NOT post or share:
• Nudity or sexually explicit content
• Violence or graphic imagery
• Hate speech or discriminatory content
• Illegal content or activities
• Spam or commercial solicitation
• Copyrighted material without permission
• Private information of others
• Scams or fraudulent schemes

Violations will result in immediate removal of content and possible account termination.''',
              Icons.block,
              Colors.red,
            ),
            _buildSection(
              '5. No Scams or Solicitation',
              '''Strictly prohibited:
• Requesting money or gifts
• Promoting businesses or services
• Advertising products
• Soliciting for websites or apps
• "Sugar daddy/mommy" arrangements
• Financial scams of any kind
• Cryptocurrency or investment schemes
• Asking for personal financial information

We have zero tolerance for scammers.''',
              Icons.report,
              Colors.orange,
            ),
            _buildSection(
              '6. Appropriate Messaging',
              '''When messaging others:
• Start with a friendly greeting
• Don\'t send unsolicited explicit content
• Respect if someone doesn\'t respond
• No spam or copy-paste messages
• Be patient and understanding
• Keep conversations appropriate

Harassment through messages will result in account suspension.''',
              Icons.message,
              Colors.purple,
            ),
            _buildSection(
              '7. Photo Guidelines',
              '''Profile photos must:
• Clearly show your face
• Be recent (within the last 2 years)
• Be appropriate for all ages
• Not contain nudity or sexual content
• Not promote products or services
• Not include children (except in background)
• Not be heavily filtered or misleading

We review reported photos and may remove inappropriate images.''',
              Icons.photo_camera,
              Colors.teal,
            ),
            _buildSection(
              '8. Age Requirements',
              '''• You must be 18 or older to use Indira Love
• Provide accurate age information
• We verify ages through photo and ID verification
• Minors found on the platform will be immediately removed
• Report anyone you suspect is underage

Protecting minors is everyone\'s responsibility.''',
              Icons.cake,
              Colors.brown,
            ),
            _buildSection(
              '9. Reporting System',
              '''Help us maintain a safe community:
• Report inappropriate profiles
• Report suspicious behavior
• Report scams or fraud attempts
• Report harassment or abuse
• Provide detailed information when reporting
• Block users who make you uncomfortable

All reports are reviewed by our safety team.''',
              Icons.flag,
              Colors.amber,
            ),
            _buildSection(
              '10. Consequences of Violations',
              '''Depending on the severity:
• Warning for minor violations
• Temporary suspension (24 hours - 30 days)
• Permanent ban for serious violations
• Legal action for illegal activities
• Cooperation with law enforcement

We take violations seriously to protect our community.''',
              Icons.gavel,
              Colors.indigo,
            ),
            _buildSection(
              '11. Dating Etiquette',
              '''Best practices:
• Be honest about your intentions
• Communicate clearly and promptly
• Be understanding of busy schedules
• Accept that not everyone will be interested
• Move at a comfortable pace
• Be courteous if you\'re not interested
• Give people a fair chance

Good manners go a long way!''',
              Icons.handshake,
              Colors.cyan,
            ),
            _buildSection(
              '12. First Date Safety',
              '''When meeting in person:
• Choose a public place
• Arrange your own transportation
• Tell a friend where you\'re going
• Keep your phone charged
• Don\'t accept drinks you didn\'t see poured
• Trust your instincts
• Stay sober enough to make good decisions

Safety first, always.''',
              Icons.restaurant,
              Colors.lime,
            ),
            _buildSection(
              '13. Privacy Protection',
              '''Protect your privacy:
• Don\'t share your full name immediately
• Keep your address private
• Don\'t share workplace details
• Avoid sharing phone number too soon
• Don\'t link to social media profiles with personal info
• Use the in-app messaging until you\'re comfortable

Your privacy is in your hands.''',
              Icons.lock,
              Colors.deepPurple,
            ),
            _buildSection(
              '14. Consent and Boundaries',
              '''Remember:
• No means no
• Respect personal boundaries
• Don\'t pressure anyone
• Consent can be withdrawn at any time
• Respect relationship preferences
• Accept if someone is not interested

Consent and respect are non-negotiable.''',
              Icons.pan_tool,
              Colors.deepOrange,
            ),
            _buildSection(
              '15. Diversity and Inclusion',
              '''We celebrate diversity:
• All races, ethnicities, and nationalities welcome
• All religions and beliefs respected
• All sexual orientations welcome
• All gender identities welcome
• No discrimination of any kind tolerated
• Everyone deserves love and respect

Love knows no boundaries.''',
              Icons.public,
              Colors.lightBlue,
            ),
            _buildSection(
              '16. Healthy Relationships',
              '''Signs of healthy connections:
• Mutual respect and trust
• Open and honest communication
• Equal partnership
• Support for each other\'s goals
• Healthy boundaries
• Feeling safe and valued

Red flags to watch for:
• Controlling behavior
• Excessive jealousy
• Isolation from friends/family
• Verbal or emotional abuse
• Pressure for money or favors
• Love bombing or manipulation''',
              Icons.health_and_safety,
              Colors.lightGreen,
            ),
            _buildSection(
              '17. Our Commitment',
              '''We are committed to:
• Reviewing all reports within 24 hours
• Removing harmful content promptly
• Banning abusive users
• Continuously improving safety features
• Protecting user privacy
• Supporting victims of harassment
• Cooperating with law enforcement

Your trust matters to us.''',
              Icons.shield,
              Colors.blueGrey,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, size: 32, color: Colors.blue),
                  const SizedBox(height: 12),
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you experience harassment, scams, or safety concerns:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo('Report via app', Icons.report_problem),
                  _buildContactInfo('Email: safety@indiralove.com', Icons.email),
                  _buildContactInfo('Emergency: Contact local authorities', Icons.local_police),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'These guidelines may be updated periodically. By using Indira Love, you agree to follow the current version of our Community Guidelines.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
