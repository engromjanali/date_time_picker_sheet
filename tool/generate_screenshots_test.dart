// Renders the screenshots used by the README and the pub.dev gallery.
//
// Run from the package root:  flutter test tool/generate_screenshots_test.dart
// The test fonts draw text as solid blocks, so this loads Roboto and Material
// Icons from the Flutter SDK and writes real-looking PNGs into screenshots/.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:date_time_picker_sheet/date_time_picker_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

const Size _phone = Size(390, 844);
const Size _desktop = Size(1100, 760);
const Color _brand = Color(0xFF039D55);

final GlobalKey _shotKey = GlobalKey();
final DateTime _now = DateTime.now();

DateTime _at(int daysAhead, int hour, [int minute = 0]) {
  final DateTime day = _now.add(Duration(days: daysAhead));
  return DateTime(day.year, day.month, day.day, hour, minute);
}

// A day of next month, so a range's band is always fully inside the month the calendar opens on.
DateTime _nextMonth(int day, int hour, [int minute = 0]) => DateTime(_now.year, _now.month + 1, day, hour, minute);

Future<void> _loadFont(String family, List<String> files) async {
  final String root = Platform.environment['FLUTTER_ROOT']!;
  final FontLoader loader = FontLoader(family);
  for (final String file in files) {
    final Uint8List bytes = File('$root/bin/cache/artifacts/material_fonts/$file').readAsBytesSync();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

ThemeData _theme(Brightness brightness) {
  return ThemeData(useMaterial3: true, brightness: brightness, colorSchemeSeed: _brand, fontFamily: 'Roboto');
}

Widget _backdrop(bool isDark) {
  final Color page = isDark ? const Color(0xFF151A17) : const Color(0xFFEDEFF2);
  final Color card = isDark ? const Color(0xFF222823) : Colors.white;
  return ColoredBox(
    color: page,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 0),
      child: Column(children: [
        for (int i = 0; i < 4; i++)
          Container(
            height: 96,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16)),
          ),
      ]),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget picker, {required Size size, bool isDark = false, bool asSheet = true}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: _theme(isDark ? Brightness.dark : Brightness.light),
    home: RepaintBoundary(
      key: _shotKey,
      child: Stack(children: [
        Positioned.fill(child: _backdrop(isDark)),
        const Positioned.fill(child: ColoredBox(color: Color(0x73000000))),
        if (asSheet) Align(alignment: Alignment.bottomCenter, child: picker) else Center(child: picker),
      ]),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, String name) async {
  final RenderRepaintBoundary boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
  final ByteData? bytes = await tester.runAsync<ByteData?>(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    return image.toByteData(format: ui.ImageByteFormat.png);
  });
  Directory('screenshots').createSync();
  File('screenshots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  debugDisableShadows = true;
  await tester.pumpWidget(const SizedBox());
}

void main() {
  setUpAll(() async {
    await _loadFont('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
    await _loadFont('MaterialIcons', ['MaterialIcons-Regular.otf']);
  });

  // Real shadows for the screenshots; _save puts the flag back before the framework checks it.
  setUp(() => debugDisableShadows = false);

  testWidgets('single sheet', (tester) async {
    final DateTimePickerConfig config = DateTimePickerConfig(initialStart: _at(2, 10, 30), showNowAction: true, use24HourFormat: false);
    await _pump(tester, DateTimePickerSheet(config: config), size: _phone);
    await _save(tester, 'single_sheet');
  });

  testWidgets('range sheet, dark', (tester) async {
    final DateTimePickerConfig config = DateTimePickerConfig(
      mode: DateTimePickerMode.range, initialStart: _nextMonth(10, 10, 30), initialEnd: _nextMonth(17, 9), use24HourFormat: false,
    );
    await _pump(tester, DateTimePickerSheet(config: config), size: const Size(390, 900), isDark: true);
    await _save(tester, 'range_sheet_dark');
  });

  testWidgets('range dialog', (tester) async {
    final DateTimePickerConfig config = DateTimePickerConfig(
      mode: DateTimePickerMode.range, initialStart: _nextMonth(10, 10, 30), initialEnd: _nextMonth(17, 9), use24HourFormat: true,
    );
    await _pump(tester, DateTimePickerDialog(config: config), size: _desktop, asSheet: false);
    await _save(tester, 'range_dialog');
  });

  testWidgets('month view', (tester) async {
    final DateTimePickerConfig config = DateTimePickerConfig(initialStart: _at(2, 10, 30), use24HourFormat: false);
    await _pump(tester, DateTimePickerSheet(config: config), size: _phone);
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await _save(tester, 'month_view');
  });

  testWidgets('blocked time', (tester) async {
    final DateTime today = DateTime(_now.year, _now.month, _now.day);
    // Earliest slot is 15:00 today, so tapping AM is refused with a snackbar.
    final DateTimePickerConfig config = DateTimePickerConfig(
      firstDate: today.add(const Duration(hours: 15)), initialStart: today.add(const Duration(hours: 16)), use24HourFormat: false,
    );
    await _pump(tester, DateTimePickerSheet(config: config), size: _phone);
    await tester.tap(find.text('AM'));
    // The first frame starts the snackbar's fade-in; the second lets it finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _save(tester, 'blocked_time');
  });
}

// SUMMARY
// Screenshot generator for the README and pub.dev: renders the single sheet, the dark range sheet, the range
// dialog, the month view and the blocked-time snackbar with real fonts into screenshots/.
