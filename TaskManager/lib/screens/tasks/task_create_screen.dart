import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../widgets/task_form.dart';

class TaskCreateScreen extends StatelessWidget {
  const TaskCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm công việc')),
      body: TaskForm(
        submitLabel: 'Tạo công việc',
        onSubmit: (v) async {
          try {
            await TaskService().create(
              title: v.title,
              description: v.description,
              startDate: v.startDate,
              dueDate: v.dueDate,
              priority: v.priority,
              status: v.status,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tạo công việc thành công')));
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
