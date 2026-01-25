import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

class ScamDetectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Suspicious keywords for message scam detection
  static const List<String> scamKeywords = [
    'bitcoin',
    'crypto',
    'invest',
    'investment',
    'sugar daddy',
    'sugar baby',
    'cash app',
    'cashapp',
    'venmo',
    'paypal',
    'wire transfer',
    'bank account',
    'send money',
    'western union',
    'gift card',
    'itunes',
    'google play',
    'steam card',
    'verify account',
    'suspended',
    'confirm identity',
    'click this link',
    'urgent',
    'emergency money',
    'financial help',
    'loan',
    'debt',
    'inheritance',
    'lawyer',
    'customs fee',
    'shipping fee',
    'release funds',
    'money order',
    'check deposit',
    'wire money',
    'cash transfer',
  ];

  // Check if message contains scam indicators
  Future<Map<String, dynamic>> checkMessage(String message) async {
    final lowerMessage = message.toLowerCase();
    int suspicionScore = 0;
    List<String> matchedKeywords = [];

    // Check for scam keywords
    for (final keyword in scamKeywords) {
      if (lowerMessage.contains(keyword)) {
        suspicionScore += 20;
        matchedKeywords.add(keyword);
      }
    }

    // Check for URLs
    final urlRegex = RegExp(
      r'https?://[^\s]+|www\.[^\s]+',
      caseSensitive: false,
    );
    if (urlRegex.hasMatch(message)) {
      suspicionScore += 15;
      matchedKeywords.add('URL link');
    }

    // Check for phone numbers
    final phoneRegex = RegExp(r'\+?\d{10,}|\d{3}[-.\s]?\d{3}[-.\s]?\d{4}');
    if (phoneRegex.hasMatch(message)) {
      suspicionScore += 10;
      matchedKeywords.add('phone number');
    }

    // Check for email addresses (uncommon in dating chat)
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    if (emailRegex.hasMatch(message)) {
      suspicionScore += 10;
      matchedKeywords.add('email address');
    }

    // Check for dollar amounts
    final moneyRegex = RegExp(r'\$\d+|USD\s*\d+|EUR\s*\d+');
    if (moneyRegex.hasMatch(message)) {
      suspicionScore += 10;
      matchedKeywords.add('money amount');
    }

    // Check for ALL CAPS (scammers often use this)
    if (message.length > 20 && message == message.toUpperCase()) {
      suspicionScore += 5;
      matchedKeywords.add('all caps');
    }

    // Log if suspicious
    if (suspicionScore > 20) {
      await _logScamAttempt(message, matchedKeywords, suspicionScore);
    }

    return {
      'isScam': suspicionScore > 30,
      'suspicionScore': suspicionScore,
      'matchedKeywords': matchedKeywords,
      'shouldWarn': suspicionScore > 20 && suspicionScore <= 30,
      'shouldBlock': suspicionScore > 30,
    };
  }

  // Check if profile has scam indicators
  Future<Map<String, dynamic>> checkProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    int suspicionScore = 0;
    List<String> reasons = [];

    // No bio or very short bio
    final bio = userData['bio'] as String? ?? '';
    if (bio.isEmpty) {
      suspicionScore += 10;
      reasons.add('No bio');
    } else if (bio.length < 10) {
      suspicionScore += 5;
      reasons.add('Very short bio');
    }

    // Bio contains scam keywords
    final bioLower = bio.toLowerCase();
    for (final keyword in scamKeywords) {
      if (bioLower.contains(keyword)) {
        suspicionScore += 15;
        reasons.add('Bio contains suspicious keyword: $keyword');
      }
    }

    // Single photo or no photos
    final photos = (userData['photos'] as List<dynamic>?)?.length ?? 0;
    if (photos == 0) {
      suspicionScore += 30;
      reasons.add('No profile photos');
    } else if (photos == 1) {
      suspicionScore += 15;
      reasons.add('Only one profile photo');
    }

    // Profile created very recently (< 24h)
    final createdAt = userData['createdAt'] as Timestamp?;
    if (createdAt != null) {
      final hoursSinceCreated =
          DateTime.now().difference(createdAt.toDate()).inHours;
      if (hoursSinceCreated < 24) {
        suspicionScore += 20;
        reasons.add('Account created less than 24 hours ago');
      }
    }

    // Multiple reports
    final reportCount = userData['reportCount'] as int? ?? 0;
    if (reportCount > 0) {
      suspicionScore += reportCount * 15;
      reasons.add('Has $reportCount reports');
    }

    // No subscription (scammers rarely pay)
    final subscriptionTier = userData['subscriptionTier'] as String? ?? 'free';
    if (subscriptionTier == 'free') {
      final createdAt = userData['createdAt'] as Timestamp?;
      if (createdAt != null) {
        final daysSinceCreated =
            DateTime.now().difference(createdAt.toDate()).inDays;
        if (daysSinceCreated > 30) {
          // Old free account, more suspicious
          suspicionScore += 5;
        }
      }
    }

    // Age seems fake (too perfect or unrealistic)
    final age = userData['age'] as int? ?? 0;
    if (age < 18 || age > 80) {
      suspicionScore += 20;
      reasons.add('Suspicious age: $age');
    }

    // Generic or suspicious name patterns
    final displayName = (userData['displayName'] as String? ?? '').toLowerCase();
    if (displayName.contains('admin') ||
        displayName.contains('support') ||
        displayName.contains('official')) {
      suspicionScore += 25;
      reasons.add('Suspicious name pattern');
    }

    return {
      'isScammer': suspicionScore > 50,
      'suspicionScore': suspicionScore,
      'reasons': reasons,
      'shouldFlag': suspicionScore > 30,
    };
  }

  // Log scam attempt
  Future<void> _logScamAttempt(
    String message,
    List<String> keywords,
    int score,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('scam_logs').add({
        'userId': user.uid,
        'message': message,
        'matchedKeywords': keywords,
        'suspicionScore': score,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user's scam attempt count
      await _firestore.collection('users').doc(user.uid).update({
        'scamAttempts': FieldValue.increment(1),
        'lastScamAttempt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      logger.logSecurityEvent('Failed to log scam attempt', details: {'error': e.toString()});
    }
  }

  // Auto-report suspicious profile
  Future<void> autoReportProfile(
    String reportedUserId,
    String reason,
    int suspicionScore,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('reports').add({
        'reporterId': 'system',
        'reportedUserId': reportedUserId,
        'reason': 'Scam Detection',
        'description': 'Auto-detected: $reason (Score: $suspicionScore)',
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'isAutoGenerated': true,
      });
    } catch (e) {
      logger.logSecurityEvent('Failed to auto-report suspicious profile', details: {'error': e.toString()});
    }
  }

  // Get warning message for user
  String getWarningMessage(List<String> keywords) {
    if (keywords.isEmpty) {
      return 'This message may contain suspicious content.';
    }

    return 'Warning: This message contains suspicious content (${keywords.take(3).join(', ')}). '
        'Never send money to people you haven\'t met in person.';
  }

  // Check if user should be auto-blocked
  Future<bool> shouldAutoBlock(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final scamAttempts = doc.data()?['scamAttempts'] as int? ?? 0;

      // Auto-block after 3 scam attempts
      return scamAttempts >= 3;
    } catch (e) {
      return false;
    }
  }

  // Stream scam logs for admin
  Stream<QuerySnapshot> getScamLogs() {
    return _firestore
        .collection('scam_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }
}
