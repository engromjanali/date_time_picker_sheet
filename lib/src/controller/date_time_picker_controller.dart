import 'package:flutter/material.dart';

import '../date_time_picker_config.dart';
import '../date_time_picker_result.dart';

class DateTimePickerController extends ChangeNotifier {
  final DateTimePickerConfig config;
  final DateTime Function() _clock;

  late final DateTime today;
  // A fixed earliest start; null means the earliest start follows the clock.
  late final DateTime? _fixedFloor;
  late final DateTime earliestStart;
  late final DateTime firstDay;
  late final DateTime lastDay;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _awaitingEnd = false;

  DateTimePickerController(this.config, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    final DateTime now = _clock();
    today = DateUtils.dateOnly(now);
    _fixedFloor = config.firstDate ?? (config.allowPast ? DateTime(now.year - 100) : null);
    earliestStart = _ceilToInterval(_fixedFloor ?? now);
    firstDay = config.startNowOnly || config.todayOnly ? today : DateUtils.dateOnly(earliestStart);
    final DateTime last = config.todayOnly ? today : DateUtils.dateOnly(config.lastDate ?? DateTime(now.year + 5, 12, 31));
    lastDay = last.isBefore(firstDay) ? firstDay : last;

    final DateTime start = config.startNowOnly ? now : _initialStart();
    _startDate = DateUtils.dateOnly(start);
    _startTime = TimeOfDay.fromDateTime(start);
    final DateTime end = _initialEnd(start);
    _endDate = DateUtils.dateOnly(end);
    _endTime = TimeOfDay.fromDateTime(end);
    // A range that opens on one day has no end picked yet, so the first tap on a later day becomes its end.
    _awaitingEnd = config.isRange && !config.startNowOnly && _endDate == _startDate;
    _clampTimes();
  }

  DateTime get startDate => _startDate;
  TimeOfDay get startTime => _startTime;
  DateTime get endDate => _endDate;
  TimeOfDay get endTime => _endTime;
  bool get awaitingEnd => _awaitingEnd;
  DateTime get start => _combine(_startDate, _startTime);
  DateTime get end => _combine(_endDate, _endTime);
  DateTime get rangeStartDay => config.startNowOnly ? today : _startDate;
  DateTime get focusedDay => config.startNowOnly ? _endDate : _startDate;

  TimeOfDay? get minimumStartTime => DateUtils.isSameDay(_startDate, earliestStart) ? TimeOfDay.fromDateTime(earliestStart) : null;

  TimeOfDay? get minimumEndTime {
    final DateTime earliestEnd = _earliestEnd();
    return DateUtils.isSameDay(_endDate, earliestEnd) ? TimeOfDay.fromDateTime(earliestEnd) : null;
  }

  bool isSelectable(DateTime day) => !day.isBefore(firstDay) && !day.isAfter(lastDay);

  void selectDay(DateTime day) {
    if (!isSelectable(day)) return;
    if (!config.isRange) {
      _startDate = day;
    } else if (config.startNowOnly) {
      _endDate = day;
    } else if (_awaitingEnd && !day.isBefore(_startDate)) {
      _endDate = day;
      _awaitingEnd = false;
    } else {
      _startDate = day;
      _endDate = day;
      _awaitingEnd = true;
    }
    _clampTimes();
    notifyListeners();
  }

  bool setStartTime(TimeOfDay time) {
    if (_isBefore(time, minimumStartTime)) return _reject();
    _startTime = time;
    _clampTimes();
    notifyListeners();
    return true;
  }

  bool setEndTime(TimeOfDay time) {
    if (_isBefore(time, minimumEndTime)) return _reject();
    _endTime = time;
    _clampTimes();
    notifyListeners();
    return true;
  }

  // Keeps the current time; notifying still rebuilds the wheels so one that landed on a blocked row rolls back.
  bool _reject() {
    notifyListeners();
    return false;
  }

  static bool _isBefore(TimeOfDay time, TimeOfDay? minimum) {
    return minimum != null && time.hour * 60 + time.minute < minimum.hour * 60 + minimum.minute;
  }

  String? validate() {
    final DateTime now = _clock();
    if (!config.startNowOnly) {
      final DateTime floor = _fixedFloor ?? DateTime(now.year, now.month, now.day, now.hour, now.minute);
      if (start.isBefore(floor)) return config.labels.startInPast;
    }
    if (config.isRange && !end.isAfter(config.startNowOnly ? now : start)) return config.labels.endNotAfterStart;
    return null;
  }

  DateTimePickerResult result() {
    return DateTimePickerResult(start: config.startNowOnly ? _clock() : start, end: config.isRange ? end : null);
  }

  DateTimePickerResult nowResult() => DateTimePickerResult(start: _clock(), isNow: true);

  DateTime _initialStart() {
    final DateTime? initial = config.initialStart;
    if (initial == null) return _defaultStart();
    final DateTime start = _ceilToInterval(initial);
    if (start.isBefore(earliestStart) || DateUtils.dateOnly(start).isAfter(lastDay)) return _defaultStart();
    return start;
  }

  // Opens on the next slot from now even when the past is allowed, unless the bounds start later.
  DateTime _defaultStart() {
    final DateTime upcoming = _ceilToInterval(_clock());
    return upcoming.isBefore(earliestStart) ? earliestStart : upcoming;
  }

  DateTime _initialEnd(DateTime start) {
    final DateTime? initial = config.initialEnd;
    final DateTime end = _ceilToInterval(initial ?? start.add(const Duration(hours: 1)));
    if (!end.isAfter(start) || DateUtils.dateOnly(end).isAfter(lastDay)) {
      return _ceilToInterval(start.add(Duration(minutes: config.minuteInterval)));
    }
    return end;
  }

  DateTime _earliestEnd() {
    final DateTime reference = config.startNowOnly ? _clock() : start;
    // The end has to be strictly after the start, so the first allowed slot is the next one.
    return _ceilToInterval(reference.add(const Duration(seconds: 1)));
  }

  void _clampTimes() {
    if (!config.startNowOnly && start.isBefore(earliestStart)) _startTime = TimeOfDay.fromDateTime(earliestStart);
    if (!config.isRange) return;
    final DateTime earliestEnd = _earliestEnd();
    // Moving the date as well covers a start in the last slot of a day, whose earliest end is tomorrow.
    if (end.isBefore(earliestEnd) && !DateUtils.dateOnly(earliestEnd).isAfter(lastDay)) {
      _endDate = DateUtils.dateOnly(earliestEnd);
      _endTime = TimeOfDay.fromDateTime(earliestEnd);
    }
  }

  DateTime _ceilToInterval(DateTime moment) {
    final int step = config.minuteInterval;
    final bool isOffSlot = moment.second > 0 || moment.millisecond > 0 || moment.microsecond > 0 || moment.minute % step != 0;
    final int minute = isOffSlot ? (moment.minute ~/ step + 1) * step : moment.minute;
    // DateTime rolls a minute of 60 over into the next hour or day.
    return DateTime(moment.year, moment.month, moment.day, moment.hour, minute);
  }

  static DateTime _combine(DateTime date, TimeOfDay time) => DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

// SUMMARY
// Holds the picker's selection — start and end day and time — and its rules: date bounds, slot rounding,
// range tapping, refusing times before their earliest allowed slot, validation and the final result.
