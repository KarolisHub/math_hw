import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/homework_model.dart';
import '../services/homework_service.dart';
import '../../../services/send_to_mathpix_scanner.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:math_keyboard/math_keyboard.dart';

class TaskSubmissionForm extends StatefulWidget {
  final List<HomeworkTask> tasks;
  final Function(List<TaskSubmission>) onSubmit;
  final bool isSubmitting;

  const TaskSubmissionForm({
    Key? key,
    required this.tasks,
    required this.onSubmit,
    required this.isSubmitting,
  }) : super(key: key);

  @override
  State<TaskSubmissionForm> createState() => _TaskSubmissionFormState();
}

class _TaskSubmissionFormState extends State<TaskSubmissionForm> {
  final List<TextEditingController> _answerControllers = [];
  final List<File?> _photos = [];
  final List<String?> _latexContents = [];
  final HomeworkService _homeworkService = HomeworkService();
  final MathpixScanner _mathpixScanner = MathpixScanner();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (var task in widget.tasks) {
      _answerControllers.add(TextEditingController());
      _photos.add(null);
      _latexContents.add(null);
    }
  }

  @override
  void dispose() {
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(int taskIndex) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _photos[taskIndex] = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Klaida pasirenkant nuotrauką: ${e.toString()}';
      });
    }
  }

  Future<void> _scanMathpix(int taskIndex) async {
    try {
      final file = await _mathpixScanner.pickImage();
      if (file != null) {
        final result = await _mathpixScanner.sendToMathpix(file);
        setState(() {
          _latexContents[taskIndex] = result;
          _answerControllers[taskIndex].text = result;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Klaida skenuojant: ${e.toString()}';
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    for (var i = 0; i < widget.tasks.length; i++) {
      if (_answerControllers[i].text.isEmpty) {
        setState(() {
          _errorMessage = 'Užpildykite visus atsakymus';
        });
        return;
      }

      if (widget.tasks[i].photoRequired && _photos[i] == null) {
        setState(() {
          _errorMessage = 'Pridėkite reikalingas nuotraukas';
        });
        return;
      }
    }

    try {
      final submissions = <TaskSubmission>[];
      
      for (var i = 0; i < widget.tasks.length; i++) {
        String? photoUrl;
        if (_photos[i] != null) {
          photoUrl = await _homeworkService.uploadTaskPhoto(
            widget.tasks[i].taskId,
            widget.tasks[i].taskId,
            _photos[i]!,
          );
        }

        submissions.add(TaskSubmission(
          taskId: widget.tasks[i].taskId,
          answer: _answerControllers[i].text,
          photoUrl: photoUrl,
          answerType: widget.tasks[i].taskType,
          latexContent: _latexContents[i],
        ));
      }

      widget.onSubmit(submissions);
    } catch (e) {
      setState(() {
        _errorMessage = 'Klaida pateikiant: ${e.toString()}';
      });
    }
  }

  Widget _buildLatexPreview(String? latex) {
    if (latex == null || latex.isEmpty) {
      return SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text('Peržiūra:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Math.tex(
            latex,
            textStyle: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerInput(int index, HomeworkTask task) {
    switch (task.taskType) {
      case 'text':
        return TextField(
          controller: _answerControllers[index],
          decoration: InputDecoration(
            labelText: 'Atsakymas',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        );
      
      case 'handwriting':
        return Column(
          children: [
            if (_photos[index] != null)
              Image.file(
                _photos[index]!,
                height: 200,
                fit: BoxFit.contain,
              ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(index),
              icon: Icon(Icons.photo_camera),
              label: Text('Pridėti nuotrauką'),
            ),
          ],
        );
      
      case 'image':
        return Column(
          children: [
            if (_photos[index] != null)
              Image.file(
                _photos[index]!,
                height: 200,
                fit: BoxFit.contain,
              ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(index),
              icon: Icon(Icons.photo_library),
              label: Text('Pasirinkti nuotrauką'),
            ),
          ],
        );
      
      case 'mathpix':
        return Column(
          children: [
            if (_latexContents[index] != null) ...[
              Text('LaTeX: ${_latexContents[index]}'),
              _buildLatexPreview(_latexContents[index]),
            ],
            ElevatedButton.icon(
              onPressed: () => _scanMathpix(index),
              icon: Icon(Icons.camera_alt),
              label: Text('Skenuoti'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      
      default:
        return TextField(
          controller: _answerControllers[index],
          decoration: InputDecoration(
            labelText: 'Atsakymas',
            border: OutlineInputBorder(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.tasks.asMap().entries.map((entry) {
            final index = entry.key;
            final task = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Užduotis ${index + 1}: ${task.title}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (task.description.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(task.description),
                    ],
                    SizedBox(height: 16),
                    _buildAnswerInput(index, task),
                  ],
                ),
              ),
            );
          }).toList(),
          
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          
          ElevatedButton(
            onPressed: widget.isSubmitting ? null : _submitForm,
            child: widget.isSubmitting
                ? CircularProgressIndicator()
                : Text('Pateikti namų darbus'),
          ),
        ],
      ),
    );
  }
} 