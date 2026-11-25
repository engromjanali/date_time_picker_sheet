import 'package:date_time_picker_sheet/date_time_picker_sheet.dart';
import 'package:date_time_picker_sheet/src/calendar/calendar_header.dart';
import 'package:date_time_picker_sheet/src/calendar/day_grid.dart';
import 'package:date_time_picker_sheet/src/time/time_wheel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _phone = Size(400, 860);
const Size _desktop = Size(1280, 900);

final DateTimePickerConfig _single = DateTimePickerConfig(
  initialStart: DateTime(2030, 3, 14, 10, 30), firstDate: DateTime(2030, 1, 1), lastDate: DateTime(2031, 12, 31), use24HourFormat: false,
);

final DateTimePickerConfig _range = DateTimePickerConfig(
  mode: DateTimePickerMode.range, initialStart: DateTime(2030, 3, 14, 10, 30), firstDate: DateTime(2030, 1, 1),
  lastDate: DateTime(2031, 12, 31), use24HourFormat: false,
);

class _Harness {
  DateTimePickerResult? result;
  bool closed = false;
}

Future<_Harness> _open(WidgetTester tester, DateTimePickerConfig config, {
  Size size = _phone, DateTimePickerPresentation presentation = DateTimePickerPresentation.auto,
  TextDirection direction = TextDirection.ltr, double textScale = 1,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final _Harness harness = _Harness();
  await tester.pumpWidget(MaterialApp(
    builder: (BuildContext context, Widget? child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Directionality(textDirection: direction, child: child!),
    ),
    home: Builder(builder: (BuildContext context) => Scaffold(body: Center(child: TextButton(
      onPressed: () async {
        harness.result = await showDateTimePicker(context, config: config, presentation: presentation);
        harness.closed = true;
      },
      child: const Text('open'),
    )))),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return harness;
}

Finder _day(int day) => find.descendant(of: find.byType(DayGrid), matching: find.text('$day'));

// Painted width over laid-out width: 1 when the title is shown at full size.
double _titleScale(WidgetTester tester, String title) {
  final Finder text = find.text(title);
  return tester.getRect(text).width / tester.renderObject<RenderBox>(text).size.width;
}

Future<void> _confirm(WidgetTester tester) async {
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
}

void main() {
  group('presentation', () {
    testWidgets('auto opens a sheet on a phone', (tester) async {
      await _open(tester, _single);
      expect(find.byType(DateTimePickerSheet), findsOneWidget);
    });

    testWidgets('auto opens a dialog on a wide screen', (tester) async {
      await _open(tester, _range, size: _desktop);
      expect(find.byType(DateTimePickerDialog), findsOneWidget);
    });

    testWidgets('a forced presentation wins over the screen width', (tester) async {
      await _open(tester, _single, presentation: DateTimePickerPresentation.dialog);
      expect(find.byType(DateTimePickerDialog), findsOneWidget);
    });
  });

  group('result', () {
    testWidgets('confirm returns the opening moment', (tester) async {
      final _Harness harness = await _open(tester, _single);
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 14, 10, 30));
      expect(harness.result!.end, isNull);
    });

    testWidgets('cancel returns null', (tester) async {
      final _Harness harness = await _open(tester, _single);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(harness.closed, isTrue);
      expect(harness.result, isNull);
    });

    testWidgets('tapping a day changes the date', (tester) async {
      final _Harness harness = await _open(tester, _single);
      await tester.tap(_day(20));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 20, 10, 30));
    });

    testWidgets('the first tap on a later day sets the end and keeps the opening start', (tester) async {
      final _Harness harness = await _open(tester, _range, size: _desktop);
      await tester.tap(_day(18));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 14, 10, 30));
      expect(harness.result!.end, DateTime(2030, 3, 18, 11, 30));
    });

    testWidgets('after an end is set, two taps pick a new range', (tester) async {
      final _Harness harness = await _open(tester, _range, size: _desktop);
      await tester.tap(_day(18));
      await tester.pumpAndSettle();
      await tester.tap(_day(20));
      await tester.pumpAndSettle();
      await tester.tap(_day(22));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 20, 10, 30));
      expect(harness.result!.end, DateTime(2030, 3, 22, 11, 30));
    });

    testWidgets('with the now action, all three buttons sit on one row on a phone', (tester) async {
      await _open(tester, DateTimePickerConfig(showNowAction: true, initialStart: DateTime(2030, 3, 14, 10, 30)));
      final double nowRow = tester.getCenter(find.text('Now')).dy;
      expect(tester.getCenter(find.text('Cancel')).dy, moreOrLessEquals(nowRow));
      expect(tester.getCenter(find.text('Confirm')).dy, moreOrLessEquals(nowRow));
      expect(tester.getCenter(find.text('Now')).dx, lessThan(tester.getCenter(find.text('Cancel')).dx));
    });

    testWidgets('the now action returns a flagged now result', (tester) async {
      final DateTimePickerConfig config = DateTimePickerConfig(showNowAction: true, initialStart: DateTime(2030, 3, 14, 10, 30));
      final _Harness harness = await _open(tester, config);
      await tester.tap(find.text('Now'));
      await tester.pumpAndSettle();
      expect(harness.result!.isNow, isTrue);
    });
  });

  group('primary colour', () {
    ButtonStyle confirmStyle(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm')).style!;

    testWidgets('primaryColor colours the picker and picks readable text on it', (tester) async {
      await _open(tester, DateTimePickerConfig(initialStart: DateTime(2030, 3, 14, 10, 30), primaryColor: const Color(0xFFFFEB3B)));
      expect(confirmStyle(tester).backgroundColor!.resolve({}), const Color(0xFFFFEB3B));
      expect(confirmStyle(tester).foregroundColor!.resolve({}), Colors.black);
    });

    testWidgets('without primaryColor the theme colour is used', (tester) async {
      await _open(tester, DateTimePickerConfig(initialStart: DateTime(2030, 3, 14, 10, 30)));
      final BuildContext context = tester.element(find.text('Confirm'));
      expect(confirmStyle(tester).backgroundColor!.resolve({}), Theme.of(context).colorScheme.primary);
    });
  });

  group('validator', () {
    testWidgets('an error keeps the picker open and shows it', (tester) async {
      final DateTimePickerConfig config = DateTimePickerConfig(
        initialStart: DateTime(2030, 3, 14, 10, 30), firstDate: DateTime(2030, 1, 1),
        validator: (DateTimePickerResult result) async => result.start.day == 14 ? 'Fully booked' : null,
      );
      final _Harness harness = await _open(tester, config);
      await _confirm(tester);
      expect(find.text('Fully booked'), findsOneWidget);
      expect(harness.closed, isFalse);

      await tester.tap(_day(15));
      await tester.pumpAndSettle();
      expect(find.text('Fully booked'), findsNothing);
      await _confirm(tester);
      expect(harness.result!.start.day, 15);
    });

    testWidgets('a throwing validator is reported and shown, and the picker stays open', (tester) async {
      final DateTimePickerConfig config = DateTimePickerConfig(
        initialStart: DateTime(2030, 3, 14, 10, 30), firstDate: DateTime(2030, 1, 1),
        validator: (DateTimePickerResult result) async => throw StateError('offline'),
      );
      final _Harness harness = await _open(tester, config);
      await _confirm(tester);
      expect(tester.takeException(), isA<StateError>());
      expect(find.text(const DateTimePickerLabels().validationFailed), findsOneWidget);
      expect(harness.closed, isFalse);
    });
  });

  group('calendar views', () {
    testWidgets('the title opens months, then years, and picks come back down', (tester) async {
      await _open(tester, _single);
      await tester.tap(find.text('March 2030'));
      await tester.pumpAndSettle();
      expect(find.text('Jun'), findsOneWidget);

      await tester.tap(find.text('2030'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2031'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jun'));
      await tester.pumpAndSettle();
      expect(find.text('June 2031'), findsOneWidget);
    });

    testWidgets('arrows stop at the date bounds', (tester) async {
      final DateTimePickerConfig config = DateTimePickerConfig(initialStart: DateTime(2030, 1, 10, 9), firstDate: DateTime(2030, 1, 1), lastDate: DateTime(2030, 2, 28));
      await _open(tester, config);
      final Finder previous = find.widgetWithIcon(IconButton, Icons.chevron_left);
      final Finder next = find.widgetWithIcon(IconButton, Icons.chevron_right);
      expect(tester.widget<IconButton>(previous).onPressed, isNull);

      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(find.text('February 2030'), findsOneWidget);
      expect(tester.widget<IconButton>(next).onPressed, isNull);
    });

    testWidgets('the arrows sit at the end and the title shows in full in a dialog', (tester) async {
      await _open(tester, DateTimePickerConfig(initialStart: DateTime(2030, 11, 14, 10, 30), firstDate: DateTime(2030)), size: _desktop);
      final Rect header = tester.getRect(find.byType(CalendarHeader));
      expect(tester.getRect(find.widgetWithIcon(IconButton, Icons.chevron_right)).right, moreOrLessEquals(header.right));
      expect(_titleScale(tester, 'November 2030'), 1);
    });

    testWidgets('a narrow header scales the title down instead of cutting it', (tester) async {
      await _open(tester, DateTimePickerConfig(initialStart: DateTime(2030, 11, 14, 10, 30), firstDate: DateTime(2030)), size: const Size(280, 860));
      expect(_titleScale(tester, 'November 2030'), lessThan(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('allowPast lets an earlier month be picked and confirmed', (tester) async {
      final _Harness harness = await _open(tester, const DateTimePickerConfig(allowPast: true));
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(_day(1));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(harness.result!.start.isBefore(DateTime.now()), isTrue);
    });

    testWidgets('months outside the bounds are disabled', (tester) async {
      final DateTimePickerConfig config = DateTimePickerConfig(initialStart: DateTime(2030, 3, 10, 9), firstDate: DateTime(2030, 3, 1));
      await _open(tester, config);
      await tester.tap(find.text('March 2030'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jan'));
      await tester.pumpAndSettle();
      expect(find.text('Jan'), findsOneWidget);
    });
  });

  group('time wheels', () {
    testWidgets('a mouse wheel scroll that stops between rows snaps and commits', (tester) async {
      final _Harness harness = await _open(tester, _single);
      final Finder minutes = find.byType(TimeWheel).at(1);
      final TestPointer mouse = TestPointer(1, PointerDeviceKind.mouse);
      mouse.hover(tester.getCenter(minutes));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 22)));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 14, 10, 31));
    });

    testWidgets('dragging the hour wheel changes the hour', (tester) async {
      final _Harness harness = await _open(tester, _single);
      // A timed drag sends many small moves like a real finger; one big jump lets the sheet's own drag win.
      await tester.timedDrag(find.byType(TimeWheel).first, const Offset(0, -50), const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 14, 11, 30));
    });

    testWidgets('PM moves the time into the afternoon', (tester) async {
      final _Harness harness = await _open(tester, _single);
      await tester.tap(find.text('PM'));
      await tester.pumpAndSettle();
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 14, 22, 30));
    });

    testWidgets('tapping a greyed AM explains why and keeps the time', (tester) async {
      final DateTimePickerConfig config = DateTimePickerConfig(initialStart: DateTime(2030, 3, 14, 16), firstDate: DateTime(2030, 3, 14, 15), use24HourFormat: false);
      final _Harness harness = await _open(tester, config);
      await tester.tap(find.text('AM'));
      await tester.pump();
      expect(find.text(const DateTimePickerLabels().startInPast), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text(const DateTimePickerLabels().startInPast), findsNothing);
      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 14, 16));
    });

    testWidgets('a wheel that lands on a blocked minute rolls back with a note', (tester) async {
      final DateTimePickerConfig config = DateTimePickerConfig(initialStart: DateTime(2030, 3, 14, 10, 30), firstDate: DateTime(2030, 3, 14, 10, 30), use24HourFormat: false);
      final _Harness harness = await _open(tester, config);
      final TestPointer mouse = TestPointer(1, PointerDeviceKind.mouse);
      mouse.hover(tester.getCenter(find.byType(TimeWheel).at(1)));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, -TimeWheel.itemExtent)));
      await tester.pumpAndSettle();
      expect(find.text(const DateTimePickerLabels().startInPast), findsOneWidget);

      await _confirm(tester);
      expect(harness.result!.start, DateTime(2030, 3, 14, 10, 30));
    });

    testWidgets('an end wheel landing before the start shows the end message', (tester) async {
      await _open(tester, _range, size: _desktop);
      final TestPointer mouse = TestPointer(1, PointerDeviceKind.mouse);
      mouse.hover(tester.getCenter(find.byType(TimeWheel).at(2)));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, -TimeWheel.itemExtent)));
      await tester.pumpAndSettle();
      expect(find.text(const DateTimePickerLabels().endNotAfterStart), findsOneWidget);
    });

    testWidgets('24-hour format hides AM and PM', (tester) async {
      await _open(tester, DateTimePickerConfig(initialStart: DateTime(2030, 3, 14, 10, 30), use24HourFormat: true));
      expect(find.text('AM'), findsNothing);
      expect(find.text('PM'), findsNothing);
    });
  });

  group('layout', () {
    testWidgets('right-to-left opens without layout errors', (tester) async {
      await _open(tester, _range, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      expect(find.text('Select Start & Return Date & Time'), findsOneWidget);
    });

    testWidgets('right-to-left keeps hours left of minutes', (tester) async {
      await _open(tester, _single, direction: TextDirection.rtl);
      expect(tester.getCenter(find.byType(TimeWheel).first).dx, lessThan(tester.getCenter(find.byType(TimeWheel).at(1)).dx));
    });

    testWidgets('large text scale opens without overflow', (tester) async {
      await _open(tester, _range, textScale: 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hovering a day with the mouse paints without errors', (tester) async {
      await _open(tester, _range, size: _desktop);
      await tester.tap(_day(16));
      await tester.pumpAndSettle();
      final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_day(20)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

// SUMMARY
// Widget tests for the picker: sheet, dialog and auto presentation, results from confirm, cancel, day taps,
// ranges and the now action, the async validator, calendar views and bounds, time wheels by mouse wheel,
// drag and AM/PM, and layout in RTL, at large text scale and under mouse hover.
