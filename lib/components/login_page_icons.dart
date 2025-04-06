import 'package:flutter/material.dart';


class SquareTile extends StatelessWidget {

  final String imagePath;
  final Function()? onTap;
  const SquareTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xFFFFA500),
          borderRadius: BorderRadius.circular(10)
        ),
        child: Image.asset(
            imagePath,
          height: 40,
        ),
      ),
    );
  }
}
