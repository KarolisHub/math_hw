import 'package:flutter/material.dart';
import '../services/class_service.dart';

class ClassCard extends StatelessWidget {
  final String classId;
  final String className;
  final String joinCode;
  final bool isCreator;
  final VoidCallback onRegenerateCode;
  final VoidCallback onManageMembers;
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
            ? 'You created this class • Code: $joinCode'
            : 'You joined this class'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCreator)
              IconButton(
                icon: Icon(Icons.refresh),
                tooltip: 'Regenerate join code',
                onPressed: onRegenerateCode,
              ),
            isCreator
                ? IconButton(
                    icon: Icon(Icons.group),
                    tooltip: 'Manage members',
                    onPressed: onManageMembers,
                  )
                : IconButton(
                    icon: Icon(Icons.exit_to_app),
                    tooltip: 'Leave class',
                    onPressed: onLeaveClass,
                  ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
} 