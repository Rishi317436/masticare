class DateUtilsX {
  DateUtilsX._();

  static String formatShortDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
