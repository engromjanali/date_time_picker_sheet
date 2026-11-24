import 'package:flutter/material.dart';

import '../picker_style.dart';
import 'am_pm_toggle.dart';
import 'time_wheel.dart';

class TimePicker extends StatelessWidget {
  final TimeOfDay value;
  final TimeOfDay? minimum;
  final bool use24HourFormat;
  final int minuteInterval;
  final String amLabel;
  final String pmLabel;
  final ValueChanged<TimeOfDay> onChanged;
  final ValueChanged<bool> onMovingChanged;

  const TimePicker({super.key,
    required this.value, required this.minimum, required this.use24HourFormat, required this.minuteInterval, required this.amLabel,
    required this.pmLabel, required this.onChanged, required this.onMovingChanged,
  });

  bool get _isPm => value.hour >= 12;

  int _hourAt(int index) => use24HourFormat ? index : index + (_isPm ? 12 : 0);

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final TimeOfDay? earliest = minimum;

    return Row(children: [
      // Hours stay left of minutes in every language, as in Material's own time picker.
      Expanded(child: Directionality(textDirection: TextDirection.ltr, child: Stack(alignment: Alignment.center, children: [
        Container(
          height: TimeWheel.itemExtent,
          decoration: BoxDecoration(color: style.surface, borderRadius: BorderRadius.circular(style.cellRadius)),
        ),
        Row(children: [
          Expanded(child: TimeWheel(
            itemCount: use24HourFormat ? 24 : 12,
            selectedIndex: use24HourFormat ? value.hour : value.hour % 12,
            labelOf: (int index) => localizations.formatHour(TimeOfDay(hour: _hourAt(index), minute: 0), alwaysUse24HourFormat: use24HourFormat),
            isDisabled: (int index) => earliest != null && _hourAt(index) < earliest.hour,
            semanticsLabel: localizations.timePickerHourLabel,
            onSelected: (int index) => onChanged(TimeOfDay(hour: _hourAt(index), minute: value.minute)),
            onMovingChanged: onMovingChanged,
          )),
          Text(':', style: Theme.of(context).textTheme.titleMedium),
          Expanded(child: TimeWheel(
            itemCount: 60 ~/ minuteInterval,
            selectedIndex: value.minute ~/ minuteInterval,
            labelOf: (int index) => localizations.formatMinute(TimeOfDay(hour: 0, minute: index * minuteInterval)),
            isDisabled: (int index) => earliest != null && value.hour == earliest.hour && index * minuteInterval < earliest.minute,
            semanticsLabel: localizations.timePickerMinuteLabel,
            onSelected: (int index) => onChanged(TimeOfDay(hour: value.hour, minute: index * minuteInterval)),
            onMovingChanged: onMovingChanged,
          )),
        ]),
      ]))),

      if (!use24HourFormat) ...[
        const SizedBox(width: 12),
        AmPmToggle(
          isPm: _isPm, isAmEnabled: earliest == null || earliest.hour < 12, amLabel: amLabel, pmLabel: pmLabel,
          onChanged: (bool isPm) => onChanged(TimeOfDay(hour: value.hour % 12 + (isPm ? 12 : 0), minute: value.minute)),
        ),
      ],
    ]);
  }
}

// SUMMARY
// Hour and minute wheels on a shared selection band, with an AM/PM switch in 12-hour mode; values before the
// earliest allowed time are shown disabled, and every change is reported as a TimeOfDay.
