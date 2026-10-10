extension DateTimeX on DateTime {
  /// Returns start of the day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns end of the day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns start of the month.
  DateTime get startOfMonth => DateTime(year, month);

  /// Returns end of the month (last ms of last day).
  DateTime get endOfMonth {
    final nextMonth = month == 12 ? DateTime(year + 1) : DateTime(year, month + 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  /// True if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  /// Unix epoch milliseconds (used for Drift INTEGER columns).
  int get epochMs => millisecondsSinceEpoch;
}

extension IntDateX on int {
  /// Convert Drift epoch ms back to DateTime.
  DateTime get toDateTime => DateTime.fromMillisecondsSinceEpoch(this);
}
