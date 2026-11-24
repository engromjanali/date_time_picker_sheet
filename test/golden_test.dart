import 'package:date_time_picker_sheet/date_time_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixed dates in the future keep the shown month and the today marker stable between runs.
final DateTime _start = DateTime(2030, 3, 14, 10, 30);
final DateTime _first = DateTime(2030, 1, 1);

Future<void> _pump(WidgetTester tester, Widget picker, {required Size size, ThemeData? theme, TextDirection direction = TextDirection.ltr}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? ThemeData(colorSchemeSeed: const Color(0xFF039D55)),
    home: Directionality(textDirection: direction, child: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: picker))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sheet, single, light', (tester) async {
    await _pump(tester, DateTimePickerSheet(config: DateTimePickerConfig(initialStart: _start, firstDate: _first, use24HourFormat: false, showNowAction: true)), size: const Size(400, 860));
    await expectLater(find.byType(DateTimePickerSheet), matchesGoldenFile('goldens/sheet_single_light.png'));
  });

  testWidgets('sheet, range, dark', (tester) async {
    await _pump(
      tester,
      DateTimePickerSheet(config: DateTimePickerConfig(mode: DateTimePickerMode.range, initialStart: _start, initialEnd: DateTime(2030, 3, 18, 9), firstDate: _first, use24HourFormat: false)),
      size: const Size(400, 900),
      theme: ThemeData(brightness: Brightness.dark, colorSchemeSeed: const Color(0xFF039D55)),
    );
    await expectLater(find.byType(DateTimePickerSheet), matchesGoldenFile('goldens/sheet_range_dark.png'));
  });

  testWidgets('dialog, range, light', (tester) async {
    await _pump(
      tester,
      DateTimePickerDialog(config: DateTimePickerConfig(mode: DateTimePickerMode.range, initialStart: _start, initialEnd: DateTime(2030, 3, 18, 9), firstDate: _first, use24HourFormat: true)),
      size: const Size(1280, 900),
    );
    await expectLater(find.byType(DateTimePickerDialog), matchesGoldenFile('goldens/dialog_range_light.png'));
  });

  testWidgets('sheet, single, right-to-left', (tester) async {
    await _pump(tester, DateTimePickerSheet(config: DateTimePickerConfig(initialStart: _start, firstDate: _first, use24HourFormat: false)), size: const Size(400, 860), direction: TextDirection.rtl);
    await expectLater(find.byType(DateTimePickerSheet), matchesGoldenFile('goldens/sheet_single_rtl.png'));
  });
}

// SUMMARY
// Golden screenshots of the picker: single sheet in light, range sheet in dark, range dialog on a wide
// screen, and the single sheet right to left.
