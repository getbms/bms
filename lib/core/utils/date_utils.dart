import 'package:intl/intl.dart';

abstract final class BmsDateUtils {
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy HH:mm');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime dt) => _date.format(dt);
  static String formatDateTime(DateTime dt) => _dateTime.format(dt);
  static String formatTime(DateTime dt) => _time.format(dt);
  static String toIsoDate(DateTime dt) => _isoDate.format(dt);

  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static int daysBetween(DateTime from, DateTime to) =>
      startOfDay(to).difference(startOfDay(from)).inDays;

  // Aging bucket for debtors / payables
  static String agingBucket(DateTime invoiceDate) {
    final days = daysBetween(invoiceDate, DateTime.now());
    if (days <= 30) return '0-30 days';
    if (days <= 60) return '31-60 days';
    return '60+ days';
  }
}
