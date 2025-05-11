import 'package:flutter/material.dart';
import 'package:math_hw/Testai/test_creation_page.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "Testai"
        ),
        backgroundColor: Color(0xFFFFA500),
      ),
      backgroundColor: Color(0xFFADD8E6),
      floatingActionButton: IconButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => TestCreationPage()));
        },
        icon: Icon(Icons.add_circle_outline, size: 100, color: Color(0xFFFFA500)),
      )
    );
  }
}
