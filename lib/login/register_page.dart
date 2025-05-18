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

  //sign user up method
  void signUserUp() async {
    if (!mounted) return;

    // Validate inputs
    if (nameController.text.trim().isEmpty) {
      showErrorMessage('Įveskite vardą');
      return;
    }

    if (surnameController.text.trim().isEmpty) {
      showErrorMessage('Įveskite pavardę');
      return;
    }

    if (emailController.text.trim().isEmpty) {
      showErrorMessage('Įveskite el. paštą');
      return;
    }

    if (passwordController.text.isEmpty) {
      showErrorMessage('Įveskite slaptažodį');
      return;
    }

    if (confirmPasswordController.text.isEmpty) {
      showErrorMessage('Pakartokite slaptažodį');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showErrorMessage('Slaptažodžiai nesutampa');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text,
        nameController.text.trim(),
        surnameController.text.trim(),
      );

      if (!mounted) return;
      
      // Clear the text controllers
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      nameController.clear();
      surnameController.clear();
      
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
                    child: Icon(
                      Icons.lock,
                      size: 120,
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
                        //vardas ir pavardė vienoje eilutėje
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

                        //el. paštas
                        LoginTextField(
                          controller: emailController,
                          hintText: 'El. paštas',
                          obscureText: false,
                        ),

                        const SizedBox(height: 20),

                        //slaptažodis
                        LoginTextField(
                          controller: passwordController,
                          hintText: 'Slaptažodis',
                          obscureText: true,
                        ),

                        const SizedBox(height: 20),

                        //pakartoti slaptažodį
                        LoginTextField(
                          controller: confirmPasswordController,
                          hintText: 'Pakartoti slaptažodį',
                          obscureText: true,
                        ),

                        const SizedBox(height: 20),

                        //prisijungti mygtukas
                        LoginButton(
                          onTap: signUserUp,
                          text: 'Registruotis',
                        ),

                        const SizedBox(height: 30),

                        //arba
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  thickness: 1.2,
                                  color: Color(0xFFFFA500),
                                ),
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 25.0),
                                child: Text(
                                  "arba",
                                  style: TextStyle(color: Color(0xB3292D32)),
                                ),
                              ),

                              const Expanded(
                                child: Divider(
                                  thickness: 1.2,
                                  color: Color(0xFFFFA500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        //google prisijungimas
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

                        //naujas vartotojas? registruotis
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
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    surnameController.dispose();
    super.dispose();
  }
}
