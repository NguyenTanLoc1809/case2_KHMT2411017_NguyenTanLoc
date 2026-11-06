import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _service = TaskService();
  Task? _task;
  List<TaskActivity> _activities = [];
  bool _loading = true;
  String? _error;
  bool _changed = false; // bao cho man hinh danh sach biet can tai lai

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final task = await _service.getById(widget.taskId);
      List<TaskActivity> acts = [];
      try {
        acts = await _service.activities(widget.taskId);
      } on ApiException {
        // Lich su la phan phu, loi o day khong chan man hinh
      }
      if (!mounted) return;
      setState(() {
        _task = task;
        _activities = acts;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _changeStatus(String status) async {
    try {
      final updated = await _service.updateStatus(widget.taskId, status);
      _changed = true;
      if (!mounted) return;
      setState(() => _task = updated);
      _toast('Đã cập nhật trạng thái');
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _edit() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: _task!)),
    );
    if (ok == true) {
      _changed = true;
      _load();
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Bạn có chắc muốn xóa "${_task!.title}"? Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.delete(widget.taskId);
      if (!mounted) return;
      _toast('Đã xóa công việc');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết công việc'),
          actions: [
            if (task != null && task.permissions.canEdit)
              IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Chỉnh sửa',
                  onPressed: _edit),
            if (task != null && task.permissions.canDelete)
              IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Xóa',
                  onPressed: _delete),
          ],
        ),
        body: _loading
            ? const LoadingView()
            : _error != null
                ? ErrorView(message: _error!, onRetry: _load)
                : _buildBody(task!),
      ),
    );
  }

  Widget _row(IconData icon, String label, Widget value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            SizedBox(
                width: 110,
                child: Text(label, style: TextStyle(color: Colors.grey[700]))),
            Expanded(child: value),
          ],
        ),
      );

  Widget _buildBody(Task task) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(task.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Vai trò của bạn: ${task.roleLabel}',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          if (task.description.isNotEmpty)
            Text(task.description, style: Theme.of(context).textTheme.bodyLarge)
          else
            Text('Không có mô tả',
                style: TextStyle(
                    color: Colors.grey[500], fontStyle: FontStyle.italic)),
          const Divider(height: 28),
          _row(Icons.timelapse, 'Trạng thái', Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status: task.status))),
          _row(Icons.flag_outlined, 'Ưu tiên', Align(
              alignment: Alignment.centerLeft,
              child: PriorityBadge(priority: task.priority))),
          _row(Icons.play_arrow_outlined, 'Bắt đầu',
              Text(DateFormatter.date(task.startDate))),
          _row(
              Icons.event,
              'Hạn hoàn thành',
              Text(
                DateFormatter.date(task.dueDate) +
                    (task.isOverdue ? '  (Quá hạn)' : ''),
                style: TextStyle(color: task.isOverdue ? Colors.red : null),
              )),
          _row(Icons.person_outline, 'Người tạo',
              Text(task.createdBy?.fullName ?? '—')),
          _row(
              Icons.assignment_ind_outlined,
              'Người phụ trách',
              Text(task.primaryAssignee?.fullName ??
                  (task.assignees.isEmpty
                      ? 'Chưa giao'
                      : task.assignees.map((u) => u.fullName).join(', ')))),
          if (task.permissions.canUpdateStatus) ...[
            const Divider(height: 28),
            Text('Cập nhật trạng thái',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: kStatusLabels.entries
                  .map((e) => ButtonSegment(
                      value: e.key,
                      label: Text(e.value, style: const TextStyle(fontSize: 11))))
                  .toList(),
              selected: {task.status},
              onSelectionChanged: (s) => _changeStatus(s.first),
            ),
          ],
          const Divider(height: 28),
          Text('Lịch sử hoạt động',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_activities.isEmpty)
            Text('Chưa có hoạt động',
                style: TextStyle(color: Colors.grey[500]))
          else
            ..._activities.map((a) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, size: 20),
                  title: Text('${a.userName} ${a.label}'),
                  subtitle: Text(DateFormatter.dateTime(a.createdAt)),
                )),
        ],
      ),
    );
  }
}
