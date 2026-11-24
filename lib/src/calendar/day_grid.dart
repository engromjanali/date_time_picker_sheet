import 'package:flutter/material.dart';

import '../controller/date_time_picker_controller.dart';
import '../picker_style.dart';

class DayGrid extends StatefulWidget {
  final DateTime month;
  final DateTimePickerController controller;
  const DayGrid({super.key, required this.month, required this.controller});

  static const double weekdayHeight = 32;
  static const double rowHeight = 44;

  @override
  State<DayGrid> createState() => _DayGridState();
}

class _DayGridState extends State<DayGrid> {
  DateTime? _hoveredDay;

  void _onHover(DateTime day, bool isHovering) {
    // Tracked even when no preview shows, so a fresh start tapped under the pointer never reuses an old hover.
    _hoveredDay = isHovering ? day : (_hoveredDay == day ? null : _hoveredDay);
    if (widget.controller.awaitingEnd) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final DateTimePickerController controller = widget.controller;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final int firstWeekday = localizations.firstDayOfWeekIndex;
    final DateTime month = widget.month;
    // DateTime counts Monday as 1 and Sunday as 7; the localisation counts Sunday as 0.
    final int leading = (DateTime(month.year, month.month).weekday % 7 - firstWeekday) % 7;
    final int daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    final DateTime bandStart = controller.rangeStartDay;
    final DateTime? hovered = _hoveredDay;
    final DateTime? bandEnd = !controller.config.isRange ? null
        : controller.awaitingEnd ? (hovered != null && hovered.isAfter(bandStart) ? hovered : null) : controller.endDate;
    final bool hasBand = bandEnd != null && bandEnd.isAfter(bandStart);

    return Column(children: [
      SizedBox(height: DayGrid.weekdayHeight, child: Row(children: List.generate(7, (int column) => Expanded(child: Center(
        child: ExcludeSemantics(child: Text(
          localizations.narrowWeekdays[(firstWeekday + column) % 7],
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).disabledColor),
        )),
      ))))),

      for (int row = 0; row < 6; row++)
        SizedBox(height: DayGrid.rowHeight, child: Row(children: List.generate(7, (int column) {
          final int day = row * 7 + column - leading + 1;
          if (day < 1 || day > daysInMonth) return const Expanded(child: SizedBox());
          final DateTime date = DateTime(month.year, month.month, day);
          final bool isBandStart = DateUtils.isSameDay(date, bandStart);
          final bool isBandEnd = hasBand && DateUtils.isSameDay(date, bandEnd);
          final bool isInside = hasBand && date.isAfter(bandStart) && date.isBefore(bandEnd);
          final bool isSelected = controller.config.isRange
              ? isBandStart || (!controller.awaitingEnd && DateUtils.isSameDay(date, controller.endDate))
              : DateUtils.isSameDay(date, controller.startDate);
          return Expanded(child: _DayCell(
            date: date, isSelected: isSelected, isToday: DateUtils.isSameDay(date, controller.today),
            isEnabled: controller.isSelectable(date), bandBefore: isInside || isBandEnd, bandAfter: isInside || (hasBand && isBandStart),
            onTap: () => controller.selectDay(date), onHover: (bool isHovering) => _onHover(date, isHovering),
          ));
        }))),
    ]);
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final bool bandBefore;
  final bool bandAfter;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;

  const _DayCell({
    required this.date, required this.isSelected, required this.isToday, required this.isEnabled, required this.bandBefore,
    required this.bandAfter, required this.onTap, required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final TextStyle text = Theme.of(context).textTheme.bodyMedium!;
    final BorderRadius radius = BorderRadius.circular(style.cellRadius);
    final Color? textColor = isSelected ? style.onSelected : !isEnabled ? style.disabled : isToday ? style.selected : null;

    return Stack(children: [
      // A Row follows the text direction, so the first half always faces the previous day.
      Positioned.fill(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: ColoredBox(color: bandBefore ? style.range : Colors.transparent)),
          Expanded(child: ColoredBox(color: bandAfter ? style.range : Colors.transparent)),
        ]),
      )),
      Padding(
        padding: const EdgeInsets.all(2),
        // Its own Material so the selected fill and the hover ink sit above the range band.
        child: Material(
          type: MaterialType.transparency,
          child: MergeSemantics(child: Semantics(
            label: localizations.formatFullDate(date), selected: isSelected, button: true,
            child: InkWell(
              onTap: isEnabled ? onTap : null,
              onHover: isEnabled ? onHover : null,
              customBorder: RoundedRectangleBorder(borderRadius: radius),
              overlayColor: style.overlay,
              child: Ink(
                decoration: BoxDecoration(
                  color: isSelected ? style.selected : null,
                  border: isToday && !isSelected ? Border.all(color: style.selected) : null,
                  borderRadius: radius,
                ),
                child: Center(child: ExcludeSemantics(child: Text(localizations.formatDecimal(date.day), style: text.copyWith(
                  color: textColor,
                  fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                )))),
              ),
            ),
          )),
        ),
      ),
    ]);
  }
}

// SUMMARY
// Month grid of days with localised weekday headings: marks today, the selection and disabled days, draws
// the range band between start and end, and previews the band under the mouse while an end is being picked.
