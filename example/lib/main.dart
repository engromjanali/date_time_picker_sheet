import 'package:date_time_picker_sheet/date_time_picker_sheet.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  static const Color _brand = Color(0xFF039D55);
  bool _isDark = false;
  bool _isRtl = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Date Time Picker',
      theme: ThemeData(colorSchemeSeed: _brand),
      darkTheme: ThemeData(brightness: Brightness.dark, colorSchemeSeed: _brand),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (BuildContext context, Widget? child) => Directionality(textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr, child: child!),
      home: ExampleScreen(
        isDark: _isDark, isRtl: _isRtl,
        onDarkChanged: (bool value) => setState(() => _isDark = value),
        onRtlChanged: (bool value) => setState(() => _isRtl = value),
      ),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  final bool isDark;
  final bool isRtl;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<bool> onRtlChanged;
  const ExampleScreen({super.key, required this.isDark, required this.isRtl, required this.onDarkChanged, required this.onRtlChanged});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  DateTimePickerPresentation _presentation = DateTimePickerPresentation.auto;
  DateTimePickerMode _mode = DateTimePickerMode.single;
  bool _startNowOnly = false;
  bool _allowPast = false;
  bool _todayOnly = false;
  bool _showNowAction = false;
  bool _use24Hour = false;
  bool _rejectWeekends = false;
  int _minuteInterval = 1;
  String _lastResult = 'Nothing picked yet';

  bool get _isRange => _mode == DateTimePickerMode.range;

  Future<String?> _weekdaysOnly(DateTimePickerResult result) async {
    // Stands in for a server check, so the confirm loader is visible.
    await Future<void>.delayed(const Duration(seconds: 1));
    return result.start.weekday >= DateTime.saturday ? 'We are closed at weekends' : null;
  }

  Future<void> _open() async {
    final DateTimePickerResult? result = await showDateTimePicker(
      context,
      presentation: _presentation,
      config: DateTimePickerConfig(
        mode: _mode,
        startNowOnly: _isRange && _startNowOnly,
        allowPast: _allowPast && !(_isRange && _startNowOnly),
        todayOnly: _todayOnly,
        showNowAction: !_isRange && _showNowAction,
        use24HourFormat: _use24Hour,
        minuteInterval: _minuteInterval,
        validator: _rejectWeekends ? _weekdaysOnly : null,
      ),
    );
    setState(() => _lastResult = result == null ? 'Dismissed' : _describe(result));
  }

  String _describe(DateTimePickerResult result) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    String format(DateTime value) => '${localizations.formatMediumDate(value)}  '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value), alwaysUse24HourFormat: _use24Hour)}';
    if (result.isNow) return 'Now: ${format(result.start)}';
    final DateTime? end = result.end;
    return end == null ? 'Start: ${format(result.start)}' : 'Start: ${format(result.start)}\nEnd: ${format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Date Time Picker')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<DateTimePickerPresentation>(
          segments: const [
            ButtonSegment(value: DateTimePickerPresentation.auto, label: Text('Auto')),
            ButtonSegment(value: DateTimePickerPresentation.sheet, label: Text('Sheet')),
            ButtonSegment(value: DateTimePickerPresentation.dialog, label: Text('Dialog')),
          ],
          selected: {_presentation},
          onSelectionChanged: (Set<DateTimePickerPresentation> value) => setState(() => _presentation = value.first),
        ),
        const SizedBox(height: 12),
        SegmentedButton<DateTimePickerMode>(
          segments: const [
            ButtonSegment(value: DateTimePickerMode.single, label: Text('Single')),
            ButtonSegment(value: DateTimePickerMode.range, label: Text('Range')),
          ],
          selected: {_mode},
          onSelectionChanged: (Set<DateTimePickerMode> value) => setState(() => _mode = value.first),
        ),
        const SizedBox(height: 8),

        if (_isRange)
          SwitchListTile(title: const Text('Start now only'), value: _startNowOnly, onChanged: (bool value) => setState(() => _startNowOnly = value))
        else
          SwitchListTile(title: const Text('Show "Now" action'), value: _showNowAction, onChanged: (bool value) => setState(() => _showNowAction = value)),
        SwitchListTile(title: const Text('Allow past dates and times'), value: _allowPast, onChanged: (bool value) => setState(() => _allowPast = value)),
        SwitchListTile(title: const Text('Today only'), value: _todayOnly, onChanged: (bool value) => setState(() => _todayOnly = value)),
        SwitchListTile(title: const Text('24-hour time'), value: _use24Hour, onChanged: (bool value) => setState(() => _use24Hour = value)),
        SwitchListTile(title: const Text('Reject weekends (1 s check)'), value: _rejectWeekends, onChanged: (bool value) => setState(() => _rejectWeekends = value)),
        ListTile(
          title: const Text('Minute step'),
          trailing: DropdownButton<int>(
            value: _minuteInterval,
            items: const [1, 5, 15, 30].map((int step) => DropdownMenuItem(value: step, child: Text('$step min'))).toList(),
            onChanged: (int? value) => setState(() => _minuteInterval = value!),
          ),
        ),
        SwitchListTile(title: const Text('Dark theme'), value: widget.isDark, onChanged: widget.onDarkChanged),
        SwitchListTile(title: const Text('Right to left'), value: widget.isRtl, onChanged: widget.onRtlChanged),
        const SizedBox(height: 16),

        FilledButton(onPressed: _open, child: const Text('Open picker')),
        const SizedBox(height: 24),
        Text(_lastResult, style: Theme.of(context).textTheme.titleMedium),
      ]),
    );
  }
}

// SUMMARY
// Example gallery for the package: switches for presentation, mode, start-now, past times, today-only, now action,
// 24-hour time, minute step, an async weekend validator, dark theme and right-to-left, then opens the
// picker and shows what it returned.
