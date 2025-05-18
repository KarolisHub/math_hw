import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'models/homework_model.dart';
import 'services/homework_service.dart';
import 'widgets/task_submission_form.dart';
import 'widgets/submission_list.dart';
import 'widgets/comment_section.dart';

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

  @override
  void initState() {
    super.initState();
    _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
  }

  Future<void> _submitHomework(List<TaskSubmission> submissions) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _homeworkService.submitHomework(
        homeworkId: widget.homeworkId,
        taskSubmissions: submissions,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Namų darbai sėkmingai pateikti')),
        );
        setState(() {
          _homeworkFuture = _homeworkService.getHomework(widget.homeworkId);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
          SnackBar(content: Text('Terminas sėkmingai atnaujintas')),
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
        title: Text('Archyvuoti namų darbą'),
        content: Text('Ar tikrai norite archyvuoti šį namų darbą?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Archyvuoti'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        title: Text('Ištrinti namų darbus'),
        content: Text('Ar tikrai norite ištrinti šiuos namų darbus? Šis veiksmas negrįžtamas.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Homework>(
          future: _homeworkFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.title);
            }
            return Text('Namų darbai');
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

          return SingleChildScrollView(
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

                // Tasks and submission form
                if (!widget.isCreator && homework.isActive && userSubmission == null)
                  TaskSubmissionForm(
                    tasks: homework.tasks,
                    onSubmit: _submitHomework,
                    isSubmitting: _isSubmitting,
                  ),

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

                // User's submission (for students)
                if (!widget.isCreator && userSubmission != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jūsų pateikimas',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 16),
                          ...userSubmission.tasks.map((task) {
                            final originalTask = homework.tasks
                                .firstWhere((t) => t.taskId == task.taskId);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  originalTask.title,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(task.answer),
                                if (task.photoUrl != null) ...[
                                  SizedBox(height: 8),
                                  Image.network(
                                    task.photoUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ],
                                if (task.score != null) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    'Balas: ${task.score!.toStringAsFixed(1)}/${originalTask.maxScore}',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                                if (task.feedback != null) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    'Atsiliepimas: ${task.feedback}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                                SizedBox(height: 16),
                              ],
                            );
                          }).toList(),
                          if (userSubmission.status == 'GRADED')
                            Text(
                              'Bendras balas: ${userSubmission.totalScore.toStringAsFixed(1)}/${homework.totalScore}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Comments section
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
          );
        },
      ),
    );
  }
} 