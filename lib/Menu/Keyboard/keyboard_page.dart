import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key});

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  final MathFieldEditingController _controller = MathFieldEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return MathKeyboardViewInsets(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Klaviatūra'),
          backgroundColor: const Color(0xFFFFA500),
        ),
        backgroundColor: const Color(0xFFFFA500),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: MathField(
                keyboardType: MathKeyboardType.expression,
                variables: ['x','y','z'],
                controller: _controller,
                focusNode: _focusNode,
                opensKeyboard: true,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  hintText: 'Įveskite matematinę išraišką',
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
