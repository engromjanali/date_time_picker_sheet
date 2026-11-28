import 'dart:async';
import 'dart:ui' show Color;

import 'date_time_picker_labels.dart';
import 'date_time_picker_result.dart';

/// Whether the picker chooses one moment or a start and an end.
enum DateTimePickerMode {
  /// One day and one time.
  single,

  /// A start day and time, and an end day and time.
  range,
}

/// Checks a picked result before the picker closes.
///
/// Return a message to keep the picker open and show it in a snackbar, or `null` to accept the pick. The confirm
/// button shows a loader while the returned future runs.
typedef DateTimePickerValidator = FutureOr<String?> Function(DateTimePickerResult result);

/// Everything that shapes one picker: its mode, opening values, date bounds, rules, time format, labels and color.
///
/// Passed to [showDateTimePicker], or straight to the sheet, dialog or embeddable picker widgets.
class DateTimePickerConfig {
  /// Whether one moment or a start and an end is picked. Defaults to [DateTimePickerMode.single].
  final DateTimePickerMode mode;

  /// Where the calendar and the start time open.
  ///
  /// Defaults to the next free slot from now. A value before the earliest allowed start falls back to that default.
  final DateTime? initialStart;

  /// Where the end day and end time open in [DateTimePickerMode.range]. Defaults to an hour after the start.
  final DateTime? initialEnd;

  /// The earliest allowed start.
  ///
  /// Defaults to now, or to 100 years back when [allowPast] is true. When set, it takes priority over [allowPast].
  final DateTime? firstDate;

  /// The latest selectable day. Only the date counts, its time of day is ignored.
  ///
  /// Defaults to 31 December, five years ahead.
  final DateTime? lastDate;

  /// Whether days and times before now can be picked. The picker still opens on the current time.
  ///
  /// Cannot be combined with [startNowOnly].
  final bool allowPast;

  /// In [DateTimePickerMode.range], fixes the start to now so only the end is picked.
  final bool startNowOnly;

  /// Whether only today can be selected.
  final bool todayOnly;

  /// Forces 24-hour (`true`) or 12-hour (`false`) wheels. Null follows the device setting.
  final bool? use24HourFormat;

  /// The minute step of the minute wheel. Must divide 60. Defaults to 1.
  final int minuteInterval;

  /// In [DateTimePickerMode.single], adds a "Now" button that returns a result with
  /// [DateTimePickerResult.isNow] set.
  final bool showNowAction;

  /// Checks the pick before the picker closes. See [DateTimePickerValidator].
  final DateTimePickerValidator? validator;

  /// Every visible string. Defaults to English.
  final DateTimePickerLabels labels;

  /// The selection color for this picker only: selected days, the range band, AM/PM, and the buttons.
  ///
  /// Text on it turns white or black automatically. Overrides the theme and [DateTimePickerThemeData.selectedColor].
  final Color? primaryColor;

  /// Creates a picker configuration. Every argument is optional.
  const DateTimePickerConfig({
    this.mode = DateTimePickerMode.single, this.initialStart, this.initialEnd, this.firstDate, this.lastDate,
    this.allowPast = false, this.startNowOnly = false, this.todayOnly = false, this.use24HourFormat, this.minuteInterval = 1,
    this.showNowAction = false, this.validator, this.labels = const DateTimePickerLabels(), this.primaryColor,
  }) : assert(minuteInterval > 0 && 60 % minuteInterval == 0, 'minuteInterval must divide 60'),
       assert(!allowPast || !startNowOnly, 'allowPast and startNowOnly cannot be combined'),
       assert(!startNowOnly || mode == DateTimePickerMode.range, 'startNowOnly applies to range mode only'),
       assert(!showNowAction || mode == DateTimePickerMode.single, 'showNowAction applies to single mode only');

  /// Whether [mode] is [DateTimePickerMode.range].
  bool get isRange => mode == DateTimePickerMode.range;
}

// SUMMARY
// Everything that shapes one picker: single or range mode, opening values, date bounds, whether past times
// are allowed, start-now and today-only rules, time format and step, the now action, an optional async
// validator, the labels and an optional primary colour.
