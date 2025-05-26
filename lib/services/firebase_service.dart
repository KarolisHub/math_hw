import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      // Initialize App Check with retry
      print('Initializing App Check...');
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.debug,
            appleProvider: AppleProvider.debug,
          );
          print('App Check initialized successfully');
          break;
        } catch (e) {
          retryCount++;
          if (retryCount == maxRetries) {
            print('Failed to initialize App Check after $maxRetries attempts: $e');
            // Continue without App Check
            break;
          }
          print('Retrying App Check initialization (attempt $retryCount)...');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // Initialize Google Sign In
      print('Initializing Google Sign In...');
      try {
        await GoogleSignIn().signOut();
        print('Google Sign In initialized successfully');
      } catch (e) {
        print('Error initializing Google Sign In: $e');
        // Continue without Google Sign In
      }
      
      print('Additional Firebase services initialization completed');
    } catch (e, stackTrace) {
      print('Error initializing additional Firebase services: $e');
      print('Stack trace: $stackTrace');
    }
  }
} 