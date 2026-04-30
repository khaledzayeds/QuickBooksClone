// date_formatter.dart
// date_formatter.dart

import 'package:intl/intl.dart';

class DateFormatter {
  static final _arabicDate  = DateFormat('d MMMM yyyy', 'ar');
  static final _shortDate   = DateFormat('yyyy-MM-dd');
  static final _displayDate = DateFormat('d/M/yyyy');

  /// مثال: ٢٦ أبريل ٢٠٢٦
  static String format(DateTime date) =>
      _arabicDate.format(date);

  /// مثال: 2026-04-26  (للـ API)
  static String toApi(DateTime date) =>
      _shortDate.format(date);

  /// مثال: 26/4/2026
  static String short(DateTime date) =>
      _displayDate.format(date);

  /// parse من الـ API
  static DateTime fromApi(String s) =>
      DateTime.parse(s);
}