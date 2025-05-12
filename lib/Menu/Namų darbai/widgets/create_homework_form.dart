import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/homework_model.dart';

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
      ),
    );
  }

  double _getTotalScore() {
    return _tasks.fold(0.0, (sum, task) => sum + (task.maxScore ?? 0.0));
  }

  void _submitForm() {
    setState(() {
      _isSubmitting = true;
    });

    if (_formKey.currentState!.validate() && _tasks.isNotEmpty) {
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
      child: SingleChildScrollView(
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
                          onPressed: _isSubmitting || _getTotalScore() > 10
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

  const _TaskFormDialog({
    Key? key,
    this.initialTask,
    required this.onTaskAdded,
    required this.taskNumber,
  }) : super(key: key);

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _photoRequired = false;
  bool _usePoints = false;
  double? _selectedScore;

  final List<double> _availableScores = [
    0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      _titleController.text = widget.initialTask!.title;
      _selectedScore = widget.initialTask!.maxScore;
      _photoRequired = widget.initialTask!.photoRequired;
      _usePoints = widget.initialTask!.maxScore != null;
    } else {
      _selectedScore = 1.0;
      _usePoints = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
              SwitchListTile(
                title: Text('Nustatyti balus'),
                value: _usePoints,
                onChanged: (value) {
                  setState(() {
                    _usePoints = value;
                    if (!value) {
                      _selectedScore = null;
                    } else if (_selectedScore == null) {
                      _selectedScore = 1.0;
                    }
                  });
                },
              ),
              if (_usePoints) ...[
                SizedBox(height: 16),
                DropdownButtonFormField<double>(
                  value: _selectedScore,
                  decoration: InputDecoration(
                    labelText: 'Maksimalus balas',
                    border: OutlineInputBorder(),
                    suffixText: 'balai',
                  ),
                  items: _availableScores.map((score) {
                    return DropdownMenuItem<double>(
                      value: score,
                      child: Text(score.toStringAsFixed(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedScore = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pasirinkite balą';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Reikalinga nuotrauka'),
                value: _photoRequired,
                onChanged: (value) {
                  setState(() {
                    _photoRequired = value;
                  });
                },
              ),
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final task = HomeworkTask(
                          taskId: widget.initialTask?.taskId ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          title: _titleController.text,
                          maxScore: _usePoints ? _selectedScore : null,
                          photoRequired: _photoRequired,
                        );
                        widget.onTaskAdded(task);
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(widget.initialTask == null ? 'Pridėti' : 'Išsaugoti'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 