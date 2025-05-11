import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_hw/Menu/Keyboard/keyboard_page.dart';
import '../services/send_to_mathpix_scanner.dart';
import 'package:camera/camera.dart';

class CameraOCR extends StatefulWidget {
  @override
  _CameraOCRState createState() => _CameraOCRState();
}

class _CameraOCRState extends State<CameraOCR> {
  final _mathpixScanner = MathpixScanner();
  File? _image;
  String _latexResult = 'No result yet';
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _processImage() async {
    if (!_cameraController!.value.isInitialized) return;

    try {
      final image = await _cameraController!.takePicture();
      final imageFile = File(image.path);

      setState(() {
        _image = imageFile;
        _latexResult = 'Palaukite...';
      });

      final result = await _mathpixScanner.sendToMathpix(_image!);
      setState(() {
        _latexResult = result;
      });
    } catch (e) {
      print('Klaida: $e');
    }
  }

  Future<void> _resetCamera() async {
    setState(() {
      _image = null;
      _latexResult = 'No result yet';
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skanuok"),
        backgroundColor: Color(0xFFFFA500),
      ),
      backgroundColor: Color(0xFFFFA500),
      body: Stack(
        children: [
          // Full screen camera preview
          if (_isCameraInitialized && _image == null)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            ),

          // Captured image display
          if (_image != null)
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.file(
                _image!,
                fit: BoxFit.cover,
              ),
            ),

          // LaTeX result overlay
          if (_latexResult != 'No result yet')
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(8),
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                        _latexResult,
                        textStyle: const TextStyle(
                            fontSize: 20,
                            color: Colors.white
                        )
                    )
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              color: const Color(0xFFFFA500),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  IconButton(
                    onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const KeyboardPage()),
                        );
                      },
                    icon: const Icon(Icons.keyboard),
                    iconSize: 50,
                  ),

                  const SizedBox(width: 35), // Left spacing to balance the right button
                  
                  //Fotografavimo mygtukas
                  Center(
                    child: IconButton(
                      onPressed: _processImage,
                      icon: const Icon(
                        Icons.radio_button_unchecked,
                        size: 80,
                        color: Color(0xFF292D32),
                      ),
                    ),
                  ),
                  
                  //Nuotraukos pakartojimo mygtukas
                  IconButton(
                    onPressed: _resetCamera,
                    icon: const Icon(
                      Icons.refresh,
                      size: 50,
                      color: Color(0xFF292D32),
                    ),
                  ),
                  const SizedBox(width: 30), // Right padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
