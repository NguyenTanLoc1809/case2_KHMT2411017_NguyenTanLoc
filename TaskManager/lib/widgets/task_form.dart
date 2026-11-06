import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/date_formatter.dart';

class TaskFormValues {
  final String title;
  final String description;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String priority;
  final String status;

  const TaskFormValues({
    required this.title,
    required this.description,
    required this.startDate,
    required this.dueDate,
    required this.priority,
    required this.status,
  });
}

/// Form dung chung cho man hinh Them va Sua cong viec.
class TaskForm extends StatefulWidget {
  final Task? initial;
  final String submitLabel;
  final Future<void> Function(TaskFormValues values) onSubmit;

  const TaskForm({
    super.key,
    this.initial,
    required this.submitLabel,
    required this.onSubmit,
  });

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _startDate;
  DateTime? _dueDate;
  late String _priority;
  late String _status;
  bool _saving = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _startDate = t?.startDate;
    _dueDate = t?.dueDate;
    _priority = t?.priority ?? 'medium';
    _status = t?.status ?? 'todo';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _dueDate = picked;
        }
        _dateError = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate != null && _dueDate != null && _dueDate!.isBefore(_startDate!)) {
      setState(() => _dateError = 'Hạn hoàn thành phải sau hoặc bằng ngày bắt đầu');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSubmit(TaskFormValues(
        title: _titleCtrl.text,
        description: _descCtrl.text,
        startDate: _startDate,
        dueDate: _dueDate,
        priority: _priority,
        status: _status,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _dateField(String label, DateTime? value, bool isStart) {
    return InkWell(
      onTap: () => _pickDate(isStart: isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event),
          suffixIcon: value == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() {
                    if (isStart) {
                      _startDate = null;
                    } else {
                      _dueDate = null;
                    }
                  }),
                ),
        ),
        child: Text(value == null ? 'Chọn ngày' : DateFormatter.date(value)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Tên công việc *',
              prefixIcon: Icon(Icons.title),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Tên công việc không được để trống'
                : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            maxLength: 5000,
            decoration: const InputDecoration(
              labelText: 'Mô tả',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _dateField('Ngày bắt đầu', _startDate, true)),
              const SizedBox(width: 12),
              Expanded(child: _dateField('Hạn hoàn thành', _dueDate, false)),
            ],
          ),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(_dateError!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _priority,
            decoration: const InputDecoration(
              labelText: 'Mức độ ưu tiên',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            items: kPriorityLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _priority = v ?? _priority),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Trạng thái',
              prefixIcon: Icon(Icons.timelapse),
            ),
            items: kStatusLabels.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}
