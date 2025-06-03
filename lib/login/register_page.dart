import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_hw/components/login_button.dart';
import 'package:math_hw/components/login_page_icons.dart';
import 'package:math_hw/components/login_text_field.dart';
import '../services/auth_services.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  bool isLoading = false;
  String? fieldError;

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
        return 'Patikrinkite interneto ryšį.';
      case 'invalid-credential':
        return 'Neteisingas el. paštas arba slaptažodis.';
      default:
        return 'Įvyko klaida. Bandykite dar kartą.';
    }
  }

  //sign user up method
  void signUserUp() async {
    if (!mounted) return;

    // Validate inputs
    if (nameController.text.trim().isEmpty) {
      setState(() { fieldError = 'Įveskite vardą'; });
      return;
    }

    if (surnameController.text.trim().isEmpty) {
      setState(() { fieldError = 'Įveskite pavardę'; });
      return;
    }

    if (emailController.text.trim().isEmpty) {
      setState(() { fieldError = 'Įveskite el. paštą'; });
      return;
    }

    if (passwordController.text.isEmpty) {
      setState(() { fieldError = 'Įveskite slaptažodį'; });
      return;
    }

    if (confirmPasswordController.text.isEmpty) {
      setState(() { fieldError = 'Pakartokite slaptažodį'; });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() { fieldError = 'Slaptažodžiai nesutampa'; });
      return;
    }

    setState(() {
      isLoading = true;
      fieldError = null;
    });

    try {
      final userCredential = await _authService.registerWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text,
        nameController.text.trim(),
        surnameController.text.trim(),
      );

      if (!mounted) return;

      // If we get here, registration was successful
      print('Registration successful for user: ${userCredential.user?.uid}');
      
      // Clear the text controllers
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      nameController.clear();
      surnameController.clear();
      
      setState(() { fieldError = null; });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registracija sėkminga!'),
          content: const Text('Patikrinkite el. paštą ir patvirtinkite paskyrą.'),
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
      setState(() { fieldError = getFirebaseAuthErrorMessage(e.code); });
    } catch (e) {
      if (!mounted) return;
      setState(() { fieldError = getFirebaseAuthErrorMessage(null); });
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
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
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
                    child: Image(
                      image: AssetImage('lib/login/loginPageFoto/Logo.png'),
                      width: 120,
                      height: 120,
                    ),
                  ),
                )
              ),
              Expanded(
                flex: 3,
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
                        const SizedBox(height: 30),
                        //name and surname
                        if (fieldError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 4.0),
                            child: Text(
                              fieldError!,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: LoginTextField(
                                  controller: nameController,
                                  hintText: 'Vardas',
                                  obscureText: false,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              const SizedBox(width: 1),
                              Expanded(
                                child: LoginTextField(
                                  controller: surnameController,
                                  hintText: 'Pavardė',
                                  obscureText: false,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

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

                        const SizedBox(height: 20),

                        //repeat password
                        LoginTextField(
                          controller: confirmPasswordController,
                          hintText: 'Pakartoti slaptažodį',
                          obscureText: true,
                        ),

                        const SizedBox(height: 20),

                        //log in button
                        LoginButton(
                          onTap: isLoading ? null : signUserUp,
                          text: isLoading ? 'Kraunama...' : 'Registruotis',
                        ),

                        const SizedBox(height: 30),

                        //"arba" button
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
                        const SizedBox(height: 30),

                        //google log in
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SquareTile(
                              onTap: () => _authService.signInWithGoogle(),
                              imagePath: 'lib/login/loginPageFoto/google.png'
                            ),
                          ],
                        ),
                        const SizedBox(height: 60),

                        //already have an account? login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Ar jau turite paskyrą?',
                              style: TextStyle(
                                color: Color(0x80000000),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: widget.onTap,
                              child: const Text(
                                'Prisijungti.',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              )
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
  void initState() {
    super.initState();
    nameController.addListener(() {
      if (fieldError != null) {
        setState(() { fieldError = null; });
      }
    });
    surnameController.addListener(() {
      if (fieldError != null) {
        setState(() { fieldError = null; });
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    surnameController.dispose();
    super.dispose();
  }
}
