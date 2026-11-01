import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/task_form.dart';

class TaskEditScreen extends StatelessWidget {
  final Task task;
  const TaskEditScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa công việc')),
      body: TaskForm(
        task: task,
        submitLabel: 'Lưu thay đổi',
        onSubmit: (body) async {
          await TaskService().updateTask(task.id, body);
          if (!context.mounted) return;
          showSnack(context, 'Đã cập nhật công việc');
          Navigator.pop(context, true);
        },
      ),
    );
  }
}
