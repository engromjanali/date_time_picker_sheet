import 'package:flutter/material.dart';

import '../controller/date_time_picker_controller.dart';
import 'calendar_header.dart';
import 'day_grid.dart';
import 'month_grid.dart';
import 'year_grid.dart';

enum _CalendarMode { day, month, year }

class CalendarView extends StatefulWidget {
  final DateTimePickerController controller;
  const CalendarView({super.key, required this.controller});

  static const double gridHeight = DayGrid.weekdayHeight + DayGrid.rowHeight * 6;

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _visibleMonth = _monthOf(widget.controller.focusedDay);
  _CalendarMode _mode = _CalendarMode.day;

  DateTimePickerController get _controller => widget.controller;

  DateTime _monthOf(DateTime day) => DateTime(day.year, day.month);

  bool get _canGoBack => switch (_mode) {
    _CalendarMode.day => _visibleMonth.isAfter(_monthOf(_controller.firstDay)),
    _CalendarMode.month => _visibleMonth.year > _controller.firstDay.year,
    _CalendarMode.year => false,
  };

  bool get _canGoForward => switch (_mode) {
    _CalendarMode.day => _visibleMonth.isBefore(_monthOf(_controller.lastDay)),
    _CalendarMode.month => _visibleMonth.year < _controller.lastDay.year,
    _CalendarMode.year => false,
  };

  void _step(int direction) {
    setState(() {
      _visibleMonth = _mode == _CalendarMode.day
          ? DateUtils.addMonthsToMonthDate(_visibleMonth, direction)
          : DateTime(_visibleMonth.year + direction, _visibleMonth.month);
    });
  }

  void _onSwipe(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200) return;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final int direction = (velocity < 0) != isRtl ? 1 : -1;
    if (direction == 1 ? _canGoForward : _canGoBack) _step(direction);
  }

  void _onTitleTap() {
    setState(() => _mode = _mode == _CalendarMode.month ? _CalendarMode.year : _CalendarMode.month);
  }

  void _pickYear(int year) {
    final DateTime first = _monthOf(_controller.firstDay);
    final DateTime last = _monthOf(_controller.lastDay);
    final DateTime month = DateTime(year, _visibleMonth.month);
    setState(() {
      _visibleMonth = month.isBefore(first) ? first : month.isAfter(last) ? last : month;
      _mode = _CalendarMode.month;
    });
  }

  void _pickMonth(int month) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, month);
      _mode = _CalendarMode.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final bool isDayMode = _mode == _CalendarMode.day;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      CalendarHeader(
        title: isDayMode ? localizations.formatMonthYear(_visibleMonth) : localizations.formatYear(_visibleMonth),
        isExpanded: !isDayMode,
        showArrows: _mode != _CalendarMode.year,
        previousTooltip: isDayMode ? localizations.previousMonthTooltip : _controller.config.labels.previousYear,
        nextTooltip: isDayMode ? localizations.nextMonthTooltip : _controller.config.labels.nextYear,
        onTitleTap: _onTitleTap,
        onPrevious: _canGoBack ? () => _step(-1) : null,
        onNext: _canGoForward ? () => _step(1) : null,
      ),

      SizedBox(
        height: CalendarView.gridHeight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: switch (_mode) {
            _CalendarMode.day => GestureDetector(
              key: ValueKey<DateTime>(_visibleMonth),
              onHorizontalDragEnd: _onSwipe,
              child: DayGrid(month: _visibleMonth, controller: _controller),
            ),
            _CalendarMode.month => MonthGrid(
              key: ValueKey<String>('month-${_visibleMonth.year}'), visibleMonth: _visibleMonth, controller: _controller, onMonthTap: _pickMonth,
            ),
            _CalendarMode.year => YearGrid(key: const ValueKey<String>('year'), selectedYear: _visibleMonth.year, controller: _controller, onYearTap: _pickYear),
          },
        ),
      ),
    ]);
  }
}

// SUMMARY
// Calendar with three views — days of a month, months of a year and a list of years — switched from the
// header title, with arrow and swipe navigation kept inside the date bounds.
