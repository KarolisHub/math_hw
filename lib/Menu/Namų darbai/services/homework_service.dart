import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/homework_model.dart';

class HomeworkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new homework
  Future<String> createHomework({
    required String title,
    required String description,
    required String classId,
    required DateTime dueDate,
    required List<HomeworkTask> tasks,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final homeworkRef = _firestore.collection('homeworks').doc();
    final totalScore = tasks.fold(0.0, (sum, task) => sum + (task.maxScore ?? 0.0));

    final homework = Homework(
      homeworkId: homeworkRef.id,
      title: title,
      description: description,
      classId: classId,
      creatorId: user.uid,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      isActive: true,
      totalScore: totalScore,
      tasks: tasks,
      submissions: [],
      comments: [],
    );

    await homeworkRef.set(homework.toMap());
    return homeworkRef.id;
  }

  // Get homework by ID
  Future<Homework> getHomework(String homeworkId) async {
    final doc = await _firestore.collection('homeworks').doc(homeworkId).get();
    if (!doc.exists) throw Exception('Homework not found');
    return Homework.fromMap(doc.id, doc.data()!);
  }

  // Get active homeworks for a class
  Stream<List<Homework>> getActiveHomeworksForClass(String classId) {
    return _firestore
        .collection('homeworks')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Homework.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get archived homeworks for a class
  Stream<List<Homework>> getArchivedHomeworksForClass(String classId) {
    return _firestore
        .collection('homeworks')
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: false)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Homework.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Submit homework
  Future<void> submitHomework({
    required String homeworkId,
    required List<TaskSubmission> taskSubmissions,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final homeworkRef = _firestore.collection('homeworks').doc(homeworkId);
    final homework = await getHomework(homeworkId);

    // Check if homework is active and not past due date
    if (!homework.isActive) throw Exception('Homework is not active');
    if (DateTime.now().isAfter(homework.dueDate)) {
      throw Exception('Homework submission deadline has passed');
    }

    // Check if user has already submitted
    bool hasSubmitted = false;
    try {
      homework.submissions.firstWhere((sub) => sub.userId == user.uid);
      hasSubmitted = true;
    } catch (e) {
      hasSubmitted = false;
    }

    if (hasSubmitted) {
      throw Exception('You have already submitted this homework');
    }

    final submission = HomeworkSubmission(
      userId: user.uid,
      submittedAt: DateTime.now(),
      status: 'SUBMITTED',
      tasks: taskSubmissions,
      totalScore: 0.0, // Will be updated when graded
    );

    await homeworkRef.update({
      'submissions': FieldValue.arrayUnion([submission.toMap()])
    });
  }

  // Upload photo for task submission
  Future<String> uploadTaskPhoto(String homeworkId, String taskId, File photo) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate file size (5MB limit)
    if (await photo.length() > 5 * 1024 * 1024) {
      throw Exception('Photo size must be less than 5MB');
    }

    try {
      // Log the attempt to upload
      print('Attempting to upload photo for homework: $homeworkId, task: $taskId');
      print('User ID: ${user.uid}');
      print('Storage bucket: ${_storage.app.options.storageBucket}');

      final path = 'homeworks/$homeworkId/tasks/$taskId/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Storage path: $path');
      
      final ref = _storage.ref().child(path);
      print('Storage reference created');

      // Create metadata with content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'homeworkId': homeworkId,
          'taskId': taskId,
        },
      );

      print('Starting upload with metadata...');
      
      // Upload file with metadata
      final uploadTask = ref.putFile(photo, metadata);
      
      // Monitor upload state
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload state: ${snapshot.state}');
        print('Bytes transferred: ${snapshot.bytesTransferred}');
        print('Total bytes: ${snapshot.totalBytes}');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      print('Upload completed successfully');
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } catch (e, stackTrace) {
      print('Error uploading photo: $e');
      print('Stack trace: $stackTrace');
      
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
        print('Firebase error plugin: ${e.plugin}');
      }
      
      throw Exception('Failed to upload photo: ${e.toString()}');
    }
  }

  // Grade homework submission
  Future<void> gradeSubmission({
    required String homeworkId,
    required String userId,
    required List<TaskSubmission> gradedTasks,
    required double totalScore,
  }) async {
    final homeworkRef = _firestore.collection('homeworks').doc(homeworkId);
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Only the homework creator can grade submissions');
    }

    // Find and update the submission
    final submissions = homework.submissions;
    final submissionIndex = submissions.indexWhere((sub) => sub.userId == userId);
    if (submissionIndex == -1) throw Exception('Submission not found');

    final updatedSubmission = HomeworkSubmission(
      userId: userId,
      submittedAt: submissions[submissionIndex].submittedAt,
      status: 'GRADED',
      tasks: gradedTasks,
      totalScore: totalScore,
    );

    submissions[submissionIndex] = updatedSubmission;

    await homeworkRef.update({
      'submissions': submissions.map((sub) => sub.toMap()).toList()
    });
  }

  // Add comment to homework
  Future<void> addComment({
    required String homeworkId,
    required String text,
    bool isPinned = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final homeworkRef = _firestore.collection('homeworks').doc(homeworkId);
    final homework = await getHomework(homeworkId);

    // Verify user is either the creator or a class member
    if (user.uid != homework.creatorId) {
      // TODO: Add check for class membership
      // For now, we'll allow any authenticated user to comment
    }

    final comment = HomeworkComment(
      userId: user.uid,
      text: text,
      createdAt: DateTime.now(),
      isPinned: isPinned,
    );

    await homeworkRef.update({
      'comments': FieldValue.arrayUnion([comment.toMap()])
    });
  }

  // Update homework deadline
  Future<void> updateHomeworkDeadline({
    required String homeworkId,
    required DateTime newDueDate,
  }) async {
    final homeworkRef = _firestore.collection('homeworks').doc(homeworkId);
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Only the homework creator can update the deadline');
    }

    await homeworkRef.update({
      'dueDate': Timestamp.fromDate(newDueDate),
      'isActive': true, // Reactivate homework when deadline is updated
    });
  }

  // Archive homework
  Future<void> archiveHomework(String homeworkId) async {
    final homeworkRef = _firestore.collection('homeworks').doc(homeworkId);
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Only the homework creator can archive homework');
    }

    await homeworkRef.update({'isActive': false});
  }

  // Delete homework
  Future<void> deleteHomework(String homeworkId) async {
    final homeworkRef = _firestore.collection('homeworks').doc(homeworkId);
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Only the homework creator can delete homework');
    }

    // Delete all associated photos
    for (var submission in homework.submissions) {
      for (var task in submission.tasks) {
        if (task.photoUrl != null) {
          try {
            final photoRef = _storage.refFromURL(task.photoUrl!);
            await photoRef.delete();
          } catch (e) {
            // Log error but continue with deletion
            print('Error deleting photo: $e');
          }
        }
      }
    }

    // Delete the homework document
    await homeworkRef.delete();
  }
} 