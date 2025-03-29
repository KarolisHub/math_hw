import 'package:flutter/material.dart';


class SquareTile extends StatelessWidget {

  final String imagePath;
  const SquareTile({
    super.key,
    required this.imagePath
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFFFA500),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Image.asset(
          imagePath,
        height: 40,
      ),
    );
  }
}
