import 'package:firebase_auth/firebase_auth.dart';
// Temporarily disabled due to AppCheckCore dependency conflict
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Connect to the nam5 database instance where all users are stored
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Temporarily disabled due to AppCheckCore dependency conflict
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (result.user != null) {
        await _createUserProfile(result.user!);
      }

      return result;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Temporarily disabled due to AppCheckCore dependency conflict
  // Future<UserCredential?> signInWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) return null;
  //
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final result = await _auth.signInWithCredential(credential);
  //
  //     // Create user profile in Firestore if it doesn't exist
  //     await _createUserProfile(result.user!);
  //
  //     return result;
  //   } catch (e) {
  //     throw _handleAuthError(e);
  //   }
  // }

  Future<void> signOut() async {
    // Temporarily disabled due to AppCheckCore dependency conflict
    // await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _createUserProfile(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);

    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'isVerified': false,
      'profileComplete': false,
      'subscriptionTier': 'free',
      'subscriptionExpiry': null,
      'bio': '',
      'age': null,
      'gender': '',
      'location': '',
      'interests': <String>[],
      'languages': <String>[],
      'photos': <String>[],
      'isOnline': true,
      'settings': {
        'notifications': true,
        'locationSharing': true,
        'showOnlineStatus': true,
        'allowMessages': true,
      },
    };

    await userDoc.set(userData, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser!.uid).update({
      ...data,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<DocumentSnapshot> getUserProfileOnce(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }

  Exception _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          // Generic message to prevent email enumeration attacks
          return Exception('Invalid email or password. Please try again.');
        case 'email-already-in-use':
          return Exception('Unable to create account. Please try a different email or sign in.');
        case 'weak-password':
          return Exception('Password is too weak. Use at least 8 characters with uppercase, lowercase, and numbers.');
        case 'invalid-email':
          return Exception('Please enter a valid email address.');
        case 'too-many-requests':
          return Exception('Too many attempts. Please wait a moment and try again.');
        default:
          return Exception('Authentication failed. Please try again.');
      }
    }
    return Exception('Something went wrong. Please try again.');
  }
}
