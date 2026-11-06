import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _date = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  static String date(DateTime? d) => d == null ? 'Chưa đặt' : _date.format(d.toLocal());

  static String dateTime(DateTime? d) =>
      d == null ? '' : _dateTime.format(d.toLocal());

  /// Gui len server dang ISO-8601 (UTC)
  static String? toIso(DateTime? d) => d?.toUtc().toIso8601String();
}
