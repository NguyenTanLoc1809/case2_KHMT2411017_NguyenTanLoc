import 'package:flutter/material.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? Colors.red.shade700 : null,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Đồng ý',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: Colors.red) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Chọn ngày rồi chọn giờ. Trả về null nếu người dùng hủy chọn ngày.
Future<DateTime?> pickDateTime(BuildContext context, DateTime? initial) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(2000),
    lastDate: DateTime(now.year + 10),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: initial != null
        ? TimeOfDay.fromDateTime(initial)
        : const TimeOfDay(hour: 17, minute: 0),
  );
  final t = time ?? const TimeOfDay(hour: 17, minute: 0);
  return DateTime(date.year, date.month, date.day, t.hour, t.minute);
}
