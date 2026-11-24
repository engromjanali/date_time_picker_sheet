import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class DateTimePickerThemeData extends ThemeExtension<DateTimePickerThemeData> {
  final Color? surfaceColor;
  final Color? selectedColor;
  final Color? onSelectedColor;
  final Color? rangeColor;
  final Color? sectionColor;
  final double? cellRadius;
  final double? containerRadius;

  const DateTimePickerThemeData({
    this.surfaceColor, this.selectedColor, this.onSelectedColor, this.rangeColor, this.sectionColor,
    this.cellRadius, this.containerRadius,
  });

  @override
  DateTimePickerThemeData copyWith({
    Color? surfaceColor, Color? selectedColor, Color? onSelectedColor, Color? rangeColor, Color? sectionColor,
    double? cellRadius, double? containerRadius,
  }) {
    return DateTimePickerThemeData(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      selectedColor: selectedColor ?? this.selectedColor,
      onSelectedColor: onSelectedColor ?? this.onSelectedColor,
      rangeColor: rangeColor ?? this.rangeColor,
      sectionColor: sectionColor ?? this.sectionColor,
      cellRadius: cellRadius ?? this.cellRadius,
      containerRadius: containerRadius ?? this.containerRadius,
    );
  }

  @override
  DateTimePickerThemeData lerp(DateTimePickerThemeData? other, double t) {
    if (other == null) return this;
    return DateTimePickerThemeData(
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t),
      onSelectedColor: Color.lerp(onSelectedColor, other.onSelectedColor, t),
      rangeColor: Color.lerp(rangeColor, other.rangeColor, t),
      sectionColor: Color.lerp(sectionColor, other.sectionColor, t),
      cellRadius: lerpDouble(cellRadius, other.cellRadius, t),
      containerRadius: lerpDouble(containerRadius, other.containerRadius, t),
    );
  }
}

// SUMMARY
// Theme extension apps add to ThemeData to override the picker's colours and corner radii; anything left
// null falls back to the app's colour scheme.
