import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/task_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/user_selector.dart';

class AssignTaskScreen extends StatefulWidget {
  final String taskId;
  const AssignTaskScreen({super.key, required this.taskId});

  @override
  State<AssignTaskScreen> createState() => _AssignTaskScreenState();
}

class _AssignTaskScreenState extends State<AssignTaskScreen> {
  final _service = TaskService();
  Task? _task;
  List<AppUser> _newUsers = [];
  String? _primaryId; // người phụ trách chính được chọn (hiện có hoặc mới)
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await _service.getTask(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = t;
        _primaryId = t.primaryAssignee?.id;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppUser> get _allAssignees => [...?_task?.assignees, ..._newUsers];

  Future<void> _submit() async {
    final task = _task!;
    final primaryChanged = _primaryId != null && _primaryId != task.primaryAssignee?.id;
    if (_newUsers.isEmpty && !primaryChanged) {
      showSnack(context, 'Hãy chọn người cần giao việc hoặc đổi người phụ trách chính', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (_newUsers.isEmpty) {
        await _service.setPrimary(task.id, _primaryId!, true);
      } else {
        await _service.assign(
          task.id,
          userIds: _newUsers.map((u) => u.id).toList(),
          primaryAssigneeId: primaryChanged ? _primaryId : null,
        );
      }
      if (!mounted) return;
      showSnack(context, 'Giao việc thành công. Người nhận sẽ được thông báo qua email.');
      setState(() => _newUsers = []);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(AppUser u) async {
    final ok = await confirmDialog(
      context,
      title: 'Hủy giao việc',
      message: 'Hủy giao việc cho ${u.fullName}?',
      confirmText: 'Hủy giao',
      danger: true,
    );
    if (!ok) return;
    try {
      await _service.unassign(widget.taskId, u.id);
      if (mounted) showSnack(context, 'Đã hủy giao việc');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giao công việc')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final task = _task!;
    final all = _allAssignees;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(task.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const Text('Người đang được giao', style: TextStyle(fontWeight: FontWeight.bold)),
        if (task.assignees.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Chưa giao cho ai', style: TextStyle(color: Colors.grey))),
        ...task.assignees.map((u) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(u.initials)),
              title: Text(u.fullName),
              subtitle: Text(u.email),
              trailing: IconButton(
                tooltip: 'Hủy giao việc',
                icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                onPressed: () => _remove(u),
              ),
            )),
        const Divider(height: 32),
        const Text('Thêm người được giao', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        UserSelector(
          selected: _newUsers,
          excludeIds: task.assignees.map((e) => e.id).toSet(),
          onChanged: (l) => setState(() {
            _newUsers = l;
            if (_primaryId != null && !_allAssignees.any((u) => u.id == _primaryId)) _primaryId = null;
          }),
        ),
        const SizedBox(height: 16),
        if (all.isNotEmpty)
          DropdownButtonFormField<String>(
            value: all.any((u) => u.id == _primaryId) ? _primaryId : null,
            decoration: const InputDecoration(labelText: 'Người phụ trách chính', border: OutlineInputBorder()),
            items: all
                .map((u) => DropdownMenuItem(value: u.id, child: Text(u.fullName)))
                .toList(),
            onChanged: (v) => setState(() => _primaryId = v),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: const Text('Xác nhận giao việc'),
        ),
      ],
    );
  }
}
