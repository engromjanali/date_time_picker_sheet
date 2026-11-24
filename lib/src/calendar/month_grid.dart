import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controller/date_time_picker_controller.dart';
import 'selectable_tile.dart';

class MonthGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTimePickerController controller;
  final ValueChanged<int> onMonthTap;
  const MonthGrid({super.key, required this.visibleMonth, required this.controller, required this.onMonthTap});

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final DateFormat shortMonth = _shortMonthFormat(Localizations.localeOf(context).toString());
    final int year = visibleMonth.year;

    return Column(children: List.generate(4, (int row) => Expanded(child: Row(children: List.generate(3, (int column) {
      final int month = row * 3 + column + 1;
      final DateTime first = DateTime(year, month);
      final bool isEnabled = !DateTime(year, month + 1, 0).isBefore(controller.firstDay) && !first.isAfter(controller.lastDay);
      return Expanded(child: SelectableTile(
        label: shortMonth.format(first), semanticsLabel: localizations.formatMonthYear(first),
        isSelected: month == visibleMonth.month, isEnabled: isEnabled, onTap: () => onMonthTap(month),
      ));
    })))));
  }

  DateFormat _shortMonthFormat(String locale) {
    try {
      final DateFormat format = DateFormat.MMM(locale);
      format.format(DateTime(2000));
      return format;
    } catch (_) {
      // intl throws when the app never loaded date data for this locale; English beats a crash.
      return DateFormat.MMM('en');
    }
  }
}

// SUMMARY
// Three-by-four grid of localised month names for the shown year; months wholly outside the date bounds are
// disabled and tapping one opens it in the day view.
