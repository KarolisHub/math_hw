import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:math_hw/login/auth_page.dart';
import 'package:math_hw/services/firebase_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase only if it hasn't been initialized yet
    if (Firebase.apps.isEmpty) {
      print('Initializing Firebase core...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase core initialized successfully');
    } else {
      print('Firebase core already initialized, using existing instance');
    }
    
    // Initialize additional services
    print('Initializing additional Firebase services...');
    await FirebaseService.initialize();
    print('All services initialized successfully');
  } catch (e, stackTrace) {
    print('Error during initialization: $e');
    print('Stack trace: $stackTrace');
    // Continue running the app even if initialization fails
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
    );
  }
}