import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/homework_model.dart';
import '../services/homework_service.dart';

class CommentSection extends StatefulWidget {
  final String homeworkId;
  final List<HomeworkComment> comments;
  final VoidCallback onCommentAdded;

  const CommentSection({
    Key? key,
    required this.homeworkId,
    required this.comments,
    required this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _commentController = TextEditingController();
  final _homeworkService = HomeworkService();
  final _auth = FirebaseAuth.instance;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _homeworkService.addComment(
        homeworkId: widget.homeworkId,
        text: _commentController.text,
      );
      _commentController.clear();
      widget.onCommentAdded();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedComments = List<HomeworkComment>.from(widget.comments)
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Komentarai',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        if (_auth.currentUser != null) ...[
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              labelText: 'Rašyti komentarą',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor),
                        ),
                      )
                    : Icon(Icons.send),
                onPressed: _isSubmitting ? null : _submitComment,
              ),
            ),
            maxLines: 3,
            enabled: !_isSubmitting,
          ),
          if (_errorMessage != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(height: 16),
        ],
        if (sortedComments.isEmpty)
          Center(
            child: Text(
              'Dar nėra komentarų',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ...sortedComments.map((comment) {
            return Card(
              margin: EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (comment.isPinned)
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.push_pin,
                              size: 16,
                              color: Colors.orange,
                            ),
                          ),
                        Expanded(
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(comment.userId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final userData =
                                    snapshot.data!.data() as Map<String, dynamic>?;
                                return Text(
                                  userData?['name'] ?? 'Nežinomas vartotojas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: comment.userId == _auth.currentUser?.uid
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                );
                              }
                              return Text('Kraunama...');
                            },
                          ),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm')
                              .format(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(comment.text),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }
} 