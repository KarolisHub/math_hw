import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Password validation
  bool isPasswordValid(String password) {
    return password.length >= 8 &&
           password.contains(RegExp(r'[A-Z]')) &&
           password.contains(RegExp(r'[a-z]')) &&
           password.contains(RegExp(r'[0-9]'));
  }

  // Email validation
  bool isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Get user-friendly error message
  String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Vartotojas su tokiu el. paštu nerastas';
      case 'wrong-password':
        return 'Neteisingas slaptažodis';
      case 'email-already-in-use':
        return 'Šis el. paštas jau naudojamas';
      case 'weak-password':
        return 'Slaptažodis per silpnas';
      case 'invalid-email':
        return 'Neteisingas el. pašto formatas';
      case 'network-request-failed':
        return 'Nepavyko prisijungti prie tinklo';
      default:
        return 'Įvyko klaida. Bandykite dar kartą';
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      if (!isEmailValid(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Neteisingas el. pašto formatas',
        );
      }

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: getErrorMessage(e.code),
      );
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String surname,
  ) async {
    try {
      if (!isEmailValid(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Neteisingas el. pašto formatas',
        );
      }

      if (!isPasswordValid(password)) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Slaptažodis turi būti bent 8 simbolių ilgio ir turėti didžiąją raidę, mažąją raidę ir skaičių',
        );
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name.trim(),
          'surname': surname.trim(),
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: getErrorMessage(e.code),
      );
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google prisijungimas atšauktas',
        );
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Store user data in Firestore
      if (userCredential.user != null) {
        final displayName = userCredential.user!.displayName ?? 'Nežinomas vartotojas';
        final nameParts = displayName.split(' ');
        final name = nameParts.isNotEmpty ? nameParts.first : 'Nežinomas';
        final surname = nameParts.length > 1 ? nameParts.last : 'Vartotojas';

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'surname': surname,
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: getErrorMessage(e.code),
      );
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      if (!isEmailValid(email)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Neteisingas el. pašto formatas',
        );
      }

      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: getErrorMessage(e.code),
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}