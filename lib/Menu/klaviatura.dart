import 'package:flutter/material.dart';
import 'package:math_keyboard/math_keyboard.dart';

class KlaviaturaPage extends StatefulWidget {
  const KlaviaturaPage({super.key});

  @override
  State<KlaviaturaPage> createState() => _KlaviaturaPageState();
}

class _KlaviaturaPageState extends State<KlaviaturaPage> {
  late final _controller = MathFieldEditingController();

  @override
  void initState() {
    super.initState();
    // Set initial value to square root of 9 using TeXParser
    _controller.updateValue(TeXParser(r'\frac{\sqrt{9}}{3} 1').parse());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapClear() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Klaviatūra'),
          backgroundColor: const Color(0xFFFFA500),
        ),
        body: MathField(
          controller: _controller,
          decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffix: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _onTapClear,
                  child: const Icon(Icons.clear),
                ),
              )
          ),
        )
    );
  }
}