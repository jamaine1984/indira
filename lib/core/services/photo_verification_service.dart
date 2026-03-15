import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:indira_love/core/services/logger_service.dart';

/// Service for photo-based identity verification.
///
/// Users submit a selfie that is uploaded to Firebase Storage and recorded
/// in their Firestore user document. For the MVP, verification is
/// auto-approved upon successful upload. When server-side ML face
/// comparison is available, the flow should be changed to set status
/// to 'pending' and let a Cloud Function approve or reject.
class PhotoVerificationService {
  static final PhotoVerificationService _instance =
      PhotoVerificationService._internal();
  factory PhotoVerificationService() => _instance;
  PhotoVerificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a verification selfie.
  ///
  /// Uploads [imagePath] to `verification_selfies/{userId}.jpg` in
  /// Firebase Storage, then updates the user document with verification
  /// fields. MVP behaviour auto-approves the submission.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> submitVerification(String imagePath) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        logger.error('submitVerification called with no authenticated user',
            tag: 'PhotoVerificationService');
        return false;
      }

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        logger.error('Verification image file does not exist: $imagePath',
            tag: 'PhotoVerificationService');
        return false;
      }

      // Upload to Firebase Storage at verification_selfies/{userId}.jpg
      final ref = _storage.ref('verification_selfies/${user.uid}.jpg');
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // MVP: Auto-approve verification.
      // When ML comparison is implemented, set verificationStatus to
      // 'pending' here and let the Cloud Function update to 'verified'
      // after the selfie passes face comparison against profile photos.
      await _firestore.collection('users').doc(user.uid).update({
        'verificationSelfie': downloadUrl,
        'isPhotoVerified': true,
        'verificationStatus': 'verified',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'verificationApprovedAt': FieldValue.serverTimestamp(),
        'isVerified': true,
      });

      logger.info('Photo verification auto-approved for user ${user.uid}',
          tag: 'PhotoVerificationService');
      return true;
    } catch (e, stack) {
      logger.error('Error in submitVerification',
          error: e, stackTrace: stack, tag: 'PhotoVerificationService');
      return false;
    }
  }

  /// Get the current verification status for [userId].
  ///
  /// Returns one of: 'none', 'pending', 'verified', 'rejected'.
  Future<String> getVerificationStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 'none';
      return doc.data()?['verificationStatus'] as String? ?? 'none';
    } catch (e) {
      logger.error('Error getting verification status for $userId',
          error: e, tag: 'PhotoVerificationService');
      return 'none';
    }
  }

  /// Stream the verification status for [userId] in real time.
  Stream<String> watchVerificationStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map(
          (doc) => doc.data()?['verificationStatus'] as String? ?? 'none',
        );
  }

  /// Check whether [userId] has a photo-verified badge.
  Future<bool> isPhotoVerified(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;
      return doc.data()?['isPhotoVerified'] == true;
    } catch (e) {
      logger.error('Error checking isPhotoVerified for $userId',
          error: e, tag: 'PhotoVerificationService');
      return false;
    }
  }
}
