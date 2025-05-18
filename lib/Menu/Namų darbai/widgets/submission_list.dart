import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/homework_model.dart';

class SubmissionList extends StatelessWidget {
  final Homework homework;
  final Function(String, List<TaskSubmission>, double) onGrade;

  const SubmissionList({
    Key? key,
    required this.homework,
    required this.onGrade,
  }) : super(key: key);

  Future<void> _showGradeDialog(
    BuildContext context,
    HomeworkSubmission submission,
  ) async {
    final taskControllers = <TextEditingController>[];
    final scoreControllers = <TextEditingController>[];
    final feedbackControllers = <TextEditingController>[];
    double totalScore = 0.0;

    for (var task in submission.tasks) {
      taskControllers.add(TextEditingController(text: task.answer));
      scoreControllers.add(TextEditingController(
        text: task.score?.toString() ?? '',
      ));
      feedbackControllers.add(TextEditingController(text: task.feedback ?? ''));
      if (task.score != null) {
        totalScore += task.score!;
      }
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _GradeDialog(
        submission: submission,
        homework: homework,
        taskControllers: taskControllers,
        scoreControllers: scoreControllers,
        feedbackControllers: feedbackControllers,
        initialTotalScore: totalScore,
      ),
    );

    if (result != null) {
      final gradedTasks = <TaskSubmission>[];
      double newTotalScore = 0.0;

      for (var i = 0; i < submission.tasks.length; i++) {
        final originalTask = homework.tasks[i];
        final score = double.tryParse(scoreControllers[i].text) ?? 0.0;
        if (originalTask.maxScore != null && score > originalTask.maxScore!) {
          throw 'Balas negali būti didesnis už ${originalTask.maxScore!.toStringAsFixed(1)}';
        }
        newTotalScore += score;

        gradedTasks.add(TaskSubmission(
          taskId: submission.tasks[i].taskId,
          answer: submission.tasks[i].answer,
          photoUrl: submission.tasks[i].photoUrl,
          score: score,
          feedback: feedbackControllers[i].text.isEmpty
              ? null
              : feedbackControllers[i].text,
          answerType: submission.tasks[i].answerType,
          latexContent: submission.tasks[i].latexContent,
        ));
      }

      onGrade(submission.userId, gradedTasks, newTotalScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (homework.submissions.isEmpty) {
      return Center(
        child: Text(
          'Dar nėra pateiktų namų darbų',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pateikimai (${homework.submissions.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        ...homework.submissions.map((submission) {
          final isGraded = submission.status == 'GRADED';
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => _showGradeDialog(context, submission),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(submission.userId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                return Text(
                                  '${userData?['name'] ?? 'Nežinomas'} ${userData?['surname'] ?? 'Vartotojas'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              return Text('Kraunama...');
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isGraded
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isGraded ? Colors.green : Colors.orange,
                            ),
                          ),
                          child: Text(
                            isGraded ? 'Įvertinta' : 'Laukia vertinimo',
                            style: TextStyle(
                              color: isGraded ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pateikta: ${DateFormat('yyyy-MM-dd HH:mm').format(submission.submittedAt)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (isGraded) ...[
                      SizedBox(height: 8),
                      Text(
                        'Bendras balas: ${submission.totalScore.toStringAsFixed(1)}/${homework.totalScore}',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _GradeDialog extends StatefulWidget {
  final HomeworkSubmission submission;
  final Homework homework;
  final List<TextEditingController> taskControllers;
  final List<TextEditingController> scoreControllers;
  final List<TextEditingController> feedbackControllers;
  final double initialTotalScore;

  const _GradeDialog({
    Key? key,
    required this.submission,
    required this.homework,
    required this.taskControllers,
    required this.scoreControllers,
    required this.feedbackControllers,
    required this.initialTotalScore,
  }) : super(key: key);

  @override
  State<_GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends State<_GradeDialog> {
  late double _totalScore;
  final List<double> _availableScores = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0];

  @override
  void initState() {
    super.initState();
    _totalScore = widget.initialTotalScore;
  }

  void _updateTotalScore() {
    setState(() {
      _totalScore = widget.scoreControllers.fold(
        0.0,
        (sum, controller) => sum + (double.tryParse(controller.text) ?? 0.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vertinti pateikimą',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ...widget.submission.tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              final originalTask = widget.homework.tasks
                  .firstWhere((t) => t.taskId == task.taskId);

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
                              originalTask.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            'Maks. ${originalTask.maxScore?.toStringAsFixed(1) ?? 'Nenustatyta'} balai',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(originalTask.description),
                      SizedBox(height: 16),
                      Text(
                        'Atsakymas:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(widget.taskControllers[index].text),
                      if (task.photoUrl != null) ...[
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            task.photoUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<double>(
                              value: double.tryParse(widget.scoreControllers[index].text) ?? 0.0,
                              decoration: InputDecoration(
                                labelText: 'Balas',
                                border: OutlineInputBorder(),
                                suffixText: '/${originalTask.maxScore}',
                              ),
                              items: _availableScores
                                  .where((score) => originalTask.maxScore == null || score <= originalTask.maxScore!)
                                  .map((score) {
                                return DropdownMenuItem<double>(
                                  value: score,
                                  child: Text(score.toStringAsFixed(1)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  widget.scoreControllers[index].text = value.toString();
                                  _updateTotalScore();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: widget.feedbackControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Atsiliepimas',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 16),
            Text(
              'Bendras balas: ${_totalScore.toStringAsFixed(1)}/${widget.homework.totalScore}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _totalScore > widget.homework.totalScore
                    ? Colors.red
                    : Colors.green,
              ),
              textAlign: TextAlign.center,
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
                  onPressed: _totalScore > widget.homework.totalScore
                      ? null
                      : () {
                          Navigator.of(context).pop({
                            'graded': true,
                          });
                        },
                  child: Text('Išsaugoti'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 