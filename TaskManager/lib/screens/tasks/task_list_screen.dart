import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/user.dart';
import '../../services/task_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/task_card.dart';
import '../../widgets/user_selector.dart';
import 'task_create_screen.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _service = TaskService();
  final _searchController = TextEditingController();
  TaskFilter _filter = TaskFilter();
  List<Task> _tasks = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _loading = true);
    try {
      final tasks = await _service.getTasks(_filter);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _filter.q = text;
      _load();
    });
  }

  Future<void> _openDetail(Task t) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t.id)));
    if (mounted) _load(showSpinner: false);
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const TaskCreateScreen()));
    if (created == true && mounted) _load();
  }

  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<TaskFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filter.copy()),
    );
    if (result != null && mounted) {
      _filter = result;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Công việc'),
        actions: [
          IconButton(
            tooltip: 'Lọc & sắp xếp',
            onPressed: _openFilter,
            icon: Badge(
              isLabelVisible: _filter.hasActiveFilter,
              smallSize: 8,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên công việc',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filter.q = '';
                          setState(() {});
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
                        padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
                        child: ChoiceChip(
                          label: Text(e.value),
                          selected: _filter.scope == e.key,
                          onSelected: (_) {
                            setState(() => _filter.scope = e.key);
                            _load();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView(message: 'Đang tải công việc...');
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: ListView(children: const [
          SizedBox(height: 120),
          EmptyView(message: 'Chưa có công việc nào.\nNhấn "Thêm việc" để tạo mới.', icon: Icons.task_outlined),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(showSpinner: false),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 88),
        itemCount: _tasks.length,
        itemBuilder: (_, i) => TaskCard(task: _tasks[i], onTap: () => _openDetail(_tasks[i])),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final TaskFilter initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TaskFilter _f;

  @override
  void initState() {
    super.initState();
    _f = widget.initial;
  }

  Future<void> _pickAssignee() async {
    final picked = await showDialog<AppUser>(
      context: context,
      builder: (ctx) {
        List<AppUser> sel = [];
        return AlertDialog(
          title: const Text('Chọn người phụ trách'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (c, setS) => SingleChildScrollView(
                child: UserSelector(
                  multiple: false,
                  selected: sel,
                  onChanged: (l) {
                    sel = l;
                    if (l.isNotEmpty) Navigator.pop(ctx, l.first);
                  },
                ),
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
        );
      },
    );
    if (picked != null) {
      setState(() {
        _f.assigneeId = picked.id;
        _f.assigneeName = picked.fullName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _f.status == null,
                onSelected: (_) => setState(() => _f.status = null),
              ),
              ...AppConstants.statuses.map((s) => ChoiceChip(
                    label: Text(AppConstants.statusLabels[s]!),
                    selected: _f.status == s,
                    onSelected: (_) => setState(() => _f.status = s),
                  )),
            ]),
            const SizedBox(height: 12),
            const Text('Mức độ ưu tiên', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                label: const Text('Tất cả'),
                selected: _f.priority == null,
                onSelected: (_) => setState(() => _f.priority = null),
              ),
              ...AppConstants.priorities.map((p) => ChoiceChip(
                    label: Text(AppConstants.priorityLabels[p]!),
                    selected: _f.priority == p,
                    onSelected: (_) => setState(() => _f.priority = p),
                  )),
            ]),
            const SizedBox(height: 12),
            const Text('Người phụ trách', style: TextStyle(fontWeight: FontWeight.w600)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_search),
              title: Text(_f.assigneeName ?? 'Tất cả'),
              trailing: _f.assigneeId == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _f.assigneeId = null;
                        _f.assigneeName = null;
                      }),
                    ),
              onTap: _pickAssignee,
            ),
            const Text('Sắp xếp theo', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'dueDate', label: Text('Hạn')),
                ButtonSegment(value: 'priority', label: Text('Ưu tiên')),
                ButtonSegment(value: 'createdAt', label: Text('Ngày tạo')),
              ],
              selected: {_f.sortBy},
              onSelectionChanged: (s) => setState(() => _f.sortBy = s.first),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'asc', label: Text('Tăng dần'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'desc', label: Text('Giảm dần'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_f.order},
              onSelectionChanged: (s) => setState(() => _f.order = s.first),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                      context,
                      TaskFilter(scope: _f.scope, q: _f.q)),
                  child: const Text('Đặt lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: () => Navigator.pop(context, _f), child: const Text('Áp dụng')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
