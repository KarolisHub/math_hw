import 'package:flutter/material.dart';


class LoginButton extends StatelessWidget {

  final Function()? onTap;
  final String text;

  const LoginButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(horizontal: 80),
        decoration: BoxDecoration(
            color: Color(0xFFFFA500),
          borderRadius: BorderRadius.circular(40)
        ),
        child: Center(
          child: Text(
              text,
            style: TextStyle(
                color: Color(0xFF292D32),
                fontSize: 18,
              fontWeight: FontWeight.bold,

            ),
          ),
        ),
      ),
    );
  }
}
