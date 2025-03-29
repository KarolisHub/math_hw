import 'package:flutter/material.dart';
import 'package:math_hw/components/login_button.dart';
import 'package:math_hw/components/login_text_field.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();


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

                    LoginButton(),

                    //arba

                    //google ir apple prisijungimas

                    //naujas vartotojas? registruotis
                  ],

                ),
              )
          )
        ],
      ),
    );
  }
}
