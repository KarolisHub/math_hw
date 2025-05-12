import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate a unique 6-digit code
  Future<String> generateUniqueClassCode() async {
    final Random _random = Random();

    while (true) {
      String code = (_random.nextInt(900000) + 100000).toString();

      QuerySnapshot query = await _firestore
          .collection('classes')
          .where('join_code', isEqualTo: code)
          .where('is_active', isEqualTo: true)
          .get();

      if (query.docs.isEmpty) {
        return code;
      }
    }
  }

  // Create a new class
  Future<String> createClass(String className) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    String joinCode = await generateUniqueClassCode();
    DateTime expiryDate = DateTime.now().add(Duration(days: 7));

    DocumentReference classRef = await _firestore.collection('classes').add({
      'name': className.trim(),
      'creator_id': currentUser.uid,
      'join_code': joinCode,
      'code_expiry_date': Timestamp.fromDate(expiryDate),
      'created_at': Timestamp.now(),
      'is_active': true,
      'max_members': 100,
      'current_member_count': 1,
    });

    await _firestore.collection('class_members').add({
      'user_id': currentUser.uid,
      'class_id': classRef.id,
      'role': 'creator',
      'joined_at': Timestamp.now(),
    });

    return joinCode;
  }

  // Join a class using a code
  Future<String> joinClass(String code) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    QuerySnapshot query = await _firestore.collection('classes')
        .where('join_code', isEqualTo: code)
        .where('is_active', isEqualTo: true)
        .where('code_expiry_date', isGreaterThan: Timestamp.now())
        .get();

    if (query.docs.isEmpty) {
      throw Exception("No active class found with this code");
    }

    DocumentSnapshot classDoc = query.docs.first;
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['current_member_count'] >= classData['max_members']) {
      throw Exception("Class is full");
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classDoc.id)
        .where('user_id', isEqualTo: currentUser.uid)
        .get();

    if (memberQuery.docs.isNotEmpty) {
      throw Exception("You are already a member of this class");
    }

    await _firestore.collection('class_members').add({
      'user_id': currentUser.uid,
      'class_id': classDoc.id,
      'role': 'member',
      'joined_at': Timestamp.now(),
    });

    await _firestore.collection('classes').doc(classDoc.id).update({
      'current_member_count': FieldValue.increment(1)
    });

    return classData['name'];
  }

  // Regenerate class code
  Future<String> regenerateClassCode(String classId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    DocumentSnapshot classDoc = await _firestore.collection('classes').doc(classId).get();
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['creator_id'] != currentUser.uid) {
      throw Exception('Only the class creator can regenerate the join code');
    }

    String newCode = await generateUniqueClassCode();
    DateTime newExpiryDate = DateTime.now().add(Duration(days: 7));

    await _firestore.collection('classes').doc(classId).update({
      'join_code': newCode,
      'code_expiry_date': Timestamp.fromDate(newExpiryDate),
    });

    return newCode;
  }

  // Leave a class
  Future<void> leaveClass(String classId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classId)
        .where('user_id', isEqualTo: currentUser.uid)
        .get();

    if (memberQuery.docs.isEmpty) {
      throw Exception("You are not a member of this class");
    }

    String role = memberQuery.docs.first.get('role');
    if (role == 'creator') {
      throw Exception("As the creator, you cannot leave the class. You can delete it instead.");
    }

    await _firestore.collection('class_members')
        .doc(memberQuery.docs.first.id)
        .delete();

    await _firestore.collection('classes').doc(classId).update({
      'current_member_count': FieldValue.increment(-1)
    });
  }

  // Remove a member from class
  Future<void> removeMember(String classId, String userId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    DocumentSnapshot classDoc = await _firestore.collection('classes').doc(classId).get();
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['creator_id'] != currentUser.uid) {
      throw Exception('Only the class creator can remove members');
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classId)
        .where('user_id', isEqualTo: userId)
        .get();

    if (memberQuery.docs.isEmpty) {
      throw Exception("User is not a member of this class");
    }

    await _firestore.collection('class_members')
        .doc(memberQuery.docs.first.id)
        .delete();

    await _firestore.collection('classes').doc(classId).update({
      'current_member_count': FieldValue.increment(-1)
    });
  }

  // Get user's classes stream
  Stream<QuerySnapshot> getUserClassesStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    return _firestore
        .collection('class_members')
        .where('user_id', isEqualTo: currentUser.uid)
        .snapshots();
  }

  // Get class members stream
  Stream<QuerySnapshot> getClassMembersStream(String classId) {
    return _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classId)
        .snapshots();
  }

  // Delete a class
  Future<void> deleteClass(String classId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    // Get class document to verify creator
    DocumentSnapshot classDoc = await _firestore.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      throw Exception("Class not found");
    }

    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
    if (classData['creator_id'] != currentUser.uid) {
      throw Exception("Only the class creator can delete the class");
    }

    // Delete all class members
    QuerySnapshot memberQuery = await _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classId)
        .get();

    // Delete each member document
    for (var doc in memberQuery.docs) {
      await doc.reference.delete();
    }

    // Delete the class document
    await classDoc.reference.delete();
  }
} 