/// What the picker returns when the user confirms.
class DateTimePickerResult {
  /// The picked start moment.
  final DateTime start;

  /// The picked end moment in range mode, otherwise null.
  final DateTime? end;

  /// Whether the user chose the "Now" action instead of a scheduled time. [start] is then the current moment.
  final bool isNow;

  /// Creates a result.
  const DateTimePickerResult({required this.start, this.end, this.isNow = false});
}

// SUMMARY
// What the picker hands back: the picked start moment, the end moment in range mode, and whether the
// user chose the "now" action instead of a scheduled time.
