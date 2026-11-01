import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  const TaskCard({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    final dueColor = overdue ? Colors.red : Colors.grey.shade700;
    final primary = task.primaryAssignee ?? (task.assignees.isNotEmpty ? task.assignees.first : null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: task.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  PriorityBadge(priority: task.priority),
                  const SizedBox(width: 12),
                  Icon(Icons.schedule, size: 14, color: dueColor),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      task.isCompleted
                          ? DateFormatter.dateTime(task.dueDate)
                          : '${DateFormatter.dateTime(task.dueDate)} • ${DateFormatter.dueText(task.dueDate)}',
                      style: TextStyle(fontSize: 12, color: dueColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      primary == null
                          ? 'Chưa giao cho ai'
                          : '${primary.fullName}${task.assignees.length > 1 ? ' +${task.assignees.length - 1}' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (task.myRole != null)
                    Chip(
                      label: Text(AppConstants.roleLabels[task.myRole] ?? task.myRole!,
                          style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
