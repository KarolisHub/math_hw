import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/homework_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/send_to_mathpix_scanner.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class CreateHomeworkForm extends StatefulWidget {
  final String classId;

  const CreateHomeworkForm({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  State<CreateHomeworkForm> createState() => _CreateHomeworkFormState();
}

class _CreateHomeworkFormState extends State<CreateHomeworkForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(Duration(days: 7));
  final List<HomeworkTask> _tasks = [];
  double _totalScore = 0.0;
  String? _errorMessage;
  bool _isSubmitting = false;
  final Map<String, bool> _taskTypes = {
    'text': false,
    'image': false,
    'mathpix': false,
  };

  final Map<String, String> _taskTypeLabels = {
    'text': 'Tekstą',
    'image': 'Nuotrauką',
    'mathpix': 'Matematinė išraiška',
  };

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => _TaskFormDialog(
        onTaskAdded: (task) {
          setState(() {
            _tasks.add(task);
            _totalScore = _getTotalScore();
          });
        },
        taskNumber: _tasks.length + 1,
        taskCount: _tasks.length,
      ),
    );
  }

  void _removeTask(int index) {
    setState(() {
      _totalScore -= _tasks[index].maxScore ?? 0;
      _tasks.removeAt(index);
    });
  }

  void _editTask(int index) {
    showDialog(
      context: context,
      builder: (context) => _TaskFormDialog(
        initialTask: _tasks[index],
        onTaskAdded: (task) {
          setState(() {
            _tasks[index] = task;
          });
        },
        taskNumber: index + 1,
        taskCount: index,
      ),
    );
  }

  double _getTotalScore() {
    return _tasks.fold(0.0, (sum, task) => sum + (task.maxScore ?? 0.0));
  }

  void _submitForm() {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    if (_formKey.currentState!.validate() && _tasks.isNotEmpty) {
      final totalScore = _getTotalScore();
      if (totalScore > 100.0) {
        setState(() {
          _errorMessage = 'Bendras balas negali viršyti 100 balų';
          _isSubmitting = false;
        });
        return;
      }

      Navigator.of(context).pop({
        'title': _titleController.text,
        'description': '',
        'dueDate': _dueDate,
        'tasks': _tasks,
      });
    } else if (_tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pridėkite bent vieną užduotį')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 32, bottom: 40),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sukurti namų darbus',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Pavadinimas',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Įveskite pavadinimą';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_dueDate),
                          );
                          if (time != null) {
                            setState(() {
                              _dueDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Terminas',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(_dueDate),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Užduotys',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    ..._tasks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final task = entry.value;
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Užduotis ${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => _editTask(index),
                                    color: const Color(0xFFFFA500),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _removeTask(index),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(task.title),
                              SizedBox(height: 4),
                              Text(
                                '${task.maxScore?.toStringAsFixed(1) ?? 'Nenustatyta'} balai',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addTask,
                      icon: Icon(Icons.add),
                      label: Text('Pridėti užduotį'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA500),
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _tasks.any((task) => task.maxScore != null)
                          ? 'Bendras balas: ${_getTotalScore().toStringAsFixed(1)}'
                          : 'Balai nenustatyti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Atšaukti'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSubmitting || _getTotalScore() > 100
                              ? null
                              : _submitForm,
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text('Sukurti'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskFormDialog extends StatefulWidget {
  final HomeworkTask? initialTask;
  final Function(HomeworkTask) onTaskAdded;
  final int taskNumber;
  final int taskCount;

  const _TaskFormDialog({
    Key? key,
    this.initialTask,
    required this.onTaskAdded,
    required this.taskNumber,
    required this.taskCount,
  }) : super(key: key);

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scoreController = TextEditingController();
  String _taskType = 'text';
  bool _photoRequired = false;
  String? _latexContent;
  File? _photo;
  String? _errorMessage;
  final MathpixScanner _mathpixScanner = MathpixScanner();

  final Map<String, bool> _taskTypes = {
    'text': false,
    'image': false,
    'mathpix': false,
  };

  final Map<String, String> _taskTypeLabels = {
    'text': 'Tekstą',
    'image': 'Nuotrauką',
    'mathpix': 'Skanuotą uždavinį',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      _titleController.text = widget.initialTask!.title;
      _descriptionController.text = widget.initialTask!.description;
      _scoreController.text = widget.initialTask!.maxScore?.toString() ?? '';
      _taskType = widget.initialTask!.taskType;
      _photoRequired = widget.initialTask!.photoRequired;
      _latexContent = widget.initialTask!.latexContent;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _photo = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Klaida fotografuojant:  ' + e.toString();
      });
    }
  }

  Future<void> _scanMathpix() async {
    try {
      final file = await _mathpixScanner.pickImage();
      if (file != null) {
        final result = await _mathpixScanner.sendToMathpix(file);
        setState(() {
          String formattedLatex = result.trim();
          if (formattedLatex.startsWith('\\(')) formattedLatex = formattedLatex.substring(2);
          if (formattedLatex.endsWith('\\)')) formattedLatex = formattedLatex.substring(0, formattedLatex.length - 2);
          if (formattedLatex.startsWith('4')) formattedLatex = formattedLatex.substring(1);
          if (formattedLatex.endsWith('4')) formattedLatex = formattedLatex.substring(0, formattedLatex.length - 1);
          _latexContent = formattedLatex;
        });
      }
    } catch (e) {
      print('Mathpix API error: ' + e.toString());
      setState(() {
        _errorMessage = 'Paslauga šiuo metu nepasiekiama. Bandykite vėliau.';
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Determine the task type based on which switches are enabled
      String taskType = 'text';  // Default type
      if (_taskTypes['image'] == true) taskType = 'image';
      if (_taskTypes['mathpix'] == true) taskType = 'mathpix';

      final task = HomeworkTask(
        id: widget.initialTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        description: _descriptionController.text,
        type: taskType,
        maxScore: double.tryParse(_scoreController.text),
        photoRequired: _photoRequired,
        taskType: taskType,
        latexContent: _latexContent,
        photoUrl: _photo != null ? _photo!.path : null,  // Store the photo path
        taskOrder: widget.taskNumber - 1,  // Use taskNumber - 1 to get the correct order
      );

      widget.onTaskAdded(task);
      Navigator.of(context).pop();
    }
  }

  Widget _buildLatexPreview(String? latex) {
    if (latex == null || latex.isEmpty) {
      return SizedBox.shrink();
    }
    return Center(
      child: Column(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: 32, bottom: 40),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.taskNumber} užduotis',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  
                  SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Užduotį pateikti kaip', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._taskTypes.keys.map((type) => SwitchListTile(
                        title: Text(_taskTypeLabels[type]!),
                        value: _taskTypes[type]!,
                        onChanged: (bool value) {
                          setState(() {
                            _taskTypes[type] = value;
                          });
                        },
                      )),
                      if (_taskTypes['text'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Užduoties aprašymas',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ),
                      if (_taskTypes['image'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              if (_photo != null)
                                Image.file(
                                  _photo!,
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              Center(
                                child: SizedBox(
                                  width: 190,
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: Icon(Icons.camera_alt),
                                    label: Text(_photo != null ? 'Pakeisti nuotrauką' : 'Fotografuoti'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_taskTypes['mathpix'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (_latexContent != null && _latexContent!.isNotEmpty) ...[
                                _buildLatexPreview(_latexContent),
                              ],
                              Center(
                                child: SizedBox(
                                  width: 190,
                                  child: ElevatedButton.icon(
                                    onPressed: _scanMathpix,
                                    icon: Icon(Icons.document_scanner),
                                    label: Text(_latexContent != null && _latexContent!.isNotEmpty ? 'Skanuoti iš naujo' : 'Skanuoti'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _scoreController,
                    decoration: InputDecoration(
                      labelText: 'Maksimalus balas',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final score = double.tryParse(value);
                        if (score == null || score < 0) {
                          return 'Įveskite teigiamą skaičių';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text('Reikalinga nuotrauka'),
                    value: _photoRequired,
                    onChanged: (value) {
                      setState(() {
                        _photoRequired = value ?? false;
                      });
                    },
                  ),
                  if (_errorMessage != null) ...[
                    SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Atšaukti'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('Išsaugoti'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 