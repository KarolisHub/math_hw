import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Klases/services/class_service.dart';
import 'services/homework_service.dart';
import 'models/homework_model.dart';
import 'widgets/homework_card.dart';
import 'widgets/create_homework_form.dart';
import 'homework_detail_page.dart';

class HomeworkPage extends StatefulWidget {
  final String classId;
  final String className;
  final bool isCreator;

  const HomeworkPage({
    Key? key,
    required this.classId,
    required this.className,
    required this.isCreator,
  }) : super(key: key);

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HomeworkService _homeworkService = HomeworkService();
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

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Namų darbai')),
        body: Center(
          child: Text('Prisijunkite norint matyti namų darbus'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: const Color(0xFFFFA500),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: widget.isCreator ? 'Aktyvūs namų darbai' : 'Neatlikti namų darbai'),
            Tab(text: widget.isCreator ? 'Neaktyvūs namų darbai' : 'Atlikti namų darbai'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Active/Current Homeworks
          StreamBuilder<List<Homework>>(
            stream: _homeworkService.getActiveHomeworksForClass(widget.classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Klaida: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Kol kas nėra namų darbų'),
                      if (widget.isCreator) ...[
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showCreateHomeworkDialog(context),
                          child: Text('Sukurti namų darbus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA500),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.length + (widget.isCreator ? 1 : 0),
                itemBuilder: (context, index) {
                  if (widget.isCreator && index == 0) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ElevatedButton(
                        onPressed: () => _showCreateHomeworkDialog(context),
                        child: Text('Sukurti namų darbus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                    );
                  }

                  final homework = snapshot.data![widget.isCreator ? index - 1 : index];
                  return HomeworkCard(
                    homework: homework,
                    isCreator: widget.isCreator,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeworkDetailPage(
                            homeworkId: homework.homeworkId,
                            isCreator: widget.isCreator,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          // Tab 2: Archived/Completed Homeworks
          StreamBuilder<List<Homework>>(
            stream: _homeworkService.getArchivedHomeworksForClass(widget.classId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Klaida: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Nėra atliktų namų darbų'));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final homework = snapshot.data![index];
                  return HomeworkCard(
                    homework: homework,
                    isCreator: widget.isCreator,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeworkDetailPage(
                            homeworkId: homework.homeworkId,
                            isCreator: widget.isCreator,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateHomeworkDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateHomeworkForm(classId: widget.classId),
    );

    if (result != null) {
      try {
        await _homeworkService.createHomework(
          title: result['title'],
          description: result['description'],
          classId: widget.classId,
          dueDate: result['dueDate'],
          tasks: result['tasks'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Namų darbai sėkmingai sukurti')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Klaida kuriant namų darbus: ${e.toString()}')),
        );
      }
    }
  }
}
