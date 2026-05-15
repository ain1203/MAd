import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  // Singleton pattern for centralized access
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Web Client ID from google-services.json is essential for Android tokens
    serverClientId: '1086855213708-akihadr1rd5oa645n86fbsem7cum3kth.apps.googleusercontent.com',
  );
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── STREAMS & GETTERS ───
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── AUTHENTICATION METHODS ───

  /// Signs up a new user and automatically logs them in
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      debugPrint('AuthService: Registering $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Update Firebase profile display name
        await credential.user!.updateDisplayName(fullName);
        
        // Save additional user metadata to Firestore
        await saveUserToFirestore(
          uid: credential.user!.uid,
          email: email.trim(),
          fullName: fullName,
          phone: phone,
          photoURL: credential.user!.photoURL,
        );
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AuthService: Unexpected Sign-Up Error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Authenticates an existing user
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Logging in $email');
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AuthService: Unexpected Login Error: $e');
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Comprehensive Google Sign-In (handles both new and existing users)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('AuthService: Initiating Google Flow');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('AuthService: Google Sign-In aborted by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint('AuthService: Google Success for ${userCredential.user!.email}');
        // Sync with Firestore
        await saveUserToFirestore(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          fullName: userCredential.user!.displayName ?? 'Google User',
          phone: userCredential.user!.phoneNumber ?? '',
          photoURL: userCredential.user!.photoURL,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('AuthService: Google Sign-In Fatal Error: $e');
      throw 'Google authentication failed.';
    }
  }

  /// Sends password reset email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email.';
    }
  }

  /// Proper Sign-Out clearing all sessions
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      debugPrint('AuthService: All sessions cleared');
    } catch (e) {
      debugPrint('AuthService: Sign-Out Error: $e');
      throw 'Logout failed.';
    }
  }

  // ─── DATA PERSISTENCE ───

  Future<void> saveUserToFirestore({
    required String uid,
    required String email,
    required String fullName,
    required String phone,
    String? photoURL,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'photoURL': photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AuthService: Firestore Sync Error: $e');
    }
  }

  // ─── EXCEPTION MAPPING ───

  String _handleAuthException(FirebaseAuthException e) {
    debugPrint('AuthService: Error Code [${e.code}]');
    switch (e.code) {
      case 'user-not-found':
        return 'No account found, please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
