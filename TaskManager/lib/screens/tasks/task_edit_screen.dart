import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../widgets/task_form.dart';

class TaskEditScreen extends StatelessWidget {
  final Task task;
  const TaskEditScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa công việc')),
      body: TaskForm(
        initial: task,
        submitLabel: 'Lưu thay đổi',
        onSubmit: (v) async {
          try {
            await TaskService().update(
              task.id,
              title: v.title,
              description: v.description,
              startDate: v.startDate,
              dueDate: v.dueDate,
              priority: v.priority,
              status: v.status,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cập nhật công việc thành công')));
            Navigator.pop(context, true);
          } on ApiException catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.message)));
          }
        },
      ),
    );
  }
}
