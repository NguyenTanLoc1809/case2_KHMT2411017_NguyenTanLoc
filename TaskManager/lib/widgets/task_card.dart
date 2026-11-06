import 'package:flutter/material.dart';

import '../models/task.dart';
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: task.status == 'completed'
                                ? TextDecoration.lineThrough
                                : null,
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
                  Icon(Icons.event,
                      size: 16, color: overdue ? Colors.red : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.date(task.dueDate),
                    style: TextStyle(
                        fontSize: 12, color: overdue ? Colors.red : null),
                  ),
                  if (overdue)
                    const Text(' • Quá hạn',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.roleLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
