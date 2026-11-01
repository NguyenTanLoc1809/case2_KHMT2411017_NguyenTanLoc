import 'package:flutter/material.dart';

import '../../services/task_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/task_form.dart';

class TaskCreateScreen extends StatelessWidget {
  const TaskCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm công việc')),
      body: TaskForm(
        submitLabel: 'Tạo công việc',
        onSubmit: (body) async {
          await TaskService().createTask(body);
          if (!context.mounted) return;
          showSnack(context, 'Đã tạo công việc');
          Navigator.pop(context, true);
        },
      ),
    );
  }
}
