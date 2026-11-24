class DateTimePickerLabels {
  final String title;
  final String rangeTitle;
  final String subtitle;
  final String startTime;
  final String endTime;
  final String now;
  final String cancel;
  final String confirm;
  // Null falls back to the app's MaterialLocalizations.
  final String? am;
  final String? pm;
  final String startInPast;
  final String endNotAfterStart;
  final String previousYear;
  final String nextYear;
  // Shown when the caller's validator throws instead of returning a message.
  final String validationFailed;

  const DateTimePickerLabels({
    this.title = 'Set Date and Time', this.rangeTitle = 'Select Start & Return Date & Time',
    this.subtitle = 'Choose your preferable date & time', this.startTime = 'Start Time', this.endTime = 'Return Time',
    this.now = 'Now', this.cancel = 'Cancel', this.confirm = 'Confirm', this.am, this.pm,
    this.startInPast = 'You cannot select a time before the current time',
    this.endNotAfterStart = 'Return time must be after start time', this.previousYear = 'Previous year', this.nextYear = 'Next year',
    this.validationFailed = 'Something went wrong. Please try again.',
  });
}

// SUMMARY
// Every piece of text the picker shows, including its validation messages, with English defaults so each
// app can pass its own translations.
