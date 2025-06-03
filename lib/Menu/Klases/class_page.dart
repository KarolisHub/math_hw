import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Namų darbai/homework_page.dart';
import 'services/class_service.dart';
import 'class_members_page.dart';
import 'widgets/class_card.dart';
import 'widgets/join_class_form.dart';
import 'widgets/create_class_form.dart';

class ClassPage extends StatefulWidget {
  const ClassPage({Key? key}) : super(key: key);

  @override
  _ClassPageState createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClassService _classService = ClassService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _regenerateClassCode(String classId) async {
    try {
      String newCode = await _classService.regenerateClassCode(classId);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Naujas prisijungimo kodas sugeneruotas: $newCode'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sugeneruoti kodo nepavyko: ${e.toString()} bandykite dar kartą vėliau'))
      );
    }
  }

  Future<void> _leaveClass(String classId, String className) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Palikti klasę'),
        content: Text('Ar tikrai norite palikti klasę "$className"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Palikti'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await _classService.leaveClass(classId);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jūs palikote klasę "$className"'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepavyko palikti klasės: ${e.toString()} bandykite dar kartą vėliau'))
      );
    }
  }

  Future<void> _deleteClass(String classId, String className) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ištrinti klasę'),
        content: Text('Ar tikrai norite ištrinti klasę "$className"? Šis veiksmas negrįžtamas.'),
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
    ) ?? false;

    if (!confirm) return;

    try {
      await _classService.deleteClass(classId);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Klasė "$className" sėkmingai ištrinta'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepavyko ištrinti klasės: ${e.toString()}'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Klasės')),
        body: Center(
          child: Text('Prisijunkite norint matyti klases '),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mano klasės'),
        backgroundColor: const Color(0xFFFFA500),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Mano klasės'),
            Tab(text: 'Prisijungti/Sukurti'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFADD8E6),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Classes view
          StreamBuilder<QuerySnapshot>(
            stream: _classService.getUserClassesStream(),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (memberSnapshot.hasError) {
                return Center(child: Text('Klaida: ${memberSnapshot.error}'));
              }

              if (!memberSnapshot.hasData || memberSnapshot.data!.docs.isEmpty) {
                return Center(child: Text('Kol kas dar esat neprisijungę prie klasės'));
              }

              List<String> classIds = memberSnapshot.data!.docs
                  .map((doc) => doc['klases_id'] as String)
                  .toList();

              Map<String, String> roles = {};
              for (var doc in memberSnapshot.data!.docs) {
                roles[doc['klases_id'] as String] = doc['vartotojo_tipas'] as String;
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('klases')
                    .where(FieldPath.documentId, whereIn: classIds)
                    .snapshots(),
                builder: (context, classSnapshot) {
                  if (classSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (classSnapshot.hasError) {
                    return Center(child: Text('Klaida: ${classSnapshot.error}'));
                  }

                  if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Klasių nerasta'));
                  }

                  return ListView.builder(
                    itemCount: classSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot classDoc = classSnapshot.data!.docs[index];
                      Map<String, dynamic> classData = classDoc.data() as Map<String, dynamic>;
                      String classId = classDoc.id;
                      String role = roles[classId] ?? 'klases_dalyvis';
                      bool isCreator = role == 'klases_kurejas';

                      return ClassCard(
                        classId: classId,
                        className: classData['pavadinimas'],
                        joinCode: classData['prisijungimo_kodas'],
                        isCreator: isCreator,
                        onRegenerateCode: () => _regenerateClassCode(classId),
                        onManageMembers: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClassMembersPage(
                                classId: classId,
                                className: classData['pavadinimas'],
                              ),
                            ),
                          );
                        },
                        onDeleteClass: () => _deleteClass(classId, classData['pavadinimas']),
                        onLeaveClass: () => _leaveClass(classId, classData['pavadinimas']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeworkPage(
                                classId: classId,
                                className: classData['pavadinimas'],
                                isCreator: isCreator,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),

          // Tab 2: Join/Create Class
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JoinClassForm(
                  onSuccess: (className) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sėkmingai prisijungėte prie klasės: $className'))
                    );
                  },
                  onError: (error) {
                    setState(() {
                      _errorMessage = error;
                    });
                  },
                ),

                SizedBox(height: 24),

                CreateClassForm(
                  onSuccess: (joinCode) {
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Sukurta!'),
                          content: Text('Klasė sėkmingai sukurta! Prisijungimo kodas: $joinCode'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                FocusScope.of(context).unfocus(); // Ensure keyboard stays dismissed
                                Navigator.of(context).pop(); // Close dialog
                                setState(() {}); // Trigger refresh
                                _tabController.animateTo(0); // Switch to first tab
                              },
                              child: Text('Peržiūrėti klases'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                              },
                              child: Text('Gerai'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onError: (error) {
                    FocusScope.of(context).unfocus(); // Dismiss keyboard
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Klaida'),
                          content: Text(error),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close dialog
                              },
                              child: Text('Gerai'),
                            ),
                          ],
                        );
                      },
                    );
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
          ),
        ],
      ),
    );
  }
}