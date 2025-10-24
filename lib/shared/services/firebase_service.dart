import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Auth Methods
  static Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // // print( // Debug log removed'Starting signup for email: $email'); // Debug log removed
      
      // Create user with minimal approach
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // // print( // Debug log removed'User created with UID: ${credential.user?.uid}'); // Debug log removed
      
      if (credential.user != null) {
        // Don't update display name immediately to avoid type cast issues
        // // print( // Debug log removed'Signup successful, user UID: ${credential.user!.uid}'); // Debug log removed
        
        // Create user document in background (fire and forget)
        _createUserDocumentInBackground(
          uid: credential.user!.uid,
          email: email,
          displayName: displayName,
        );
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      // print( // Debug log removed'Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      // print( // Debug log removed'Unexpected error in signUpWithEmail: $e');
      // Check if user was actually created despite the error
      if (auth.currentUser != null) {
        // print( // Debug log removed'User was created despite error, returning success');
        // Return null but user is authenticated
        return null;
      }
      throw 'An unexpected error occurred. Please try again.';
    }
  }
  
  static void _createUserDocumentInBackground({
    required String uid,
    required String email,
    required String displayName,
  }) {
    // Run in background without waiting
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await createUserDocument(
          uid: uid,
          email: email,
          displayName: displayName,
        );
        // print( // Debug log removed'User document created successfully in background');
      } catch (e) {
        // print( // Debug log removed'Error creating user document in background: $e');
      }
    });
  }
  
  static Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // print( // Debug log removed'User signed in successfully: ${credential.user!.uid}');
        
        // Ensure user document exists
        try {
          final userDoc = await firestore.collection('users').doc(credential.user!.uid).get();
          if (!userDoc.exists) {
            // print( // Debug log removed'User document does not exist, creating...');
            await createUserDocument(
              uid: credential.user!.uid,
              email: email,
              displayName: credential.user!.displayName ?? 'User',
            );
          }
        } catch (e) {
          // print( // Debug log removed'Error checking/creating user document: $e');
          // Don't throw here, sign in is successful
        }
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      // print( // Debug log removed'Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      // print( // Debug log removed'Unexpected error in signInWithEmail: $e');
      throw 'An unexpected error occurred during sign in. Please try again.';
    }
  }
  
  static Future<void> signOut() async {
    await auth.signOut();
  }
  
  static Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // Firestore Methods
  static Future<void> createUserDocument({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    try {
      final userDoc = firestore.collection('users').doc(uid);
      
      // Check if document already exists
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        // print( // Debug log removed'User document already exists for uid: $uid');
        return;
      }
      
      final userData = <String, dynamic>{
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': _generateUsername(displayName),
        'bio': '',
        'profileImageUrl': '',
        'spotifyConnected': false,
        'totalSongsRated': 0,
        'totalAlbumsRated': 0,
        'totalReviews': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await userDoc.set(userData);
      // print( // Debug log removed'User document created successfully for uid: $uid');
    } catch (e) {
      // print( // Debug log removed'Error in createUserDocument: $e');
      // Don't rethrow to prevent signup failure
    }
  }
  
  static Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await firestore.collection('users').doc(uid).get();
  }
  
  static Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await firestore.collection('users').doc(uid).update(data);
  }
  
  static Future<void> createMusicRating({
    required String userId,
    required String spotifyId,
    required String type, // 'track' or 'album'
    required double rating,
    String? review,
    List<String>? tags,
  }) async {
    final ratingDoc = firestore.collection('music_ratings').doc();
    
    final ratingData = {
      'id': ratingDoc.id,
      'userId': userId,
      'spotifyId': spotifyId,
      'type': type,
      'rating': rating,
      'review': review ?? '',
      'tags': tags ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    await ratingDoc.set(ratingData);
    
    // Update user stats
    await _updateUserStats(userId, type);
  }
  
  static Future<QuerySnapshot> getUserRatings(String userId) async {
    return await firestore
        .collection('music_ratings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
  }
  
  static Future<QuerySnapshot> getRecentActivity(String userId) async {
    return await firestore
        .collection('music_ratings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
  }
  
  // Helper Methods
  static String _generateUsername(String displayName) {
    final base = displayName.toLowerCase().replaceAll(' ', '');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$base$timestamp';
  }
  
  static Future<void> _updateUserStats(String userId, String type) async {
    final userDoc = firestore.collection('users').doc(userId);
    
    if (type == 'track') {
      await userDoc.update({
        'totalSongsRated': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else if (type == 'album') {
      await userDoc.update({
        'totalAlbumsRated': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
  
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
