import 'package:date_time_picker_sheet/date_time_picker_sheet.dart';
import 'package:date_time_picker_sheet_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _start(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ExampleApp());
}

Future<void> _openPicker(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Open picker'));
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
}

Future<void> _confirmAndShowResult(WidgetTester tester) async {
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.textContaining('Start:'));
}

void main() {
  testWidgets('phone opens a sheet and shows the picked start', (tester) async {
    await _start(tester, const Size(400, 860));
    await _openPicker(tester);
    expect(find.byType(DateTimePickerSheet), findsOneWidget);

    await _confirmAndShowResult(tester);
    expect(find.textContaining('Start:'), findsOneWidget);
  });

  testWidgets('wide screen opens a range dialog and shows start and end', (tester) async {
    await _start(tester, const Size(1280, 900));
    await tester.tap(find.text('Range'));
    await tester.pumpAndSettle();
    await _openPicker(tester);
    expect(find.byType(DateTimePickerDialog), findsOneWidget);

    await _confirmAndShowResult(tester);
    expect(find.textContaining('End:'), findsOneWidget);
  });
}

// SUMMARY
// Smoke tests for the example gallery: a phone opens the sheet and a wide screen opens the range dialog, and
// each shows what the picker returned.
