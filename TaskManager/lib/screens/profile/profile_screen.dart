import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/statistics_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_formatter.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/loading_view.dart';
import '../tasks/task_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _statsService = StatisticsService();
  AllStatistics? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool spinner = true}) async {
    if (spinner) setState(() => _loading = true);
    try {
      final s = await _statsService.all();
      if (!mounted) return;
      setState(() {
        _stats = s;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final auth = context.read<AuthProvider>();
    final name = TextEditingController(text: auth.user?.fullName ?? '');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thông tin'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Họ tên', border: OutlineInputBorder()),
            validator: Validators.fullName,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final newName = name.text;
    name.dispose();
    if (ok != true || !mounted) return;
    try {
      await auth.updateProfile(fullName: newName);
      if (mounted) showSnack(context, 'Đã cập nhật thông tin');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
                validator: (v) => Validators.required(v, 'Mật khẩu hiện tại'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
                validator: (v) => Validators.password(v, 'Mật khẩu mới'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder()),
                validator: (v) => Validators.confirmPassword(v, next.text),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
    final cur = current.text;
    final nw = next.text;
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (ok != true || !mounted) return;
    try {
      await AuthService().changePassword(cur, nw);
      if (mounted) showSnack(context, 'Đổi mật khẩu thành công');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc muốn đăng xuất?',
      confirmText: 'Đăng xuất',
    );
    if (ok && mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân & thống kê')),
      body: RefreshIndicator(
        onRefresh: () => _load(spinner: false),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  CircleAvatar(radius: 36, child: Text(user?.initials ?? '?', style: const TextStyle(fontSize: 28))),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
                    OutlinedButton.icon(onPressed: _editProfile, icon: const Icon(Icons.edit), label: const Text('Sửa hồ sơ')),
                    OutlinedButton.icon(onPressed: _changePassword, icon: const Icon(Icons.lock_reset), label: const Text('Đổi mật khẩu')),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Text('Thống kê công việc', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: LoadingView())
            else if (_error != null)
              SizedBox(height: 200, child: ErrorView(message: _error!, onRetry: _load))
            else
              ..._statsWidgets(_stats!),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _statsWidgets(AllStatistics s) {
    final total = s.tasks.total == 0 ? 1 : s.tasks.total;
    Widget bar(String label, int value, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: value / total, minHeight: 10, color: color, backgroundColor: color.withAlpha(30)),
              ),
            ),
            SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
        );

    Widget tile(String label, int value, IconData icon, Color color) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
        );

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tổng số: ${s.tasks.total} công việc', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            bar(AppConstants.statusLabels['todo']!, s.tasks.todo, AppConstants.statusColors['todo']!),
            bar(AppConstants.statusLabels['in_progress']!, s.tasks.inProgress, AppConstants.statusColors['in_progress']!),
            bar(AppConstants.statusLabels['completed']!, s.tasks.completed, AppConstants.statusColors['completed']!),
          ]),
        ),
      ),
      Row(children: [
        tile('Được giao cho tôi', s.assignments.assignedToMe.total, Icons.assignment_ind, Colors.indigo),
        tile('Đang phụ trách chính', s.assignments.primaryActive, Icons.star, Colors.amber.shade800),
        tile('Tôi giao cho người khác', s.assignments.createdAssignedToOthers, Icons.send, Colors.teal),
      ]),
      Row(children: [
        tile('Sắp đến hạn (${s.deadlines.days} ngày)', s.deadlines.dueSoonCount, Icons.alarm, Colors.orange),
        tile('Đã quá hạn', s.deadlines.overdueCount, Icons.warning_amber, Colors.red),
      ]),
      if (s.deadlines.overdue.isNotEmpty) _deadlineList('Việc quá hạn', s.deadlines.overdue, Colors.red),
      if (s.deadlines.dueSoon.isNotEmpty) _deadlineList('Việc sắp đến hạn', s.deadlines.dueSoon, Colors.orange),
    ];
  }

  Widget _deadlineList(String title, List<Task> tasks, Color color) {
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
        ...tasks.take(5).map((t) => ListTile(
              dense: true,
              title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${DateFormatter.dateTime(t.dueDate)} • ${DateFormatter.dueText(t.dueDate)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)));
                if (mounted) _load(spinner: false);
              },
            )),
      ]),
    );
  }
}
