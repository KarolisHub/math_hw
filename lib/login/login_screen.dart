import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFA500),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: //logo
                  Center(
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
                  child: Column(
                    children: [
        
                      //el. paštas
        
                      //slaptažodis
        
                      //pamiršau slaptažodį
        
                      //prisijungti mygtukas
        
                      //arba
        
                      //google ir apple prisijungimas
        
                      //naujas vartotojas? registruotis
                    ],
        
                  ),
                )
            )
          ],
        ),
      ),
    );
  }
}
