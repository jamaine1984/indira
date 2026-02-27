import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';
import 'package:share_plus/share_plus.dart';

class FamilySharingService {
  static final FamilySharingService _instance = FamilySharingService._();
  factory FamilySharingService() => _instance;
  FamilySharingService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Generate a shareable profile card URL for family review
  Future<String> generateShareableLink(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    // Get the target user's clean profile data
    final doc = await _firestore.collection('users').doc(targetUserId).get();
    if (!doc.exists) throw Exception('User not found');

    // Create a share record in Firestore for tracking
    final shareDoc = await _firestore.collection('family_shares').add({
      'sharedBy': user.uid,
      'profileUserId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'viewed': false,
      'familyApproval': null, // null = pending, true = approved, false = rejected
    });

    logger.info('Family share created: ${shareDoc.id}');
    return shareDoc.id;
  }

  /// Build a clean text profile summary for sharing
  Future<String> buildProfileSummary(String targetUserId) async {
    final doc = await _firestore.collection('users').doc(targetUserId).get();
    if (!doc.exists) return 'Profile not available';

    final data = doc.data()!;
    final name = data['displayName'] ?? 'Unknown';
    final age = data['age'] ?? '';
    final bio = data['bio'] ?? '';
    final cultural = data['culturalPreferences'] as Map<String, dynamic>? ?? {};

    final buffer = StringBuffer();
    buffer.writeln('Indira Love - Profile Card');
    buffer.writeln('${'=' * 30}');
    buffer.writeln('Name: $name${age != '' ? ', $age' : ''}');
    if (bio.isNotEmpty) buffer.writeln('About: $bio');
    buffer.writeln();

    if (cultural.isNotEmpty) {
      buffer.writeln('Background:');
      if (cultural['religion'] != null) buffer.writeln('  Religion: ${cultural['religion']}');
      if (cultural['community'] != null) buffer.writeln('  Community: ${cultural['community']}');
      if (cultural['motherTongue'] != null) buffer.writeln('  Mother Tongue: ${cultural['motherTongue']}');
      if (cultural['educationLevel'] != null) buffer.writeln('  Education: ${cultural['educationLevel']}');
      if (cultural['profession'] != null) buffer.writeln('  Profession: ${cultural['profession']}');
      if (cultural['dietType'] != null) buffer.writeln('  Diet: ${cultural['dietType']}');
      if (cultural['familyType'] != null) buffer.writeln('  Family: ${cultural['familyType']}');
      if (cultural['familyValues'] != null) buffer.writeln('  Values: ${cultural['familyValues']}');
      if (cultural['marriageTimeline'] != null) buffer.writeln('  Marriage Timeline: ${cultural['marriageTimeline']}');
      if (cultural['state'] != null) buffer.writeln('  From: ${cultural['state']}');
      if (cultural['manglik'] != null) buffer.writeln('  Manglik: ${cultural['manglik'] == true ? 'Yes' : 'No'}');
    }

    buffer.writeln();
    buffer.writeln('Shared via Indira Love - The South Asian Dating App');

    return buffer.toString();
  }

  /// Share profile with family via system share sheet (WhatsApp, email, etc.)
  Future<void> shareWithFamily(String targetUserId) async {
    final summary = await buildProfileSummary(targetUserId);
    await generateShareableLink(targetUserId);
    await SharePlus.instance.share(ShareParams(text: summary));
  }

  /// Get profiles shared with family by current user
  Future<List<Map<String, dynamic>>> getSharedProfiles() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snap = await _firestore
        .collection('family_shares')
        .where('sharedBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
