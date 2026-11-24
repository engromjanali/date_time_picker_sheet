class DateTimePickerResult {
  final DateTime start;
  final DateTime? end;
  final bool isNow;
  const DateTimePickerResult({required this.start, this.end, this.isNow = false});
}

// SUMMARY
// What the picker hands back: the picked start moment, the end moment in range mode, and whether the
// user chose the "now" action instead of a scheduled time.
