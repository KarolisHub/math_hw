import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkTask {
  final String taskId;
  final String title;
  final String description;
  final double? maxScore;
  final bool photoRequired;

  HomeworkTask({
    required this.taskId,
    required this.title,
    this.description = '',
    this.maxScore,
    required this.photoRequired,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'maxScore': maxScore,
      'photoRequired': photoRequired,
    };
  }

  factory HomeworkTask.fromMap(Map<String, dynamic> map) {
    return HomeworkTask(
      taskId: map['taskId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      maxScore: map['maxScore'] != null ? (map['maxScore'] as num).toDouble() : null,
      photoRequired: map['photoRequired'] as bool,
    );
  }
}

class HomeworkSubmission {
  final String userId;
  final DateTime submittedAt;
  final String status;
  final List<TaskSubmission> tasks;
  final double totalScore;

  HomeworkSubmission({
    required this.userId,
    required this.submittedAt,
    required this.status,
    required this.tasks,
    required this.totalScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'totalScore': totalScore,
    };
  }

  factory HomeworkSubmission.fromMap(Map<String, dynamic> map) {
    return HomeworkSubmission(
      userId: map['userId'] as String,
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      status: map['status'] as String,
      tasks: (map['tasks'] as List)
          .map((task) => TaskSubmission.fromMap(task as Map<String, dynamic>))
          .toList(),
      totalScore: (map['totalScore'] as num).toDouble(),
    );
  }
}

class TaskSubmission {
  final String taskId;
  final String answer;
  final String? photoUrl;
  final double? score;
  final String? feedback;

  TaskSubmission({
    required this.taskId,
    required this.answer,
    this.photoUrl,
    this.score,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'answer': answer,
      'photoUrl': photoUrl,
      'score': score,
      'feedback': feedback,
    };
  }

  factory TaskSubmission.fromMap(Map<String, dynamic> map) {
    return TaskSubmission(
      taskId: map['taskId'] as String,
      answer: map['answer'] as String,
      photoUrl: map['photoUrl'] as String?,
      score: map['score'] != null ? (map['score'] as num).toDouble() : null,
      feedback: map['feedback'] as String?,
    );
  }
}

class HomeworkComment {
  final String userId;
  final String text;
  final DateTime createdAt;
  final bool isPinned;

  HomeworkComment({
    required this.userId,
    required this.text,
    required this.createdAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPinned': isPinned,
    };
  }

  factory HomeworkComment.fromMap(Map<String, dynamic> map) {
    return HomeworkComment(
      userId: map['userId'] as String,
      text: map['text'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }
}

class Homework {
  final String homeworkId;
  final String title;
  final String description;
  final String classId;
  final String creatorId;
  final DateTime createdAt;
  final DateTime dueDate;
  final bool isActive;
  final double totalScore;
  final List<HomeworkTask> tasks;
  final List<HomeworkSubmission> submissions;
  final List<HomeworkComment> comments;

  Homework({
    required this.homeworkId,
    required this.title,
    required this.description,
    required this.classId,
    required this.creatorId,
    required this.createdAt,
    required this.dueDate,
    required this.isActive,
    required this.totalScore,
    required this.tasks,
    required this.submissions,
    required this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'classId': classId,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'isActive': isActive,
      'totalScore': totalScore,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'submissions': submissions.map((sub) => sub.toMap()).toList(),
      'comments': comments.map((comment) => comment.toMap()).toList(),
    };
  }

  factory Homework.fromMap(String id, Map<String, dynamic> map) {
    return Homework(
      homeworkId: id,
      title: map['title'] as String,
      description: map['description'] as String,
      classId: map['classId'] as String,
      creatorId: map['creatorId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isActive: map['isActive'] as bool,
      totalScore: (map['totalScore'] as num).toDouble(),
      tasks: (map['tasks'] as List)
          .map((task) => HomeworkTask.fromMap(task as Map<String, dynamic>))
          .toList(),
      submissions: (map['submissions'] as List)
          .map((sub) => HomeworkSubmission.fromMap(sub as Map<String, dynamic>))
          .toList(),
      comments: (map['comments'] as List)
          .map((comment) => HomeworkComment.fromMap(comment as Map<String, dynamic>))
          .toList(),
    );
  }
} 