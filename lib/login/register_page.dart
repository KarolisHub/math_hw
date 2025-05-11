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
  //text editing controller
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  //sign user in method
  void signUserUp()async{

    //show loading circle
    showDialog(
        context: context,
        builder: (context){
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
    );

    //try sign user up

    try{
      //patikrinti ar slaptažodis yra patvirtintas
      if(passwordController.text == confirmPasswordController.text){
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      }else{
        //blogai pakartotas slaptažodis
        showErrorMessage("Slaptažodis nesutampa");
      }


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
                Center(
                  child: const Icon(
                    Icons.lock,
                    size: 120,
                  ),
                ),
              )
          ),
          Expanded(
              flex: 3,
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

                          //SizedBox(width: 20),

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
                            'Ar jau turite paskyrą?',
                            style: TextStyle(
                              color: Color(0x80000000),

                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                              onTap: widget.onTap,
                              child: Text(
                                  'Prisijungti.'
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
