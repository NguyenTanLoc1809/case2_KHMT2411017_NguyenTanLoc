import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../services/api_client.dart';
import '../../services/task_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_card.dart';
import '../profile/profile_screen.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _service = TaskService();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;

  String _scope = ''; // '' = tat ca | created | assigned | shared
  String _status = '';
  String _priority = '';
  String _sortBy = 'createdAt';
  String _order = 'desc';

  static const _scopes = {
    '': 'Tất cả',
    'created': 'Của tôi',
    'assigned': 'Được giao cho tôi',
    'shared': 'Được chia sẻ',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await _service.list(
        scope: _scope,
        status: _status,
        priority: _priority,
        q: _searchCtrl.text,
        sortBy: _sortBy,
        order: _order,
      );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
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

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openCreate() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const TaskCreateScreen()));
    if (ok == true) _load();
  }

  Future<void> _openDetail(Task t) async {
    final changed = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)));
    if (changed == true) _load();
  }

  Future<void> _openFilters() async {
    String status = _status;
    String priority = _priority;
    String sortBy = _sortBy;
    String order = _order;

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lọc & sắp xếp',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tất cả')),
                    ...kStatusLabels.entries.map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) => setSheet(() => status = v ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tất cả')),
                    ...kPriorityLabels.entries.map((e) =>
                        DropdownMenuItem(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) => setSheet(() => priority = v ?? ''),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: sortBy,
                  decoration: const InputDecoration(labelText: 'Sắp xếp theo'),
                  items: const [
                    DropdownMenuItem(
                        value: 'createdAt', child: Text('Thời gian tạo')),
                    DropdownMenuItem(
                        value: 'dueDate', child: Text('Hạn hoàn thành')),
                    DropdownMenuItem(
                        value: 'priority', child: Text('Mức độ ưu tiên')),
                  ],
                  onChanged: (v) => setSheet(() => sortBy = v ?? 'createdAt'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'asc',
                        icon: Icon(Icons.arrow_upward),
                        label: Text('Tăng dần')),
                    ButtonSegment(
                        value: 'desc',
                        icon: Icon(Icons.arrow_downward),
                        label: Text('Giảm dần')),
                  ],
                  selected: {order},
                  onSelectionChanged: (s) => setSheet(() => order = s.first),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheet(() {
                          status = '';
                          priority = '';
                          sortBy = 'createdAt';
                          order = 'desc';
                        }),
                        child: const Text('Đặt lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (apply == true) {
      setState(() {
        _status = status;
        _priority = priority;
        _sortBy = sortBy;
        _order = order;
      });
      _load();
    }
  }

  bool get _hasActiveFilter =>
      _status.isNotEmpty ||
      _priority.isNotEmpty ||
      _sortBy != 'createdAt' ||
      _order != 'desc';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc'),
        actions: [
          IconButton(
            tooltip: 'Lọc & sắp xếp',
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _hasActiveFilter,
              smallSize: 8,
              child: const Icon(Icons.filter_list),
            ),
          ),
          IconButton(
            tooltip: 'Cá nhân',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên công việc',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _scopes.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _scope == e.key,
                          onSelected: (_) {
                            setState(() => _scope = e.key);
                            _load();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 8),
            Center(child: Text('Không có công việc nào')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: _tasks.length,
        itemBuilder: (_, i) =>
            TaskCard(task: _tasks[i], onTap: () => _openDetail(_tasks[i])),
      ),
    );
  }
}
