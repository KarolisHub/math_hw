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
      throw Exception("Vartotojas neprisijungęs");
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
      throw Exception("Vartotojas neprisijungęs");
    }

    QuerySnapshot query = await _firestore.collection('classes')
        .where('join_code', isEqualTo: code)
        .where('is_active', isEqualTo: true)
        .where('code_expiry_date', isGreaterThan: Timestamp.now())
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Nerasta klasių su šiuo kodu. Patikrinkite ar gerai suvedėte kodą");
    }

    DocumentSnapshot classDoc = query.docs.first;
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['current_member_count'] >= classData['max_members']) {
      throw Exception("Klasė yra pilna");
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classDoc.id)
        .where('user_id', isEqualTo: currentUser.uid)
        .get();

    if (memberQuery.docs.isNotEmpty) {
      throw Exception("Tu jau esi šios klasės dalyvis");
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
      throw Exception("Vartotojas neprisijungęs");
    }

    DocumentSnapshot classDoc = await _firestore.collection('classes').doc(classId).get();
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['creator_id'] != currentUser.uid) {
      throw Exception('Tik klasės kūrėjas gali atnaujinti kodą');
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
      throw Exception("Vartotojas neprisijungęs");
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classId)
        .where('user_id', isEqualTo: currentUser.uid)
        .get();

    if (memberQuery.docs.isEmpty) {
      throw Exception("Jūs neesate šios klasės dalyvis");
    }

    String role = memberQuery.docs.first.get('role');
    if (role == 'creator') {
      throw Exception("Negalite palikti šios klasės, nes esate jos kūrėjas");
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
      throw Exception("Vartotojas neprisijungęs");
    }

    DocumentSnapshot classDoc = await _firestore.collection('classes').doc(classId).get();
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['creator_id'] != currentUser.uid) {
      throw Exception('Tik klasės kūrėjas gali pašalinti dalyvį');
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('class_members')
        .where('class_id', isEqualTo: classId)
        .where('user_id', isEqualTo: userId)
        .get();

    if (memberQuery.docs.isEmpty) {
      throw Exception("Jūs neesate šios klasės dalyvis");
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
      throw Exception("Vartotojas neprisijungęs");
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
      throw Exception("Vartotojas neprisijungęs");
    }

    // Get class document to verify creator
    DocumentSnapshot classDoc = await _firestore.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      throw Exception("Klasė nerasta");
    }

    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
    if (classData['creator_id'] != currentUser.uid) {
      throw Exception("Tik klasės kūrėjas gali ištrinti klasę");
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