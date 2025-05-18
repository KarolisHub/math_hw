import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MathpixScanner {
  final picker = ImagePicker();

  Future<File?> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<String> sendToMathpix(File imageFile) async {
    // Compress the image first
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes == null) {
      return 'Image compression failed.';
    }

    final base64Image = base64Encode(compressedBytes);

    const appId = 'mathhw_5e136a_90ee3f';
    const appKey = 'f518dd464dc3148e940688818ee37f70a339e0bc9ed99c31099380d8a4816bfe';

    final response = await http.post(
      Uri.parse('https://api.mathpix.com/v3/text'),
      headers: {
        'app_id': appId,
        'app_key': appKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'src': 'data:image/jpeg;base64,$base64Image',
        'formats': ['latex_simplified', 'latex_styled', 'text'],
        'ocr': ['math'],
        'include_latex': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['latex_simplified'] ??
          data['latex_styled'] ??
          data['text'] ??
          'No math found.';
    } else {
      return 'Error: ${response.statusCode}\n${response.body}';
    }
  }
}