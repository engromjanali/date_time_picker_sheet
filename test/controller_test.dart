import 'package:date_time_picker_sheet/date_time_picker_sheet.dart';
import 'package:date_time_picker_sheet/src/controller/date_time_picker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DateTime now = DateTime(2030, 3, 14, 10, 30, 20);
  DateTimePickerController build(DateTimePickerConfig config) => DateTimePickerController(config, clock: () => now);

  setUp(() => now = DateTime(2030, 3, 14, 10, 30, 20));

  group('opening values', () {
    test('defaults to the next whole minute today', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig());
      expect(controller.start, DateTime(2030, 3, 14, 10, 31));
      expect(controller.firstDay, DateTime(2030, 3, 14));
      expect(controller.lastDay, DateTime(2035, 12, 31));
    });

    test('rounds up to the minute interval', () {
      expect(build(const DateTimePickerConfig(minuteInterval: 15)).start, DateTime(2030, 3, 14, 10, 45));
    });

    test('rounding past the hour rolls over', () {
      now = DateTime(2030, 3, 14, 23, 50);
      expect(build(const DateTimePickerConfig(minuteInterval: 15)).start, DateTime(2030, 3, 15));
    });

    test('a past initial start opens on the earliest start instead', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(initialStart: DateTime(2030, 3, 1, 9)));
      expect(controller.start, DateTime(2030, 3, 14, 10, 31));
    });

    test('a future initial start is kept, rounded to the interval', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(initialStart: DateTime(2030, 4, 2, 9, 7), minuteInterval: 5));
      expect(controller.start, DateTime(2030, 4, 2, 9, 10));
    });

    test('range end defaults to an hour after the start', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(mode: DateTimePickerMode.range, initialStart: DateTime(2030, 4, 2, 9)));
      expect(controller.end, DateTime(2030, 4, 2, 10));
    });

    test('allowPast opens on now but accepts past days and times', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig(allowPast: true));
      expect(controller.start, DateTime(2030, 3, 14, 10, 31));
      expect(controller.firstDay, DateTime(1930));

      controller.selectDay(DateTime(2029, 12, 1));
      controller.setStartTime(const TimeOfDay(hour: 6, minute: 0));
      expect(controller.start, DateTime(2029, 12, 1, 6));
      expect(controller.validate(), isNull);
    });

    test('allowPast also lets a past initial start through', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(allowPast: true, initialStart: DateTime(2030, 3, 1, 9)));
      expect(controller.start, DateTime(2030, 3, 1, 9));
      expect(controller.minimumStartTime, isNull);
    });

    test('an explicit past first date allows past starts', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(firstDate: DateTime(2000), initialStart: DateTime(2020, 5, 1, 8)));
      expect(controller.start, DateTime(2020, 5, 1, 8));
      expect(controller.validate(), isNull);
    });
  });

  group('day selection', () {
    test('days outside the bounds are ignored', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig());
      controller.selectDay(DateTime(2030, 3, 13));
      expect(controller.startDate, DateTime(2030, 3, 14));
    });

    test('range taps pick a start, then an end', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig(mode: DateTimePickerMode.range));
      controller.selectDay(DateTime(2030, 3, 20));
      expect(controller.awaitingEnd, isTrue);
      controller.selectDay(DateTime(2030, 3, 25));
      expect(controller.awaitingEnd, isFalse);
      expect(controller.startDate, DateTime(2030, 3, 20));
      expect(controller.endDate, DateTime(2030, 3, 25));
    });

    test('a range tap before the start restarts the range', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig(mode: DateTimePickerMode.range));
      controller.selectDay(DateTime(2030, 3, 20));
      controller.selectDay(DateTime(2030, 3, 18));
      expect(controller.startDate, DateTime(2030, 3, 18));
      expect(controller.awaitingEnd, isTrue);
    });

    test('start-now ranges only move the end day', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig(mode: DateTimePickerMode.range, startNowOnly: true));
      controller.selectDay(DateTime(2030, 3, 22));
      expect(controller.endDate, DateTime(2030, 3, 22));
      expect(controller.rangeStartDay, DateTime(2030, 3, 14));
      expect(controller.result().start, now);
    });

    test('today-only limits the bounds to today', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(todayOnly: true, initialStart: DateTime(2030, 3, 20, 9)));
      expect(controller.firstDay, DateTime(2030, 3, 14));
      expect(controller.lastDay, DateTime(2030, 3, 14));
      expect(controller.startDate, DateTime(2030, 3, 14));
    });
  });

  group('times', () {
    test('a start time before the earliest slot today is raised to it', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig());
      controller.setStartTime(const TimeOfDay(hour: 8, minute: 0));
      expect(controller.startTime, const TimeOfDay(hour: 10, minute: 31));
    });

    test('an early start time on a later day is kept', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig());
      controller.selectDay(DateTime(2030, 3, 15));
      controller.setStartTime(const TimeOfDay(hour: 8, minute: 0));
      expect(controller.start, DateTime(2030, 3, 15, 8));
      expect(controller.minimumStartTime, isNull);
    });

    test('a same-day end is pushed past the start', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(mode: DateTimePickerMode.range, initialStart: DateTime(2030, 4, 2, 9)));
      controller.selectDay(DateTime(2030, 4, 2));
      controller.selectDay(DateTime(2030, 4, 2));
      controller.setEndTime(const TimeOfDay(hour: 8, minute: 0));
      expect(controller.end, DateTime(2030, 4, 2, 9, 1));
    });

    test('a start in the last slot of the day pushes the end into the next day', () {
      final DateTimePickerController controller = build(DateTimePickerConfig(
        mode: DateTimePickerMode.range, minuteInterval: 15, initialStart: DateTime(2030, 4, 2, 22), initialEnd: DateTime(2030, 4, 2, 23),
      ));
      controller.setStartTime(const TimeOfDay(hour: 23, minute: 45));
      expect(controller.end, DateTime(2030, 4, 3));
      expect(controller.validate(), isNull);
    });
  });

  group('validation and result', () {
    test('a start that fell behind the clock is rejected', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig());
      now = now.add(const Duration(minutes: 5));
      expect(controller.validate(), const DateTimePickerLabels().startInPast);
    });

    test('a valid single pick has no end', () {
      final DateTimePickerController controller = build(const DateTimePickerConfig());
      expect(controller.validate(), isNull);
      expect(controller.result().end, isNull);
    });

    test('the now result is flagged and uses the clock', () {
      final DateTimePickerResult result = build(const DateTimePickerConfig(showNowAction: true)).nowResult();
      expect(result.isNow, isTrue);
      expect(result.start, now);
    });
  });
}

// SUMMARY
// Unit tests for the picker controller against a fixed clock: opening values and rounding, bounds, range
// tapping, start-now and today-only rules, time clamping, validation and the result it builds.
