import 'dart:math';

import 'package:flutter/material.dart';

import '../controller/date_time_picker_controller.dart';
import 'selectable_tile.dart';

class YearGrid extends StatefulWidget {
  final int selectedYear;
  final DateTimePickerController controller;
  final ValueChanged<int> onYearTap;
  const YearGrid({super.key, required this.selectedYear, required this.controller, required this.onYearTap});

  @override
  State<YearGrid> createState() => _YearGridState();
}

class _YearGridState extends State<YearGrid> {
  static const int _columns = 3;
  static const double _rowExtent = 56;

  // Opens with the selected year's row in view, two rows down from the top.
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: max(0, ((widget.selectedYear - widget.controller.firstDay.year) ~/ _columns - 2) * _rowExtent),
  );

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final int firstYear = widget.controller.firstDay.year;
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _columns, mainAxisExtent: _rowExtent),
      itemCount: widget.controller.lastDay.year - firstYear + 1,
      itemBuilder: (BuildContext context, int index) {
        final int year = firstYear + index;
        final String label = localizations.formatYear(DateTime(year));
        return SelectableTile(
          label: label, semanticsLabel: label, isSelected: year == widget.selectedYear, isEnabled: true,
          onTap: () => widget.onYearTap(year),
        );
      },
    );
  }
}

// SUMMARY
// Scrollable grid of the years inside the date bounds, opened with the selected year in view; tapping a year
// moves the calendar to it.
