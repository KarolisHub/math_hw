import 'package:flutter/material.dart';


class LoginButton extends StatelessWidget {

  final Function()? onTap;

  const LoginButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.symmetric(horizontal: 110),
        decoration: BoxDecoration(
            color: Color(0xFFFFA500),
          borderRadius: BorderRadius.circular(40)
        ),
        child: const Center(
          child: Text(
              "PRISIJUNGTI",
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
