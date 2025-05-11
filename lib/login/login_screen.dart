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
  //text editing controller
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  //sign user in method
  void signUserIn()async{

    //show loading circle
    showDialog(
        context: context,
        builder: (context){
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
    );

    //try sign in

    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );


      Navigator.pop(context);

    } on FirebaseAuthException catch (e){
      Navigator.pop(context);

      showErrorMessage(e.code);
    }
  }

  //error message pop up to user
  void showErrorMessage(String message){
    showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: Text(
                message,
              style: TextStyle(color: Color(0xFFFFA500)),

            ),
          );
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFA500),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: Container(
                color: Colors.transparent,
                child: //logo
                const Center(
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
                decoration: BoxDecoration(
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
                  
                      //pamiršau slaptažodį
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Pamiršai slaptažodį?',
                              style: TextStyle(color: Color(0xB3292D32)),
                            ),
                          ],
                        ),
                      ),
                  
                      const SizedBox(height: 20),
                  
                      //prisijungti mygtukas
                  
                      LoginButton(
                        onTap: signUserIn,
                        text: 'Prisijungti',
                      ),
                  
                      const SizedBox(height: 50),
                  
                      //arba
                  
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                thickness: 1.2,
                                color: Color(0xFFFFA500),
                              ),
                            ),
                  
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
                  
                      //google ir apple prisijungimas
                  
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //google button
                          SquareTile(
                              onTap: () => AuthService().signInWithGoogle(),
                              imagePath: 'lib/login/loginPageFoto/google.png'
                          ),
                  
                          //const SizedBox(width: 20),
                  
                          //apple button
                          /*
                          SquareTile(
                              onTap: (){

                              },
                              imagePath: 'lib/login/loginPageFoto/apple.png'
                          )

                           */
                  
                        ],
                      ),
                      const SizedBox(height: 50),
                  
                      //naujas vartotojas? registruotis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              'Naujas vartotojas?',
                            style: TextStyle(
                              color: Color(0x80000000),
                  
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                              onTap: widget.onTap,
                              child: const Text(
                                  'Registruotis.'
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
    );
  }
}
