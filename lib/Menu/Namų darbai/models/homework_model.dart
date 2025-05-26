import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkTask {
  final String id;
  final String title;
  final String description;
  final String type;
  final double? maxScore;
  final String? photoUrl;
  final String? mathpixResponse;
  final bool photoRequired;
  final String taskType;
  final String? latexContent;

  HomeworkTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.maxScore,
    this.photoUrl,
    this.mathpixResponse,
    required this.photoRequired,
    required this.taskType,
    this.latexContent,
  });

  // Add getter for taskId to maintain backward compatibility
  String get taskId => id;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pavadinimas': title,
      'aprasymas': description,
      'tipas': type,
      'maksimalus_balas': maxScore,
      'nuotraukos_url': photoUrl,
      'mathpix_atsakymas': mathpixResponse,
      'reikalinga_nuotrauka': photoRequired,
      'uzduoties_tipas': taskType,
      'latex_turinys': latexContent,
    };
  }

  factory HomeworkTask.fromMap(Map<String, dynamic> map) {
    return HomeworkTask(
      id: map['id'] as String,
      title: map['pavadinimas'] as String,
      description: map['aprasymas'] as String,
      type: map['tipas'] as String,
      maxScore: map['maksimalus_balas'] != null ? (map['maksimalus_balas'] as num).toDouble() : null,
      photoUrl: map['nuotraukos_url'] as String?,
      mathpixResponse: map['mathpix_atsakymas'] as String?,
      photoRequired: map['reikalinga_nuotrauka'] as bool,
      taskType: map['uzduoties_tipas'] as String,
      latexContent: map['latex_turinys'] as String?,
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
  final String? answer;
  final String? photoUrl;
  final double? score;
  final String? feedback;
  final String? mathpixResponse;
  final String answerType;
  final String? latexContent;

  TaskSubmission({
    required this.taskId,
    this.answer,
    this.photoUrl,
    this.score,
    this.feedback,
    this.mathpixResponse,
    required this.answerType,
    this.latexContent,
  });

  Map<String, dynamic> toMap() {
    return {
      'uzduoties_id': taskId,
      'atsakymas': answer,
      'nuotraukos_url': photoUrl,
      'balas': score,
      'atsiliepimas': feedback,
      'mathpix_atsakymas': mathpixResponse,
      'atsakymo_tipas': answerType,
      'latex_turinys': latexContent,
    };
  }

  factory TaskSubmission.fromMap(Map<String, dynamic> map) {
    return TaskSubmission(
      taskId: map['uzduoties_id'] as String,
      answer: map['atsakymas'] as String?,
      photoUrl: map['nuotraukos_url'] as String?,
      score: map['balas'] != null ? (map['balas'] as num).toDouble() : null,
      feedback: map['atsiliepimas'] as String?,
      mathpixResponse: map['mathpix_atsakymas'] as String?,
      answerType: map['atsakymo_tipas'] as String,
      latexContent: map['latex_turinys'] as String?,
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
      'vartotojo_id': userId,
      'tekstas': text,
      'sukurimo_data': Timestamp.fromDate(createdAt),
      'prisegtas': isPinned,
    };
  }

  factory HomeworkComment.fromMap(Map<String, dynamic> map) {
    return HomeworkComment(
      userId: map['vartotojo_id'] as String,
      text: map['tekstas'] as String,
      createdAt: (map['sukurimo_data'] as Timestamp).toDate(),
      isPinned: map['prisegtas'] as bool? ?? false,
    );
  }
}

class Homework {
  final String id;
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
    required this.id,
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

  // Add getter for homeworkId to maintain backward compatibility
  String get homeworkId => id;

  Map<String, dynamic> toMap() {
    return {
      'pavadinimas': title,
      'aprasymas': description,
      'klases_id': classId,
      'kurejo_id': creatorId,
      'sukurimo_data': Timestamp.fromDate(createdAt),
      'terminas': Timestamp.fromDate(dueDate),
      'aktyvus': isActive,
      'bendras_balas': totalScore,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'submissions': submissions.map((submission) => submission.toMap()).toList(),
      'comments': comments.map((comment) => comment.toMap()).toList(),
    };
  }

  factory Homework.fromMap(String id, Map<String, dynamic> map) {
    return Homework(
      id: id,
      title: map['pavadinimas'] as String,
      description: map['aprasymas'] as String,
      classId: map['klases_id'] as String,
      creatorId: map['kurejo_id'] as String,
      createdAt: (map['sukurimo_data'] as Timestamp).toDate(),
      dueDate: (map['terminas'] as Timestamp).toDate(),
      isActive: map['aktyvus'] as bool,
      totalScore: (map['bendras_balas'] as num).toDouble(),
      tasks: (map['tasks'] as List<dynamic>)
          .map((task) => HomeworkTask.fromMap(task as Map<String, dynamic>))
          .toList(),
      submissions: (map['submissions'] as List<dynamic>)
          .map((submission) => HomeworkSubmission.fromMap(submission as Map<String, dynamic>))
          .toList(),
      comments: (map['comments'] as List<dynamic>)
          .map((comment) => HomeworkComment.fromMap(comment as Map<String, dynamic>))
          .toList(),
    );
  }
} 