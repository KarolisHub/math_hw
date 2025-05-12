import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/homework_model.dart';
import '../services/homework_service.dart';

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
  final HomeworkService _homeworkService = HomeworkService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (var task in widget.tasks) {
      _answerControllers.add(TextEditingController());
      _photos.add(null);
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
        ));
      }

      widget.onSubmit(submissions);
    } catch (e) {
      setState(() {
        _errorMessage = 'Klaida pateikiant: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pateikti namų darbus',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${task.maxScore?.toStringAsFixed(1) ?? 'Nenustatyta'} balai',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(task.description),
                  SizedBox(height: 16),
                  TextField(
                    controller: _answerControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Jūsų atsakymas',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  if (task.photoRequired) ...[
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Reikalinga nuotrauka',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(index),
                          icon: Icon(Icons.photo),
                          label: Text(_photos[index] == null ? 'Pridėti' : 'Pakeisti'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA500),
                          ),
                        ),
                      ],
                    ),
                    if (_photos[index] != null) ...[
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _photos[index]!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
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
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Pateikti'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA500),
            minimumSize: Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
} 