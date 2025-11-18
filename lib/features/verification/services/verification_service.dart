import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Verify selfie using ML Kit Face Detection
  Future<Map<String, dynamic>> verifySelfie(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableLandmarks: true,
          enableClassification: true,
          enableTracking: false,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      // Validation checks
      if (faces.isEmpty) {
        return {
          'isValid': false,
          'error': 'No face detected. Please ensure your face is clearly visible.',
        };
      }

      if (faces.length > 1) {
        return {
          'isValid': false,
          'error': 'Multiple faces detected. Only one person should be in the photo.',
        };
      }

      final face = faces.first;

      // Check face quality
      final headEulerAngleY = face.headEulerAngleY ?? 0;
      final headEulerAngleZ = face.headEulerAngleZ ?? 0;

      // Face should not be too tilted
      if (headEulerAngleY!.abs() > 15) {
        return {
          'isValid': false,
          'error': 'Please face the camera directly. Your head is turned too much to the side.',
        };
      }

      if (headEulerAngleZ!.abs() > 15) {
        return {
          'isValid': false,
          'error': 'Please keep your head straight. Your head is tilted too much.',
        };
      }

      // Check if eyes are open
      final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 0;

      if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
        return {
          'isValid': false,
          'error': 'Please keep your eyes open for verification.',
        };
      }

      // Check if smiling (optional, for better photos)
      final smilingProbability = face.smilingProbability ?? 0;

      return {
        'isValid': true,
        'faceDetected': true,
        'quality': _calculateFaceQuality(
          headEulerAngleY.abs(),
          headEulerAngleZ.abs(),
          leftEyeOpen,
          rightEyeOpen,
          smilingProbability,
        ),
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Error processing image: $e',
      };
    }
  }

  double _calculateFaceQuality(
    double angleY,
    double angleZ,
    double leftEyeOpen,
    double rightEyeOpen,
    double smile,
  ) {
    // Quality score from 0 to 100
    double score = 100;

    // Penalize for head tilt
    score -= angleY * 2;
    score -= angleZ * 2;

    // Reward for eyes open
    score += (leftEyeOpen + rightEyeOpen) * 10;

    // Reward for smiling
    score += smile * 10;

    return score.clamp(0, 100);
  }

  // Upload verification selfie and update user status
  Future<bool> submitVerificationSelfie(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Upload to Firebase Storage
      final fileName = '${user.uid}_verification_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref('verification_selfies/$fileName');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'verificationSelfie': url,
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error submitting verification selfie: $e');
      return false;
    }
  }

  // Get verification status
  Future<String> getVerificationStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['verificationStatus'] ?? 'none';
    } catch (e) {
      return 'none';
    }
  }

  // Admin: Approve verification
  Future<void> approveVerification(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'verificationStatus': 'approved',
      'isVerified': true,
      'verificationApprovedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin: Reject verification
  Future<void> rejectVerification(String userId, String reason) async {
    await _firestore.collection('users').doc(userId).update({
      'verificationStatus': 'rejected',
      'verificationRejectedReason': reason,
      'verificationRejectedAt': FieldValue.serverTimestamp(),
    });
  }

  // Stream verification status
  Stream<String> watchVerificationStatus(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map(
          (doc) => doc.data()?['verificationStatus'] as String? ?? 'none',
        );
  }

  // Submit full verification with ID documents
  Future<bool> submitFullVerification({
    required File selfie,
    required File idFront,
    File? idBack,
    required String verificationType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Upload all documents
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload selfie
      final selfieRef = _storage.ref().child(
        'verification/${user.uid}/selfie_$timestamp.jpg',
      );
      await selfieRef.putFile(selfie);
      final selfieUrl = await selfieRef.getDownloadURL();

      // Upload ID front
      final idFrontRef = _storage.ref().child(
        'verification/${user.uid}/id_front_$timestamp.jpg',
      );
      await idFrontRef.putFile(idFront);
      final idFrontUrl = await idFrontRef.getDownloadURL();

      // Upload ID back if provided
      String? idBackUrl;
      if (idBack != null) {
        final idBackRef = _storage.ref().child(
          'verification/${user.uid}/id_back_$timestamp.jpg',
        );
        await idBackRef.putFile(idBack);
        idBackUrl = await idBackRef.getDownloadURL();
      }

      // Create verification request
      await _firestore.collection('verification_requests').add({
        'userId': user.uid,
        'verificationType': verificationType,
        'selfieUrl': selfieUrl,
        'idFrontUrl': idFrontUrl,
        'idBackUrl': idBackUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'deviceInfo': 'Flutter App',
          'appVersion': '1.0.0',
        },
      });

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'verificationType': verificationType,
      });

      return true;
    } catch (e) {
      print('Error submitting full verification: $e');
      return false;
    }
  }
}
