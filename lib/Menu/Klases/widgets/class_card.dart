import 'package:flutter/material.dart';
import '../services/class_service.dart';

class ClassCard extends StatelessWidget {
  final String classId;
  final String className;
  final String joinCode;
  final bool isCreator;
  final VoidCallback onRegenerateCode;
  final VoidCallback onManageMembers;
  final VoidCallback onDeleteClass;
  final VoidCallback onLeaveClass;
  final VoidCallback onTap;

  const ClassCard({
    Key? key,
    required this.classId,
    required this.className,
    required this.joinCode,
    required this.isCreator,
    required this.onRegenerateCode,
    required this.onManageMembers,
    required this.onDeleteClass,
    required this.onLeaveClass,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(className),
        subtitle: Text(isCreator
            ? 'Jūsų sukurta klasė • Kodas: $joinCode'
            : 'Jūs esate šios klasės dalyvis'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'regenerate':
                onRegenerateCode();
                break;
              case 'manage':
                onManageMembers();
                break;
              case 'delete':
                onDeleteClass();
                break;
              case 'leave':
                onLeaveClass();
                break;
            }
          },
          itemBuilder: (context) => [
            if (isCreator) ...[
              const PopupMenuItem(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Atnaujinti kodą'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'manage',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Tvarkyti narius'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Ištrinti klasę', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ] else
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 20),
                    SizedBox(width: 8),
                    Text('Palikti klasę'),
                  ],
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
} 