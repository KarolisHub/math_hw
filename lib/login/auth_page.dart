import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:math_hw/Menu/menu_screen.dart';
import 'package:math_hw/login/login_or_register.dart';
import 'package:math_hw/login/login_screen.dart';

import '../Home/camera_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          //user is logged in
          if(snapshot.hasData){
            //return GoogleVisionExample();
            //return CameraOCR();
            return MenuScreen();
          }
          // user is not logged in
          else{
            return LoginOrRegister();
          }
        },
      ),
    );
  }
}
