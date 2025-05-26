import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_hw/components/login_button.dart';
import 'package:math_hw/components/login_page_icons.dart';
import 'package:math_hw/components/login_text_field.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onTap;
  const LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  String getFirebaseAuthErrorMessage(String? code) {
    switch (code) {
      case 'invalid-email':
        return 'Neteisingas el. pašto formatas.';
      case 'user-disabled':
        return 'Ši paskyra yra išjungta.';
      case 'user-not-found':
        return 'Vartotojas nerastas. Bandykite prisijungti iš naujo.';
      case 'wrong-password':
        return 'Neteisingas el. paštas arba slaptažodis.';
      case 'email-already-in-use':
        return 'Šis el. paštas jau naudojamas.';
      case 'weak-password':
        return 'Slaptažodis per silpnas.';
      case 'too-many-requests':
        return 'Per daug bandymų. Bandykite vėliau.';
      case 'network-request-failed':
        return 'Nepavyko prisijungti prie interneto. Patikrinkite interneto ryšį.';
      default:
        return 'Įvyko klaida. Bandykite dar kartą.';
    }
  }

  //sign user in method
  void signUserIn() async {
    print('signUserIn called');
    if (!mounted) return;
    setState(() { isLoading = true; });
    try {
      await _authService.signInWithEmailAndPassword(
        emailController.text,
        passwordController.text,
      );
      if (!mounted) return;
      emailController.clear();
      passwordController.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sėkmingai prisijungėte!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Gerai'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      print('FirebaseAuthException: \\${e.code} - \\${e.message}');
      print('StackTrace: \\${stackTrace}');
      if (!mounted) return;
      showErrorMessage(getFirebaseAuthErrorMessage(e.code));
    } catch (e, stackTrace) {
      print('Other error: \\${e.toString()}');
      print('StackTrace: \\${stackTrace}');
      if (!mounted) return;
      showErrorMessage(getFirebaseAuthErrorMessage(null));
    } finally {
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }

  // Reset password method
  void resetPassword() async {
    if (!mounted) return;

    final email = emailController.text;
    if (email.isEmpty) {
      showErrorMessage('Įveskite el. paštą slaptažodžio atstatymui');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.resetPassword(email);
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Slaptažodžio atstatymas'),
          content: const Text('Slaptažodžio atstatymo nuoroda išsiųsta į jūsų el. paštą'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Gerai'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showErrorMessage(e.message ?? 'Įvyko klaida. Bandykite dar kartą.');
    } catch (e) {
      if (!mounted) return;
      showErrorMessage("Įvyko klaida. Bandykite dar kartą.");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //error message pop up to user
  void showErrorMessage(String message) {
    print('showErrorMessage called with: ' + message);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text(
            message,
            style: const TextStyle(color: Color(0xFFFFA500)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Gerai'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFA500),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: const Center(
                    child: Icon(
                      Icons.lock,
                      size: 150,
                    ),
                  ),
                )
              ),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)
                    ),
                    color: Color(0xFFADD8E6),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 50),
                        //email
                        LoginTextField(
                          controller: emailController,
                          hintText: 'El. paštas',
                          obscureText: false,
                        ),
                      
                        const SizedBox(height: 20),
                      
                        //password
                        LoginTextField(
                          controller: passwordController,
                          hintText: 'Slaptažodis',
                          obscureText: true,
                        ),
                      
                        //forgot password
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: resetPassword,
                                child: const Text(
                                  'Pamiršai slaptažodį?',
                                  style: TextStyle(
                                    color: Color(0xB3292D32),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                        const SizedBox(height: 20),
                      
                        //log in button
                        LoginButton(
                          onTap: isLoading ? null : signUserIn,
                          text: isLoading ? 'Kraunama...' : 'Prisijungti',
                        ),
                      
                        const SizedBox(height: 50),
                      
                        // 'or' text
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  thickness: 1.2,
                                  color: Color(0xFFFFA500),
                                ),
                              ),
                      
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 25.0),
                                child: Text(
                                  "arba",
                                  style: TextStyle(color: Color(0xB3292D32)),
                                ),
                              ),
                      
                              Expanded(
                                child: Divider(
                                  thickness: 1.2,
                                  color: Color(0xFFFFA500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 50),
                      
                        //google log in button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SquareTile(
                              onTap: () => _authService.signInWithGoogle(),
                              imagePath: 'lib/login/loginPageFoto/google.png'
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),
                      
                        //new user? register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Naujas vartotojas?',
                              style: TextStyle(
                                color: Color(0x80000000),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: widget.onTap,
                              child: const Text(
                                'Registruotis.',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              )
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              )
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFA500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
