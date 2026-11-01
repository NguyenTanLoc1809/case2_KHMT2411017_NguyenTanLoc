import 'package:flutter/material.dart';

import '../utils/constants.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.priorityColors[priority] ?? Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          AppConstants.priorityLabels[priority] ?? priority,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
