import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/date_formatter.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/loading_view.dart';
import '../tasks/task_detail_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
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
      final items = await _service.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
      context.read<NotificationProvider>().setUnread(items.where((n) => !n.isRead).length);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'task_assigned':
        return Icons.assignment_ind_outlined;
      case 'task_shared':
      case 'share_permission_changed':
      case 'share_revoked':
        return Icons.share_outlined;
      case 'due_date_changed':
      case 'task_reminder':
        return Icons.alarm;
      case 'task_completed':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      try {
        await _service.markRead(n.id);
        if (mounted) {
          setState(() => _items = _items.map((e) => e.id == n.id ? e.copyWith(isRead: true) : e).toList());
          context.read<NotificationProvider>().setUnread(_items.where((e) => !e.isRead).length);
        }
      } catch (_) {}
    }
    if (n.taskId != null && mounted) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: n.taskId!)));
    }
  }

  Future<void> _markAll() async {
    try {
      await _service.markAllRead();
      await _load(spinner: false);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => !n.isRead);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (hasUnread)
            TextButton.icon(
              onPressed: _markAll,
              icon: const Icon(Icons.done_all),
              label: const Text('Đọc tất cả'),
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: () => _load(spinner: false),
                  child: _items.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 120),
                          EmptyView(message: 'Chưa có thông báo nào', icon: Icons.notifications_off_outlined),
                        ])
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            return ListTile(
                              tileColor: n.isRead ? null : Theme.of(context).colorScheme.primary.withAlpha(18),
                              leading: CircleAvatar(child: Icon(_icon(n.type))),
                              title: Text(n.title,
                                  style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                              subtitle: Text('${n.message}\n${DateFormatter.timeAgo(n.createdAt)}'),
                              isThreeLine: true,
                              trailing: n.isRead
                                  ? null
                                  : const Icon(Icons.circle, size: 10, color: Colors.indigo),
                              onTap: () => _open(n),
                            );
                          },
                        ),
                ),
    );
  }
}
