import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';

/// Form dùng chung cho màn hình Thêm và Chỉnh sửa công việc.
class TaskForm extends StatefulWidget {
  final Task? task;
  final String submitLabel;
  final bool allowStatus;
  final Future<void> Function(Map<String, dynamic> body) onSubmit;

  const TaskForm({
    super.key,
    this.task,
    required this.submitLabel,
    required this.onSubmit,
    this.allowStatus = true,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _start;
  DateTime? _due;
  late String _priority;
  late String _status;
  bool _dueError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _start = t?.startDate ?? (t == null ? DateTime.now() : null);
    _due = t?.dueDate;
    _priority = t?.priority ?? 'medium';
    _status = t?.status ?? 'todo';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _dueError = _due == null);
    if (!valid || _due == null) return;
    if (_start != null && _due!.isBefore(_start!)) {
      showSnack(context, 'Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'startDate': _start?.toUtc().toIso8601String(),
        'dueDate': _due!.toUtc().toIso8601String(),
        'priority': _priority,
        if (widget.allowStatus) 'status': _status,
      });
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _title,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Tên công việc *', border: OutlineInputBorder()),
            validator: (v) => Validators.required(v, 'Tên công việc'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _description,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder(), alignLabelWithHint: true),
          ),
          const SizedBox(height: 8),
          _DateField(
            label: 'Ngày bắt đầu',
            value: _start,
            onTap: () async {
              final d = await pickDateTime(context, _start);
              if (d != null) setState(() => _start = d);
            },
            onClear: _start == null ? null : () => setState(() => _start = null),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Hạn hoàn thành *',
            value: _due,
            errorText: _dueError && _due == null ? 'Vui lòng chọn hạn hoàn thành' : null,
            onTap: () async {
              final d = await pickDateTime(context, _due);
              if (d != null) setState(() {
                _due = d;
                _dueError = false;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text('Mức độ ưu tiên', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: AppConstants.priorities
                .map((p) => ButtonSegment<String>(value: p, label: Text(AppConstants.priorityLabels[p]!)))
                .toList(),
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          if (widget.allowStatus) ...[
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
              items: AppConstants.statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(AppConstants.statusLabels[s]!)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? errorText;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.event),
          suffixIcon: onClear == null ? null : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
        ),
        child: Text(value == null ? 'Chọn ngày giờ' : DateFormatter.dateTime(value),
            style: TextStyle(color: value == null ? Colors.grey : null)),
      ),
    );
  }
}
