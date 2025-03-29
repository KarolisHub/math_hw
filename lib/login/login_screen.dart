import 'package:flutter/material.dart';
import 'package:math_hw/components/login_button.dart';
import 'package:math_hw/components/login_page_icons.dart';
import 'package:math_hw/components/login_text_field.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  //text editing controller
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  //sign user in method
  void signUserIn(){}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFA500),
      body: Column(
        children: [
          Expanded(
              child: Container(
                color: Colors.transparent,
                child: //logo
                Center(
                  child: const Icon(
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
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    //el. paštas
                    LoginTextField(
                      controller: usernameController,
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
                    ),

                    const SizedBox(height: 80),

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
                    const SizedBox(height: 60),

                    //google ir apple prisijungimas

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        //google button
                        SquareTile(imagePath: 'lib/login/loginPageFoto/google.png'),

                        const SizedBox(width: 20),

                        //apple button
                        SquareTile(imagePath: 'lib/login/loginPageFoto/apple.png')
                        
                      ],
                    ),
                    const SizedBox(height: 60),

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
                        Text('Registruotis.'),
                      ],
                    )

                  ],

                ),
              )
          )
        ],
      ),
    );
  }
}
