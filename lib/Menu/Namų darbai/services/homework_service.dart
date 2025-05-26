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
    if (user == null) throw Exception('Nepavyko nustatyti vartotojo');

    final homeworkRef = _firestore.collection('namu_darbai').doc();
    final totalScore = tasks.fold(0.0, (sum, task) => sum + (task.maxScore ?? 0.0));

    // Create homework document
    await homeworkRef.set({
      'pavadinimas': title,
      'aprasymas': description,
      'klases_id': classId,
      'kurejo_id': user.uid,
      'sukurimo_data': Timestamp.fromDate(DateTime.now()),
      'terminas': Timestamp.fromDate(dueDate),
      'aktyvus': true,
      'bendras_balas': totalScore,
    });

    // Create tasks in separate collection
    for (var task in tasks) {
      await _firestore.collection('namu_darbo_uzduotys').add({
        ...task.toMap(),
        'namu_darbo_id': homeworkRef.id,
      });
    }

    return homeworkRef.id;
  }

  // Get homework by ID
  Future<Homework> getHomework(String homeworkId) async {
    final homeworkDoc = await _firestore.collection('namu_darbai').doc(homeworkId).get();
    if (!homeworkDoc.exists) throw Exception('Namų darbas nerastas');

    // Get tasks
    final tasksSnapshot = await _firestore
        .collection('namu_darbo_uzduotys')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .get();
    final tasks = tasksSnapshot.docs
        .map((doc) => HomeworkTask.fromMap(doc.data()))
        .toList();

    // Get submissions
    final submissionsSnapshot = await _firestore
        .collection('namu_darbo_pateikimai')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .get();
    
    final submissions = <HomeworkSubmission>[];
    for (var submissionDoc in submissionsSnapshot.docs) {
      final submissionData = submissionDoc.data();
      
      // Get task submissions for this submission
      final taskSubmissionsSnapshot = await _firestore
          .collection('uzduoties_atsakymai')
          .where('pateikimo_id', isEqualTo: submissionDoc.id)
          .get();
      
      final taskSubmissions = taskSubmissionsSnapshot.docs
          .map((doc) => TaskSubmission.fromMap(doc.data()))
          .toList();

      submissions.add(HomeworkSubmission(
        userId: submissionData['vartotojo_id'] as String,
        submittedAt: (submissionData['pateikimo_data'] as Timestamp).toDate(),
        status: submissionData['busena'] as String,
        tasks: taskSubmissions,
        totalScore: (submissionData['bendras_balas'] as num).toDouble(),
      ));
    }

    // Get comments
    final commentsSnapshot = await _firestore
        .collection('namu_darbo_komentarai')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .get();
    final comments = commentsSnapshot.docs
        .map((doc) => HomeworkComment.fromMap(doc.data()))
        .toList();

    return Homework.fromMap(
      homeworkId,
      {
        ...homeworkDoc.data()!,
        'tasks': tasks.map((t) => t.toMap()).toList(),
        'submissions': submissions.map((s) => s.toMap()).toList(),
        'comments': comments.map((c) => c.toMap()).toList(),
      },
    );
  }

  // Get active homeworks for a class
  Stream<List<Homework>> getActiveHomeworksForClass(String classId) {
    return _firestore
        .collection('namu_darbai')
        .where('klases_id', isEqualTo: classId)
        .where('aktyvus', isEqualTo: true)
        .orderBy('terminas')
        .snapshots()
        .asyncMap((snapshot) async {
          final homeworks = <Homework>[];
          for (var doc in snapshot.docs) {
            homeworks.add(await getHomework(doc.id));
          }
          return homeworks;
        });
  }

  // Get archived homeworks for a class
  Stream<List<Homework>> getArchivedHomeworksForClass(String classId) {
    return _firestore
        .collection('namu_darbai')
        .where('klases_id', isEqualTo: classId)
        .where('aktyvus', isEqualTo: false)
        .orderBy('terminas', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final homeworks = <Homework>[];
          for (var doc in snapshot.docs) {
            homeworks.add(await getHomework(doc.id));
          }
          return homeworks;
        });
  }

  // Submit homework
  Future<void> submitHomework({
    required String homeworkId,
    required List<TaskSubmission> taskSubmissions,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nepavyko nustatyti vartotojo');

    final homework = await getHomework(homeworkId);

    // Check if homework is active and not past due date
    if (!homework.isActive) throw Exception('Namų darbas yra neaktyvus');
    if (DateTime.now().isAfter(homework.dueDate)) {
      throw Exception('Namų darbo atlikimo laikas baigtas');
    }

    // Check if user has already submitted
    final existingSubmission = await _firestore
        .collection('namu_darbo_pateikimai')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .where('vartotojo_id', isEqualTo: user.uid)
        .get();

    if (existingSubmission.docs.isNotEmpty) {
      throw Exception('Jau esate pateikę šį namų darbą');
    }

    // Create submission document
    final submissionRef = await _firestore.collection('namu_darbo_pateikimai').add({
      'vartotojo_id': user.uid,
      'namu_darbo_id': homeworkId,
      'pateikimo_data': Timestamp.fromDate(DateTime.now()),
      'busena': 'PATEIKTA',
      'bendras_balas': 0.0,
    });

    // Create task submissions
    for (var taskSubmission in taskSubmissions) {
      await _firestore.collection('uzduoties_atsakymai').add({
        ...taskSubmission.toMap(),
        'pateikimo_id': submissionRef.id,
        'namu_darbo_id': homeworkId,
        'vartotojo_id': user.uid,
      });
    }

    // Update homework status
    await _firestore.collection('namu_darbai').doc(homeworkId).update({
      'aktyvus': false,
    });
  }

  // Upload photo for task submission
  Future<String> uploadTaskPhoto(String homeworkId, String taskId, File photo) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nepavyko nustatyti vartotojo');

    // Validate file size (5MB limit)
    if (await photo.length() > 5 * 1024 * 1024) {
      throw Exception('Nuotraukos dydis turi būti mažesnis nei 5MB');
    }

    try {
      final path = 'namu_darbai/$homeworkId/uzduotys/$taskId/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(path);
      
      // Create metadata with content type
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'namu_darbo_id': homeworkId,
          'uzduoties_id': taskId,
        },
      );
      
      // Upload file with metadata
      final uploadTask = ref.putFile(photo, metadata);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
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
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Tik klasės vartotojas gali vertinti namų darbą');
    }

    // Find the submission
    final submissionQuery = await _firestore
        .collection('namu_darbo_pateikimai')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .where('vartotojo_id', isEqualTo: userId)
        .get();

    if (submissionQuery.docs.isEmpty) {
      throw Exception('Pateikimas nerastas');
    }

    final submissionDoc = submissionQuery.docs.first;

    // Update task submissions
    for (var task in gradedTasks) {
      final taskSubmissionQuery = await _firestore
          .collection('uzduoties_atsakymai')
          .where('pateikimo_id', isEqualTo: submissionDoc.id)
          .where('uzduoties_id', isEqualTo: task.taskId)
          .get();

      if (taskSubmissionQuery.docs.isNotEmpty) {
        await taskSubmissionQuery.docs.first.reference.update({
          'balas': task.score,
          'atsiliepimas': task.feedback,
        });
      }
    }

    // Update submission status and total score
    await submissionDoc.reference.update({
      'busena': 'IVERTINTA',
      'bendras_balas': totalScore,
    });
  }

  // Add comment to homework
  Future<void> addComment({
    required String homeworkId,
    required String text,
    bool isPinned = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Nepavyko nustatyti vartotojo');

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

    await _firestore.collection('namu_darbo_komentarai').add({
      ...comment.toMap(),
      'namu_darbo_id': homeworkId,
    });
  }

  // Update homework deadline
  Future<void> updateHomeworkDeadline({
    required String homeworkId,
    required DateTime newDueDate,
  }) async {
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Tik namų darbo kūrėjas gali atnaujinti laiką');
    }

    await _firestore.collection('namu_darbai').doc(homeworkId).update({
      'terminas': Timestamp.fromDate(newDueDate),
      'aktyvus': true,
    });
  }

  // Archive homework
  Future<void> archiveHomework(String homeworkId) async {
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Tik namų darbo kūrėjas gali archyvuoti namų darbą');
    }

    await _firestore.collection('namu_darbai').doc(homeworkId).update({
      'aktyvus': false,
    });
  }

  // Delete homework
  Future<void> deleteHomework(String homeworkId) async {
    final homework = await getHomework(homeworkId);

    // Verify user is the creator
    if (_auth.currentUser?.uid != homework.creatorId) {
      throw Exception('Tik namų darbo kūrėjas gali ištrinti namų darbą');
    }

    // Delete all associated photos
    for (var submission in homework.submissions) {
      for (var task in submission.tasks) {
        if (task.photoUrl != null) {
          try {
            final photoRef = _storage.refFromURL(task.photoUrl!);
            await photoRef.delete();
          } catch (e) {
            print('Nepavyko ištrinti nuotraukos: $e. Bandykite vėliau');
          }
        }
      }
    }

    // Delete all related documents
    final batch = _firestore.batch();

    // Delete tasks
    final tasksSnapshot = await _firestore
        .collection('namu_darbo_uzduotys')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .get();
    for (var doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete submissions and their task submissions
    final submissionsSnapshot = await _firestore
        .collection('namu_darbo_pateikimai')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .get();
    
    for (var submissionDoc in submissionsSnapshot.docs) {
      // Delete task submissions
      final taskSubmissionsSnapshot = await _firestore
          .collection('uzduoties_atsakymai')
          .where('pateikimo_id', isEqualTo: submissionDoc.id)
          .get();
      for (var doc in taskSubmissionsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete submission
      batch.delete(submissionDoc.reference);
    }

    // Delete comments
    final commentsSnapshot = await _firestore
        .collection('namu_darbo_komentarai')
        .where('namu_darbo_id', isEqualTo: homeworkId)
        .get();
    for (var doc in commentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the homework document
    batch.delete(_firestore.collection('namu_darbai').doc(homeworkId));

    await batch.commit();
  }
} 