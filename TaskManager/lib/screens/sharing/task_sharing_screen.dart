import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/task_share.dart';
import '../../models/user.dart';
import '../../services/task_service.dart';
import '../../services/task_share_service.dart';
import '../../utils/constants.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/user_selector.dart';

class TaskSharingScreen extends StatefulWidget {
  final String taskId;
  const TaskSharingScreen({super.key, required this.taskId});

  @override
  State<TaskSharingScreen> createState() => _TaskSharingScreenState();
}

class _TaskSharingScreenState extends State<TaskSharingScreen> {
  final _shareService = TaskShareService();
  final _taskService = TaskService();
  Task? _task;
  List<TaskShare> _shares = [];
  List<AppUser> _selected = [];
  String _permission = 'viewer';
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
      final task = await _taskService.getTask(widget.taskId);
      final shares = await _shareService.getShares(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _shares = shares;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    if (_selected.isEmpty) {
      showSnack(context, 'Hãy chọn ít nhất một người để chia sẻ', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final shares = await _shareService.share(
          widget.taskId, _selected.map((u) => u.id).toList(), _permission);
      if (!mounted) return;
      setState(() {
        _shares = shares;
        _selected = [];
      });
      showSnack(context, 'Đã chia sẻ công việc');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePermission(TaskShare s, String permission) async {
    try {
      final shares = await _shareService.updatePermission(widget.taskId, s.id, permission);
      if (mounted) {
        setState(() => _shares = shares);
        showSnack(context, 'Đã đổi quyền');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _revoke(TaskShare s) async {
    final ok = await confirmDialog(
      context,
      title: 'Thu hồi quyền',
      message: 'Thu hồi quyền truy cập của ${s.user.fullName}?',
      confirmText: 'Thu hồi',
      danger: true,
    );
    if (!ok) return;
    try {
      final shares = await _shareService.revoke(widget.taskId, s.id);
      if (mounted) {
        setState(() => _shares = shares);
        showSnack(context, 'Đã thu hồi quyền');
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ & phân quyền')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final task = _task!;
    final exclude = {
      ..._shares.map((s) => s.user.id),
      if (task.createdBy != null) task.createdBy!.id,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(task.title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const Text('Người đã được chia sẻ', style: TextStyle(fontWeight: FontWeight.bold)),
        if (_shares.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Chưa chia sẻ cho ai', style: TextStyle(color: Colors.grey))),
        ..._shares.map((s) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Text(s.user.initials)),
              title: Text(s.user.fullName),
              subtitle: Text(s.user.email),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                DropdownButton<String>(
                  value: s.permission,
                  underline: const SizedBox.shrink(),
                  items: AppConstants.permissionLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null && v != s.permission) _changePermission(s, v);
                  },
                ),
                IconButton(
                  tooltip: 'Thu hồi quyền',
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _revoke(s),
                ),
              ]),
            )),
        const Divider(height: 32),
        const Text('Chia sẻ cho người khác', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        UserSelector(
          selected: _selected,
          excludeIds: exclude,
          onChanged: (l) => setState(() => _selected = l),
        ),
        const SizedBox(height: 16),
        const Text('Quyền truy cập'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'viewer', label: Text('Chỉ xem'), icon: Icon(Icons.visibility)),
            ButtonSegment(value: 'editor', label: Text('Chỉnh sửa'), icon: Icon(Icons.edit)),
          ],
          selected: {_permission},
          onSelectionChanged: (s) => setState(() => _permission = s.first),
        ),
        const SizedBox(height: 8),
        const Text(
          'Editor có thể sửa nội dung và đổi trạng thái nhưng không được xóa công việc hay quản lý chia sẻ.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _share,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.share),
          label: const Text('Chia sẻ'),
        ),
      ],
    );
  }
}
