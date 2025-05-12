import 'package:flutter/material.dart';
import '../models/homework_model.dart';
import 'package:intl/intl.dart';

class HomeworkCard extends StatelessWidget {
  final Homework homework;
  final bool isCreator;
  final VoidCallback onTap;

  const HomeworkCard({
    Key? key,
    required this.homework,
    required this.isCreator,
    required this.onTap,
  }) : super(key: key);

  Color _getStatusColor() {
    if (!homework.isActive) return Colors.grey;
    
    final now = DateTime.now();
    if (now.isAfter(homework.dueDate)) return Colors.red;
    if (homework.dueDate.difference(now).inHours <= 24) return Colors.orange;
    return Colors.green;
  }

  String _getStatusText() {
    if (!homework.isActive) return 'Neaktyvus';
    
    final now = DateTime.now();
    if (now.isAfter(homework.dueDate)) return 'Pradelstas';
    if (homework.dueDate.difference(now).inHours <= 24) return 'Artėja terminas';
    return 'Aktyvus';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final statusColor = _getStatusColor();
    final statusText = _getStatusText();

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      homework.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
                        dateFormat.format(homework.dueDate),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Užduotys:',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${homework.tasks.length} ${_getTaskText(homework.tasks.length)}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              if (isCreator) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pateikimai:',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${homework.submissions.length} ${_getSubmissionText(homework.submissions.length)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTaskText(int count) {
    if (count == 1) return 'užduotis';
    if (count >= 2 && count <= 9) return 'užduotys';
    return 'užduočių';
  }

  String _getSubmissionText(int count) {
    if (count == 1) return 'pateikimas';
    if (count >= 2 && count <= 9) return 'pateikimai';
    return 'pateikimų';
  }
} 