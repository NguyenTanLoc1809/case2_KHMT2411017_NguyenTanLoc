import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('HH:mm dd/MM/yyyy');

  static String date(DateTime? d) => d == null ? 'Chưa đặt' : _date.format(d);
  static String dateTime(DateTime? d) => d == null ? 'Chưa đặt' : _dateTime.format(d);

  /// "5 phút trước", "2 giờ trước", ...
  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return _date.format(d);
  }

  /// Mô tả thời gian còn lại đến hạn, ví dụ "Còn 2 ngày", "Quá hạn 3 giờ".
  static String dueText(DateTime due) {
    final diff = due.difference(DateTime.now());
    final abs = diff.abs();
    String span;
    if (abs.inMinutes < 60) {
      span = '${abs.inMinutes} phút';
    } else if (abs.inHours < 24) {
      span = '${abs.inHours} giờ';
    } else {
      span = '${abs.inDays} ngày';
    }
    return diff.isNegative ? 'Quá hạn $span' : 'Còn $span';
  }
}
