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
          .collection('klases')
          .where('prisijungimo_kodas', isEqualTo: code)
          .where('aktyvumas', isEqualTo: true)
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

    DocumentReference classRef = await _firestore.collection('klases').add({
      'pavadinimas': className.trim(),
      'kurejo_id': currentUser.uid,
      'prisijungimo_kodas': joinCode,
      'kodo_galiojimo_data': Timestamp.fromDate(expiryDate),
      'sukurimo_data': Timestamp.now(),
      'aktyvumas': true,
      'maksimalus_nariu_skaicius': 100,
      'dabartinis_nariu_skaicius': 1,
    });

    await _firestore.collection('klases_nariai').add({
      'klases_id': classRef.id,
      'vartotojo_id': currentUser.uid,
      'vartotojo_tipas': 'klases_kurejas',
      'prisijungta': Timestamp.now(),
    });

    return joinCode;
  }

  // Join a class using a code
  Future<String> joinClass(String code) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Vartotojas neprisijungęs");
    }

    QuerySnapshot query = await _firestore.collection('klases')
        .where('prisijungimo_kodas', isEqualTo: code)
        .where('aktyvumas', isEqualTo: true)
        .where('kodo_galiojimo_data', isGreaterThan: Timestamp.now())
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Nerasta klasių su šiuo kodu. Patikrinkite ar gerai suvedėte kodą");
    }

    DocumentSnapshot classDoc = query.docs.first;
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['dabartinis_nariu_skaicius'] >= classData['maksimalus_nariu_skaicius']) {
      throw Exception("Klasė yra pilna");
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('klases_nariai')
        .where('klases_id', isEqualTo: classDoc.id)
        .where('vartotojo_id', isEqualTo: currentUser.uid)
        .get();

    if (memberQuery.docs.isNotEmpty) {
      throw Exception("Tu jau esi šios klasės dalyvis");
    }

    await _firestore.collection('klases_nariai').add({
      'klases_id': classDoc.id,
      'vartotojo_id': currentUser.uid,
      'vartotojo_tipas': 'klases_dalyvis',
      'prisijungta': Timestamp.now(),
    });

    await _firestore.collection('klases').doc(classDoc.id).update({
      'dabartinis_nariu_skaicius': FieldValue.increment(1)
    });

    return classData['pavadinimas'];
  }

  // Regenerate class code
  Future<String> regenerateClassCode(String classId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Vartotojas neprisijungęs");
    }

    DocumentSnapshot classDoc = await _firestore.collection('klases').doc(classId).get();
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['kurejo_id'] != currentUser.uid) {
      throw Exception('Tik klasės kūrėjas gali atnaujinti kodą');
    }

    String newCode = await generateUniqueClassCode();
    DateTime newExpiryDate = DateTime.now().add(Duration(days: 7));

    await _firestore.collection('klases').doc(classId).update({
      'prisijungimo_kodas': newCode,
      'kodo_galiojimo_data': Timestamp.fromDate(newExpiryDate),
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
        .collection('klases_nariai')
        .where('klases_id', isEqualTo: classId)
        .where('vartotojo_id', isEqualTo: currentUser.uid)
        .get();

    if (memberQuery.docs.isEmpty) {
      throw Exception("Jūs neesate šios klasės dalyvis");
    }

    String role = memberQuery.docs.first.get('vartotojo_tipas');
    if (role == 'klases_kurejas') {
      throw Exception("Negalite palikti šios klasės, nes esate jos kūrėjas");
    }

    await _firestore.collection('klases_nariai')
        .doc(memberQuery.docs.first.id)
        .delete();

    await _firestore.collection('klases').doc(classId).update({
      'dabartinis_nariu_skaicius': FieldValue.increment(-1)
    });
  }

  // Remove a member from class
  Future<void> removeMember(String classId, String userId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Vartotojas neprisijungęs");
    }

    DocumentSnapshot classDoc = await _firestore.collection('klases').doc(classId).get();
    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;

    if (classData['kurejo_id'] != currentUser.uid) {
      throw Exception('Tik klasės kūrėjas gali pašalinti dalyvį');
    }

    QuerySnapshot memberQuery = await _firestore
        .collection('klases_nariai')
        .where('klases_id', isEqualTo: classId)
        .where('vartotojo_id', isEqualTo: userId)
        .get();

    if (memberQuery.docs.isEmpty) {
      throw Exception("Jūs neesate šios klasės dalyvis");
    }

    await _firestore.collection('klases_nariai')
        .doc(memberQuery.docs.first.id)
        .delete();

    await _firestore.collection('klases').doc(classId).update({
      'dabartinis_nariu_skaicius': FieldValue.increment(-1)
    });
  }

  // Get user's classes stream
  Stream<QuerySnapshot> getUserClassesStream() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Vartotojas neprisijungęs");
    }

    return _firestore
        .collection('klases_nariai')
        .where('vartotojo_id', isEqualTo: currentUser.uid)
        .snapshots();
  }

  // Get class members stream
  Stream<QuerySnapshot> getClassMembersStream(String classId) {
    return _firestore
        .collection('klases_nariai')
        .where('klases_id', isEqualTo: classId)
        .snapshots();
  }

  // Delete a class
  Future<void> deleteClass(String classId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Vartotojas neprisijungęs");
    }

    // Get class document to verify creator
    DocumentSnapshot classDoc = await _firestore.collection('klases').doc(classId).get();
    if (!classDoc.exists) {
      throw Exception("Klasė nerasta");
    }

    Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
    if (classData['kurejo_id'] != currentUser.uid) {
      throw Exception("Tik klasės kūrėjas gali ištrinti klasę");
    }

    // Use a batch write to ensure atomicity
    WriteBatch batch = _firestore.batch();

    // Delete all class members
    QuerySnapshot memberQuery = await _firestore
        .collection('klases_nariai')
        .where('klases_id', isEqualTo: classId)
        .get();

    // Add member deletions to batch
    for (var doc in memberQuery.docs) {
      batch.delete(doc.reference);
    }

    // Add class deletion to batch
    batch.delete(classDoc.reference);

    // Commit the batch
    await batch.commit();
  }
} 