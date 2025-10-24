import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleSignInService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Save user data to Firestore
      await _saveUserToFirestore(userCredential.user);

      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Save user data to Firestore
  static Future<void> _saveUserToFirestore(User? user) async {
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userRef.get();

      if (!docSnapshot.exists) {
        // New user - create profile
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'User',
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          'emailVerified': user.emailVerified,
        });
      } else {
        // Existing user - update last login
        await userRef.update({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'photoURL': user.photoURL,
          'displayName': user.displayName ?? docSnapshot.data()?['displayName'] ?? 'User',
        });
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Google Sign-Out Error: $e');
    }
  }

  /// Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Get user stream
  static Stream<User?> get userChanges => _auth.userChanges();
}
