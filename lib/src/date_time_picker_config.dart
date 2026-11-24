import 'dart:async';

import 'date_time_picker_labels.dart';
import 'date_time_picker_result.dart';

enum DateTimePickerMode { single, range }

typedef DateTimePickerValidator = FutureOr<String?> Function(DateTimePickerResult result);

class DateTimePickerConfig {
  final DateTimePickerMode mode;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  // Null means the earliest start is the moment the picker opens, or 100 years back when past is allowed.
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowPast;
  final bool startNowOnly;
  final bool todayOnly;
  // Null follows the device's 24-hour setting.
  final bool? use24HourFormat;
  final int minuteInterval;
  final bool showNowAction;
  // Returning a message keeps the picker open and shows it; null lets the picker close.
  final DateTimePickerValidator? validator;
  final DateTimePickerLabels labels;

  const DateTimePickerConfig({
    this.mode = DateTimePickerMode.single, this.initialStart, this.initialEnd, this.firstDate, this.lastDate,
    this.allowPast = false, this.startNowOnly = false, this.todayOnly = false, this.use24HourFormat, this.minuteInterval = 1,
    this.showNowAction = false, this.validator, this.labels = const DateTimePickerLabels(),
  }) : assert(minuteInterval > 0 && 60 % minuteInterval == 0, 'minuteInterval must divide 60'),
       assert(!allowPast || !startNowOnly, 'allowPast and startNowOnly cannot be combined'),
       assert(!startNowOnly || mode == DateTimePickerMode.range, 'startNowOnly applies to range mode only'),
       assert(!showNowAction || mode == DateTimePickerMode.single, 'showNowAction applies to single mode only');

  bool get isRange => mode == DateTimePickerMode.range;
}

// SUMMARY
// Everything that shapes one picker: single or range mode, opening values, date bounds, whether past times
// are allowed, start-now and today-only rules, time format and step, the now action, an optional async
// validator and the labels.
