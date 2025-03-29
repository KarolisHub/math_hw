import 'package:flutter/material.dart';


class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.symmetric(horizontal: 110),
      decoration: BoxDecoration(
          color: Color(0xFFFFA500),
        borderRadius: BorderRadius.circular(40)
      ),
      child: Center(
        child: Text(
            "PRISIJUNGTI",
          style: TextStyle(
              color: Color(0xFF292D32),
              fontSize: 18,
            fontWeight: FontWeight.bold,

          ),
        ),
      ),
    );
  }
}
