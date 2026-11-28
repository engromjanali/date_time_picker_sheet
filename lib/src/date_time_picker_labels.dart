/// Every piece of text the picker shows, so an app can pass its own translations.
///
/// Each field has an English default.
class DateTimePickerLabels {
  /// The heading in single mode. Defaults to "Set Date and Time".
  final String title;

  /// The heading in range mode. Defaults to "Select Start & Return Date & Time".
  final String rangeTitle;

  /// The line under the heading. Defaults to "Choose your preferable date & time".
  final String subtitle;

  /// The label of the start time card. Defaults to "Start Time".
  final String startTime;

  /// The label of the end time card in range mode. Defaults to "Return Time".
  final String endTime;

  /// The "Now" button, and the text shown for the start when it is fixed to now. Defaults to "Now".
  final String now;

  /// The cancel button. Defaults to "Cancel".
  final String cancel;

  /// The confirm button. Defaults to "Confirm".
  final String confirm;

  /// The AM label. Null uses the app's `MaterialLocalizations`.
  final String? am;

  /// The PM label. Null uses the app's `MaterialLocalizations`.
  final String? pm;

  /// Shown when a start time before the earliest allowed one is picked or confirmed.
  ///
  /// Defaults to "You can't select a past time."
  final String startInPast;

  /// Shown when an end time at or before the start is picked or confirmed.
  ///
  /// Defaults to "Return time must be after the start time."
  final String endNotAfterStart;

  /// The tooltip of the previous arrow in the month view. Defaults to "Previous year".
  final String previousYear;

  /// The tooltip of the next arrow in the month view. Defaults to "Next year".
  final String nextYear;

  /// Shown when the caller's validator throws instead of returning a message.
  ///
  /// Defaults to "Something went wrong. Please try again."
  final String validationFailed;

  /// Creates a set of labels. Anything left out keeps its English default.
  const DateTimePickerLabels({
    this.title = 'Set Date and Time', this.rangeTitle = 'Select Start & Return Date & Time',
    this.subtitle = 'Choose your preferable date & time', this.startTime = 'Start Time', this.endTime = 'Return Time',
    this.now = 'Now', this.cancel = 'Cancel', this.confirm = 'Confirm', this.am, this.pm,
    this.startInPast = "You can't select a past time.",
    this.endNotAfterStart = 'Return time must be after the start time.', this.previousYear = 'Previous year', this.nextYear = 'Next year',
    this.validationFailed = 'Something went wrong. Please try again.',
  });
}

// SUMMARY
// Every piece of text the picker shows, including the messages for a refused or invalid start or end time,
// with English defaults so each app can pass its own translations.
