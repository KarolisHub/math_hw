import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/class_service.dart';

class ClassMembersPage extends StatefulWidget {
  final String classId;
  final String className;

  const ClassMembersPage({
    Key? key,
    required this.classId,
    required this.className,
  }) : super(key: key);

  @override
  _ClassMembersPageState createState() => _ClassMembersPageState();
}

class _ClassMembersPageState extends State<ClassMembersPage> {
  final ClassService _classService = ClassService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _removeMember(String userId, String userName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pašalinti vartotoją'),
        content: Text('Ar tikrai norite pašalinti vartotoją $userName iš klasės?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Atšaukti'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Pašalinti'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await _classService.removeMember(widget.classId, userId);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vartotojas pašalintas sėkmingai'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nepavyko pašalinti vartotojo: ${e.toString()}. Bandykite vėliau dar kartą'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Vartotojai'),
      ),
      body: currentUser == null
          ? Center(child: Text('Prašome prisijungti norint matyti klasės vartotojus'))
          : StreamBuilder<QuerySnapshot>(
        stream: _classService.getClassMembersStream(widget.classId),
        builder: (context, memberSnapshot) {
          if (memberSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (memberSnapshot.hasError) {
            return Center(child: Text('Klaida: ${memberSnapshot.error}'));
          }

          if (!memberSnapshot.hasData || memberSnapshot.data!.docs.isEmpty) {
            return Center(child: Text('Vartotojų nerasta'));
          }

          List<String> userIds = memberSnapshot.data!.docs
              .map((doc) => doc['user_id'] as String)
              .toList();

          Map<String, String> roles = {};
          for (var doc in memberSnapshot.data!.docs) {
            roles[doc['user_id'] as String] = doc['role'] as String;
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: userIds)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError) {
                return Center(child: Text('Klaida: ${userSnapshot.error}'));
              }

              if (!userSnapshot.hasData) {
                return Center(child: Text('Vartotojo informacija nerasta'));
              }

              Map<String, Map<String, dynamic>> userInfo = {};
              for (var doc in userSnapshot.data!.docs) {
                userInfo[doc.id] = doc.data() as Map<String, dynamic>;
              }

              return ListView.builder(
                itemCount: memberSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot memberDoc = memberSnapshot.data!.docs[index];
                  String userId = memberDoc['user_id'];
                  String role = memberDoc['role'];
                  String name = userInfo[userId]?['name'] as String? ?? 'Unknown User';
                  bool isCreator = role == 'creator';
                  bool isSelf = userId == currentUser.uid;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                    ),
                    title: Text(name),
                    subtitle: Text(isCreator ? 'Kūrėjas' : 'Dalyvis'),
                    trailing: !isSelf && !isCreator
                        ? IconButton(
                      icon: Icon(Icons.remove_circle_outline),
                      tooltip: 'Pašalinti dalyvį',
                      onPressed: () => _removeMember(userId, name),
                    )
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 