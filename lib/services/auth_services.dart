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

      print('Creating user with email: $email');
      
      // First create the user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Nepavyko sukurti vartotojo',
        );
      }

      print('User created successfully with UID: ${userCredential.user?.uid}');

      // Then update the user profile
      try {
        await userCredential.user?.updateDisplayName('$name $surname');
        print('User profile updated successfully');
      } catch (e) {
        print('Error updating user profile: $e');
        // Continue even if profile update fails
      }

      // Store user data in Firestore
      try {
        print('Attempting to create user document in Firestore');
        final userData = {
          'vardas': name.trim(),
          'pavarde': surname.trim(),
          'el_pastas': email,
          'role': 'mokinys',
          'sukurimo_data': FieldValue.serverTimestamp(),
          'paskutinio_prisijungimo_data': FieldValue.serverTimestamp(),
          'aktyvus': true,
        };
        
        await _firestore
            .collection('vartotojai')
            .doc(userCredential.user!.uid)
            .set(userData);
            
        print('User document created successfully in Firestore');
      } catch (e) {
        print('Error creating user document in Firestore: $e');
        // If Firestore fails, we should still return the user credential
        // as the user is already created in Firebase Auth
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw FirebaseAuthException(
        code: e.code,
        message: getErrorMessage(e.code),
      );
    } catch (e, stackTrace) {
      print('Unexpected error during registration: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process');
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        print('Google Sign In was cancelled by user');
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google prisijungimas atšauktas',
        );
      }

      print('Getting Google authentication');
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      print('Signing in with Google credential');
      final userCredential = await _auth.signInWithCredential(credential);
      print('Successfully signed in with Google. UID: ${userCredential.user?.uid}');

      // Store user data in Firestore
      if (userCredential.user != null) {
        try {
          print('Attempting to create/update user document in Firestore');
          final displayName = userCredential.user!.displayName ?? 'Nežinomas vartotojas';
          final nameParts = displayName.split(' ');
          final name = nameParts.isNotEmpty ? nameParts.first : 'Nežinomas';
          final surname = nameParts.length > 1 ? nameParts.last : 'Vartotojas';

          await _firestore.collection('vartotojai').doc(userCredential.user!.uid).set({
            'vardas': name,
            'pavarde': surname,
            'el_pastas': userCredential.user!.email,
            'role': 'mokinys',
            'sukurimo_data': FieldValue.serverTimestamp(),
            'paskutinio_prisijungimo_data': FieldValue.serverTimestamp(),
            'aktyvus': true,
          }, SetOptions(merge: true));
          print('User document created/updated successfully in Firestore');
        } catch (e) {
          print('Error creating/updating user document in Firestore: $e');
          rethrow;
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during Google Sign In: ${e.code} - ${e.message}');
      throw FirebaseAuthException(
        code: e.code,
        message: getErrorMessage(e.code),
      );
    } catch (e) {
      print('Unexpected error during Google Sign In: $e');
      rethrow;
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