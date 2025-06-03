import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/homework_model.dart';
import '../services/homework_service.dart';
import '../../../services/send_to_mathpix_scanner.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
  final Map<String, TextEditingController> _answerControllers = {};
  final Map<String, File?> _photos = {};
  final Map<String, String?> _latexContents = {};
  final HomeworkService _homeworkService = HomeworkService();
  final MathpixScanner _mathpixScanner = MathpixScanner();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllersAndState(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant TaskSubmissionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks != widget.tasks) {
      _initializeControllersAndState(widget.tasks);
    }
  }

  void _initializeControllersAndState(List<HomeworkTask> tasks) {
    // Sort tasks by taskOrder
    final sortedTasks = List<HomeworkTask>.from(tasks)
      ..sort((a, b) => (a.taskOrder ?? 0).compareTo(b.taskOrder ?? 0));
    // Clear old controllers/state
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    _answerControllers.clear();
    _photos.clear();
    _latexContents.clear();
    // Initialize new controllers/state in sorted order
    for (var task in sortedTasks) {
      _answerControllers[task.id] = TextEditingController();
      _photos[task.id] = null;
      _latexContents[task.id] = null;
    }
  }

  @override
  void dispose() {
    for (var controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(String taskId) async {
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
          _photos[taskId] = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Klaida pasirenkant nuotrauką: ${e.toString()}';
      });
    }
  }

  Future<void> _scanMathpix(String taskId) async {
    try {
      final file = await _mathpixScanner.pickImage();
      if (file != null) {
        final result = await _mathpixScanner.sendToMathpix(file);
        setState(() {
          _latexContents[taskId] = result;
          _answerControllers[taskId]?.text = result;
        });
      }
    } catch (e) {
      print('Mathpix API error: ' + e.toString());
      setState(() {
        _errorMessage = 'Paslauga šiuo metu nepasiekiama. Bandykite vėliau.';
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    for (var task in widget.tasks) {
      if (_answerControllers[task.id]?.text.isEmpty ?? true) {
        setState(() {
          _errorMessage = 'Užpildykite visus atsakymus';
        });
        return;
      }
      if (task.photoRequired && _photos[task.id] == null) {
        setState(() {
          _errorMessage = 'Pridėkite reikalingas nuotraukas';
        });
        return;
      }
    }

    try {
      final submissions = <TaskSubmission>[];
      for (var task in widget.tasks) {
        String? photoUrl;
        if (_photos[task.id] != null) {
          photoUrl = await _homeworkService.uploadTaskPhoto(
            task.taskId,
            task.taskId,
            _photos[task.id]!,
          );
        }
        submissions.add(TaskSubmission(
          taskId: task.taskId,
          answer: _answerControllers[task.id]?.text,
          photoUrl: photoUrl,
          answerType: task.taskType,
          latexContent: _latexContents[task.id],
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

  Widget _buildAnswerInput(HomeworkTask task) {
    final taskId = task.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (task.photoUrl != null) ...[
          SizedBox(height: 8),
          Text('Užduoties nuotrauka:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Image.file(
            File(task.photoUrl!),
            height: 200,
            fit: BoxFit.contain,
          ),
        ],
        if (task.latexContent != null && task.latexContent!.isNotEmpty) ...[
          SizedBox(height: 8),
          Text('Užduoties matematinė išraiška:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Math.tex(
              task.latexContent!,
              textStyle: TextStyle(fontSize: 18),
            ),
          ),
        ],
        SizedBox(height: 16),
        switch (task.taskType) {
          'text' => TextField(
            controller: _answerControllers[taskId],
            decoration: InputDecoration(
              labelText: 'Atsakymas',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          'image' => Column(
            children: [
              if (_photos[taskId] != null)
                Image.file(
                  _photos[taskId]!,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(taskId),
                icon: Icon(Icons.photo_library),
                label: Text(_photos[taskId] != null ? 'Pakeisti nuotrauką' : 'Pasirinkti nuotrauką'),
              ),
            ],
          ),
          'mathpix' => Column(
            children: [
              if (_latexContents[taskId] != null && _latexContents[taskId]!.isNotEmpty) ...[
                _buildLatexPreview(_latexContents[taskId]),
              ],
              if (task.latexContent == null || task.latexContent!.isEmpty)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _scanMathpix(taskId),
                    icon: Icon(Icons.camera_alt),
                    label: Text(_latexContents[taskId] != null && _latexContents[taskId]!.isNotEmpty 
                      ? 'Skanuoti iš naujo' 
                      : 'Skanuoti'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          _ => TextField(
            controller: _answerControllers[taskId],
            decoration: InputDecoration(
              labelText: 'Atsakymas',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort tasks by taskOrder before displaying
    final sortedTasks = List<HomeworkTask>.from(widget.tasks)
      ..sort((a, b) => (a.taskOrder ?? 0).compareTo(b.taskOrder ?? 0));

    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...sortedTasks.asMap().entries.map((entry) {
            final task = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Užduotis ${entry.key + 1}: ${task.title}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (task.description.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(task.description),
                    ],
                    SizedBox(height: 16),
                    _buildAnswerInput(task),
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