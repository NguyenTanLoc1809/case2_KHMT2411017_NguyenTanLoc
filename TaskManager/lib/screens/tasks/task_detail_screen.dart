import 'package:flutter/material.dart';

import '../../models/email_log.dart';
import '../../models/task.dart';
import '../../models/task_activity.dart';
import '../../models/task_share.dart';
import '../../services/task_service.dart';
import '../../services/task_share_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/status_badge.dart';
import '../assignment/assign_task_screen.dart';
import '../sharing/task_sharing_screen.dart';
import 'task_edit_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskService = TaskService();
  final _shareService = TaskShareService();

  Task? _task;
  List<TaskActivity> _activities = [];
  List<TaskShare> _shares = [];
  List<EmailLog> _emailLogs = [];
  bool _loading = true;
  bool _updatingStatus = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner) setState(() => _loading = true);
    try {
      final task = await _taskService.getTask(widget.taskId);
      final activitiesF = _taskService.getActivities(widget.taskId);
      final sharesF = _shareService.getShares(widget.taskId);
      final activities = await activitiesF;
      final shares = await sharesF;
      var logs = <EmailLog>[];
      if (task.canManage) {
        try {
          logs = await _taskService.getEmailLogs(widget.taskId);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _task = task;
        _activities = activities;
        _shares = shares;
        _emailLogs = logs;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    if (_task == null || status == _task!.status) return;
    setState(() => _updatingStatus = true);
    try {
      await _taskService.updateStatus(_task!.id, status);
      await _load(spinner: false);
      if (mounted) showSnack(context, 'Đã cập nhật trạng thái');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Xóa công việc',
      message: 'Bạn có chắc muốn xóa "${_task!.title}"? Hành động này không thể hoàn tác.',
      confirmText: 'Xóa',
      danger: true,
    );
    if (!ok) return;
    try {
      await _taskService.deleteTask(_task!.id);
      if (!mounted) return;
      showSnack(context, 'Đã xóa công việc');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load(spinner: false);
  }

  Future<void> _retryEmail(EmailLog log) async {
    try {
      await _taskService.retryEmail(log.id);
      if (mounted) showSnack(context, 'Đã đưa email vào hàng đợi gửi lại');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _load(spinner: false);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          if (task != null && (task.canEdit || task.canDelete))
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _push(TaskEditScreen(task: task));
                if (v == 'delete') _delete();
              },
              itemBuilder: (_) => [
                if (task.canEdit)
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Chỉnh sửa'))),
                if (task.canDelete)
                  const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Xóa'))),
              ],
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(onRefresh: () => _load(spinner: false), child: _buildContent(task!)),
    );
  }

  Widget _buildContent(Task task) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(task.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          StatusBadge(status: task.status),
          PriorityBadge(priority: task.priority),
          if (task.myRole != null)
            Chip(
              label: Text('Vai trò của tôi: ${AppConstants.roleLabels[task.myRole] ?? task.myRole}',
                  style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
            ),
        ]),
        const SizedBox(height: 16),
        if (task.description.isNotEmpty) ...[
          Text(task.description),
          const SizedBox(height: 16),
        ],
        Card(
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: const Text('Ngày bắt đầu'),
              trailing: Text(DateFormatter.dateTime(task.startDate)),
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: task.isOverdue ? Colors.red : null),
              title: const Text('Hạn hoàn thành'),
              subtitle: task.isCompleted
                  ? null
                  : Text(DateFormatter.dueText(task.dueDate),
                      style: TextStyle(color: task.isOverdue ? Colors.red : Colors.grey)),
              trailing: Text(DateFormatter.dateTime(task.dueDate),
                  style: TextStyle(color: task.isOverdue ? Colors.red : null)),
            ),
          ]),
        ),
        if (task.canEdit) ...[
          const SizedBox(height: 16),
          const Text('Cập nhật trạng thái', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'todo', label: Text('Chưa làm')),
              ButtonSegment(value: 'in_progress', label: Text('Đang làm')),
              ButtonSegment(value: 'completed', label: Text('Hoàn thành')),
            ],
            selected: {task.status},
            onSelectionChanged: _updatingStatus ? null : (s) => _changeStatus(s.first),
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle('Người tạo'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Text(task.createdBy?.initials ?? '?')),
          title: Text(task.createdBy?.fullName ?? '—'),
          subtitle: Text(task.createdBy?.email ?? ''),
        ),
        _sectionTitle('Người được giao (${task.assignees.length})'),
        if (task.assignees.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Chưa giao cho ai', style: TextStyle(color: Colors.grey))),
        ...task.assignees.map((u) {
          final isPrimary = task.primaryAssignee?.id == u.id;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text(u.initials)),
            title: Text(u.fullName),
            subtitle: Text(u.email),
            trailing: isPrimary
                ? const Chip(label: Text('Phụ trách chính', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact)
                : null,
          );
        }),
        _sectionTitle('Người được chia sẻ (${_shares.length})'),
        if (_shares.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Chưa chia sẻ cho ai', style: TextStyle(color: Colors.grey))),
        ..._shares.map((s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(s.user.initials)),
              title: Text(s.user.fullName),
              subtitle: Text(s.user.email),
              trailing: Chip(
                label: Text(AppConstants.permissionLabels[s.permission] ?? s.permission,
                    style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            )),
        if (task.canManage) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _push(AssignTaskScreen(taskId: task.id)),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Giao việc'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _push(TaskSharingScreen(taskId: task.id)),
                icon: const Icon(Icons.share),
                label: const Text('Chia sẻ'),
              ),
            ),
          ]),
        ],
        const SizedBox(height: 16),
        _sectionTitle('Lịch sử hoạt động'),
        if (_activities.isEmpty) const Text('Chưa có hoạt động', style: TextStyle(color: Colors.grey)),
        ..._activities.take(30).map((a) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.history, size: 20),
              title: Text('${a.user.fullName} ${a.description}'),
              subtitle: Text(DateFormatter.timeAgo(a.createdAt)),
            )),
        if (task.canManage && _emailLogs.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('Lịch sử gửi email'),
          ..._emailLogs.map(_emailTile),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _emailTile(EmailLog log) {
    final color = log.status == 'sent' ? Colors.green : (log.status == 'failed' ? Colors.red : Colors.orange);
    final icon = log.status == 'sent' ? Icons.check_circle : (log.status == 'failed' ? Icons.error : Icons.schedule);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(log.subject, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${log.recipientEmail} • ${log.attempts} lần thử'
        '${log.status == 'failed' && log.errorMessage.isNotEmpty ? '\n${log.errorMessage}' : ''}',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: log.status == 'failed'
          ? TextButton(onPressed: () => _retryEmail(log), child: const Text('Gửi lại'))
          : null,
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
}
