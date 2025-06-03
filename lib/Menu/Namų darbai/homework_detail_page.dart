import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'models/homework_model.dart';
import 'services/homework_service.dart';
import 'widgets/submission_list.dart';
import 'widgets/comment_section.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../services/send_to_mathpix_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkDetailPage extends StatefulWidget {
  final String homeworkId;
  final bool isCreator;

  const HomeworkDetailPage({
    Key? key,
    required this.homeworkId,
    required this.isCreator,
  }) : super(key: key);

  @override
  State<HomeworkDetailPage> createState() => _HomeworkDetailPageState();
}

class _HomeworkDetailPageState extends State<HomeworkDetailPage> {
  final HomeworkService _homeworkService = HomeworkService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<Homework> _homeworkFuture;
  String? _errorMessage;
  bool _isSubmitting = false;
  // Local state for student answers
  final Map<String, TaskSubmission> _localTaskAnswers = {};

  @override
  void initState() {
    super.initState();
    _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
  }

  // New: Add or update local answer for a task
  void _addOrUpdateLocalAnswer(TaskSubmission submission) {
    setState(() {
      _localTaskAnswers[submission.taskId] = submission;
    });
  }

  // New: Submit all local answers
  Future<void> _submitAllAnswers() async {
    setState(() { _isSubmitting = true; _errorMessage = null; });
    try {
      await _homeworkService.submitHomework(
        homeworkId: widget.homeworkId,
        taskSubmissions: _localTaskAnswers.values.toList(),
      );
      setState(() {
        _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
        _localTaskAnswers.clear();
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Namų darbai sėkmingai pateikti')),
      );
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isSubmitting = false; });
    }
  }

  Future<void> _updateDeadline(DateTime newDueDate) async {
    try {
      await _homeworkService.updateHomeworkDeadline(
        homeworkId: widget.homeworkId,
        newDueDate: newDueDate,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terminas sėkmingai atnaujintas')),
        );
        setState(() {
          _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Klaida atnaujinant terminą: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _archiveHomework() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archyvuoti namų darbą'),
        content: const Text('Ar tikrai norite archyvuoti šį namų darbą?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Archyvuoti'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _homeworkService.archiveHomework(widget.homeworkId);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Klaida archyvuojant: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteHomework() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ištrinti namų darbus'),
        content: const Text('Ar tikrai norite ištrinti šiuos namų darbus? Šis veiksmas negrįžtamas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ištrinti'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _homeworkService.deleteHomework(widget.homeworkId);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Klaida ištrinant: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<TaskSubmission?> _showAnswerDialog(BuildContext context, HomeworkTask task, {bool localMode = false, TaskSubmission? initialSubmission}) async {
    final TextEditingController answerController = TextEditingController();
    File? selectedImage;
    String? latexContent;
    String? errorMessage;
    final mathpixScanner = MathpixScanner();
    TaskSubmission? resultSubmission;

    // Toggle states
    bool showText = false;
    bool showPhoto = false;
    bool showScan = false;

    // Prefill fields if editing
    if (initialSubmission != null) {
      if (initialSubmission.answer != null) {
        showText = true;
        answerController.text = initialSubmission.answer!;
      }
      if (initialSubmission.photoUrl != null) {
        showPhoto = true;
        selectedImage = initialSubmission.photoUrl!.startsWith('http') ? null : File(initialSubmission.photoUrl!);
      }
      if (initialSubmission.latexContent != null && initialSubmission.latexContent!.isNotEmpty) {
        showScan = true;
        latexContent = initialSubmission.latexContent;
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pridėti atsakymą'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Užduotis: ${task.title}'),
                const SizedBox(height: 16),
                // Toggles
                Row(
                  children: [
                    Switch(
                      value: showText,
                      onChanged: (val) => setState(() => showText = val),
                    ),
                    const Text('Tekstinis atsakymas'),
                  ],
                ),
                Row(
                  children: [
                    Switch(
                      value: showPhoto,
                      onChanged: (val) => setState(() => showPhoto = val),
                    ),
                    const Text('Fotografuoti'),
                  ],
                ),
                Row(
                  children: [
                    Switch(
                      value: showScan,
                      onChanged: (val) => setState(() => showScan = val),
                    ),
                    const Text('Skanuoti'),
                  ],
                ),
                const SizedBox(height: 16),
                // Text field
                if (showText) ...[
                  TextField(
                    controller: answerController,
                    decoration: const InputDecoration(
                      labelText: 'Atsakymas',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                ],
                // Photo preview and button
                if (showPhoto) ...[
                  if (selectedImage != null) ...[
                    const Text('Pasirinkta nuotrauka:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Image.file(
                      selectedImage!,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1920,
                        maxHeight: 1080,
                        imageQuality: 85,
                      );
                      if (pickedFile != null) {
                        setState(() {
                          selectedImage = File(pickedFile.path);
                          errorMessage = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Fotografuoti'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // Scan preview and button
                if (showScan) ...[
                  if (latexContent != null && latexContent!.isNotEmpty) ...[
                    const Text('Skenuotas atsakymas:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Math.tex(
                        latexContent!,
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton.icon(
                    onPressed: () async {
                      final file = await mathpixScanner.pickImage();
                      if (file != null) {
                        final result = await mathpixScanner.sendToMathpix(file);
                        setState(() {
                          latexContent = result;
                          errorMessage = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Skanuoti'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (errorMessage != null) ...[
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Atšaukti'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!showText && !showPhoto && !showScan) {
                  setState(() {
                    errorMessage = 'Pasirinkite bent vieną atsakymo tipą';
                  });
                  return;
                }
                if (showText && answerController.text.isEmpty) {
                  setState(() {
                    errorMessage = 'Įveskite atsakymą';
                  });
                  return;
                }
                try {
                  String? photoUrl;
                  if (showPhoto && selectedImage != null) {
                    photoUrl = await _homeworkService.uploadTaskPhoto(
                      task.taskId,
                      task.taskId,
                      selectedImage!,
                    );
                  }
                  final submission = TaskSubmission(
                    taskId: task.taskId,
                    answer: showText ? answerController.text : null,
                    photoUrl: showPhoto ? photoUrl : null,
                    answerType: task.taskType,
                    latexContent: showScan ? latexContent : null,
                  );
                  if (localMode) {
                    resultSubmission = submission;
                  } else {
                    await _homeworkService.submitTaskAnswer(
                      homeworkId: widget.homeworkId,
                      taskSubmission: submission,
                    );
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Atsakymas sėkmingai pateiktas')),
                  );
                } catch (e) {
                  setState(() {
                    errorMessage = 'Klaida pateikiant atsakymą: ${e.toString()}';
                  });
                }
              },
              child: const Text('Pridėti'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return resultSubmission;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFADD8E6),
      appBar: AppBar(
        title: FutureBuilder<Homework>(
          future: _homeworkFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.title);
            }
            return const Text('Namų darbai');
          },
        ),
        backgroundColor: const Color(0xFFFFA500),
        actions: [
          if (widget.isCreator)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'archive') {
                  await _archiveHomework();
                } else if (value == 'deadline') {
                  final homework = await _homeworkFuture;
                  final date = await showDatePicker(
                    context: context,
                    initialDate: homework.dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(homework.dueDate),
                    );
                    if (time != null) {
                      final newDueDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                      await _updateDeadline(newDueDate);
                    }
                  }
                } else if (value == 'delete') {
                  await _deleteHomework();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'deadline',
                  child: Text('Keisti terminą'),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Text('Archyvuoti'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Ištrinti'),
                  textStyle: TextStyle(color: Colors.red),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<Homework>(
        future: _homeworkFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Klaida: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('Namų darbų nerasta'));
          }

          final homework = snapshot.data!;
          final currentUser = _auth.currentUser;
          if (currentUser == null) {
            return Center(child: Text('Prisijunkite norint matyti namų darbus'));
          }

          // Check if user has submitted
          HomeworkSubmission? userSubmission;
          try {
            userSubmission = homework.submissions
                .firstWhere((sub) => sub.userId == currentUser.uid);
          } catch (e) {
            userSubmission = null;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Homework details
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            homework.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Terminas:',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('yyyy-MM-dd HH:mm').format(homework.dueDate),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: DateTime.now().isAfter(homework.dueDate)
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Bendras balas:',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${homework.totalScore.toStringAsFixed(1)} balai',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Display all tasks
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...homework.tasks.asMap().entries.map((entry) {
                            final index = entry.key;
                            final task = entry.value;
                            // Find user's answer for this task
                            TaskSubmission? userTaskSubmission;
                            if (userSubmission != null) {
                              try {
                                userTaskSubmission = userSubmission.tasks.firstWhere((t) => t.taskId == task.taskId);
                              } catch (e) {
                                userTaskSubmission = null;
                              }
                            }
                            // Prefer local answer if present
                            final localOrSubmittedAnswer = _localTaskAnswers[task.taskId] ?? userTaskSubmission;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${index + 1}. Užduotis',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (task.description.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    child: Text(
                                      task.description,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                                if (task.photoUrl != null) ...[
                                  SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: task.photoUrl!.startsWith('http')
                                        ? Image.network(
                                            task.photoUrl!,
                                            height: 200,
                                            fit: BoxFit.contain,
                                          )
                                        : Image.file(
                                            File(task.photoUrl!),
                                            height: 200,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ],
                                if (task.latexContent != null && task.latexContent!.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Math.tex(
                                        task.latexContent!,
                                        textStyle: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  child: Text(
                                    'Maksimalus balas: ${task.maxScore?.toStringAsFixed(1) ?? 'Nenustatyta'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // User's answer section (local or submitted)
                                if (localOrSubmittedAnswer != null && (localOrSubmittedAnswer.answer != null || localOrSubmittedAnswer.photoUrl != null || (localOrSubmittedAnswer.latexContent != null && localOrSubmittedAnswer.latexContent!.isNotEmpty))) ...[
                                  SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE6F4EA), // light green
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (widget.isCreator && userTaskSubmission != null && userSubmission != null) ...[
                                              FutureBuilder<DocumentSnapshot>(
                                                future: FirebaseFirestore.instance
                                                    .collection('vartotojai')
                                                    .doc(userSubmission.userId)
                                                    .get(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                                    final name = userData?['vardas'] ?? 'Nežinomas';
                                                    final surname = userData?['pavarde'] ?? 'Vartotojas';
                                                    return Text('$name $surname', style: TextStyle(fontWeight: FontWeight.bold));
                                                  }
                                                  return Text('Kraunama...');
                                                },
                                              ),
                                            ]
                                            else ...[
                                              Text('Jūsų atsakymas:', style: TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                            if (_localTaskAnswers[task.taskId] != null) ...[
                                              IconButton(
                                                icon: Icon(Icons.edit, color: Color(0xFFFFA500)),
                                                tooltip: 'Keisti atsakymą',
                                                onPressed: () async {
                                                  final submission = await _showAnswerDialog(context, task, localMode: true, initialSubmission: _localTaskAnswers[task.taskId]);
                                                  if (submission != null) {
                                                    _addOrUpdateLocalAnswer(submission);
                                                  }
                                                },
                                              ),
                                            ],
                                            if (widget.isCreator && userTaskSubmission != null) ...[
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.delete, color: Colors.red),
                                                    tooltip: 'Ištrinti atsakymą',
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: Text('Ištrinti atsakymą'),
                                                          content: Text('Ar tikrai norite ištrinti šį atsakymą?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.of(context).pop(false),
                                                              child: Text('Atšaukti'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.of(context).pop(true),
                                                              child: Text('Ištrinti'),
                                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        // Delete from Firestore
                                                        await _homeworkService.deleteTaskAnswer(
                                                          homeworkId: homework.homeworkId,
                                                          userId: userSubmission!.userId,
                                                          taskId: userTaskSubmission!.taskId,
                                                        );
                                                        setState(() {
                                                          _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.refresh, color: Color(0xFF4CAF50)),
                                                    tooltip: 'Leisti pakartotinai pateikti',
                                                    onPressed: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          title: Text('Leisti pakartotinai pateikti'),
                                                          content: Text('Ar tikrai norite leisti šiam vartotojui pateikti atsakymus iš naujo?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.of(context).pop(false),
                                                              child: Text('Atšaukti'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.of(context).pop(true),
                                                              child: Text('Leisti'),
                                                              style: TextButton.styleFrom(foregroundColor: Color(0xFF4CAF50)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        // Delete the whole submission for this user and homework
                                                        await _homeworkService.deleteUserSubmission(
                                                          homeworkId: homework.homeworkId,
                                                          userId: userSubmission!.userId,
                                                        );
                                                        setState(() {
                                                          _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (localOrSubmittedAnswer.answer != null && localOrSubmittedAnswer.answer!.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Text(localOrSubmittedAnswer.answer!),
                                        ],
                                        if (localOrSubmittedAnswer.photoUrl != null) ...[
                                          SizedBox(height: 8),
                                          localOrSubmittedAnswer.photoUrl!.startsWith('http')
                                              ? Image.network(
                                                  localOrSubmittedAnswer.photoUrl!,
                                                  height: 200,
                                                  fit: BoxFit.contain,
                                                )
                                              : Image.file(
                                                  File(localOrSubmittedAnswer.photoUrl!),
                                                  height: 200,
                                                  fit: BoxFit.contain,
                                                ),
                                        ],
                                        if (localOrSubmittedAnswer.latexContent != null && localOrSubmittedAnswer.latexContent!.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Math.tex(
                                              localOrSubmittedAnswer.latexContent!,
                                              textStyle: TextStyle(fontSize: 18),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                                if (!widget.isCreator && homework.isActive && _localTaskAnswers[task.taskId] == null && userTaskSubmission == null) ...[
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final submission = await _showAnswerDialog(context, task, localMode: true);
                                      if (submission != null) {
                                        _addOrUpdateLocalAnswer(submission);
                                      }
                                    },
                                    child: Text('Pridėti atsakymą'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFFA500),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                                if (index < homework.tasks.length - 1)
                                  Divider(height: 24),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Submissions list (for creator)
                  if (widget.isCreator)
                    SubmissionList(
                      homework: homework,
                      onGrade: (userId, gradedTasks, totalScore) async {
                        try {
                          await _homeworkService.gradeSubmission(
                            homeworkId: homework.homeworkId,
                            userId: userId,
                            gradedTasks: gradedTasks,
                            totalScore: totalScore,
                          );
                          setState(() {
                            _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Klaida vertinant: ${e.toString()}')),
                          );
                        }
                      },
                    ),

                  // Comments section
                  if (!widget.isCreator && homework.isActive) ...[
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_isSubmitting || _localTaskAnswers.isEmpty)
                          ? null
                          : () async {
                              await _submitAllAnswers();
                              setState(() {
                                _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
                              });
                            },
                      child: _isSubmitting
                          ? CircularProgressIndicator()
                          : Text('Pateikti vertinimui'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ],
                  SizedBox(height: 24),
                  CommentSection(
                    homeworkId: homework.homeworkId,
                    comments: homework.comments,
                    onCommentAdded: () {
                      setState(() {
                        _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
                      });
                    },
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 