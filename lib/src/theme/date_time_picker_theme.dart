import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Overrides the picker's colors and corner radii for the whole app.
///
/// Add it to [ThemeData.extensions]. Anything left null falls back to the app's color scheme.
class DateTimePickerThemeData extends ThemeExtension<DateTimePickerThemeData> {
  /// The background of the sheet or dialog. Defaults to [ThemeData.cardColor].
  final Color? surfaceColor;

  /// The color of the selected day, the AM/PM and Confirm buttons. Defaults to [ColorScheme.primary].
  final Color? selectedColor;

  /// The color of text and icons on [selectedColor]. Defaults to [ColorScheme.onPrimary].
  final Color? onSelectedColor;

  /// The band between the start and end day of a range. Defaults to [selectedColor] at 12% strength.
  final Color? rangeColor;

  /// The fill of the day tiles and the time cards. Defaults to the disabled color at 8% strength.
  final Color? sectionColor;

  /// The corner radius of day tiles and the smaller controls. Defaults to 8.
  final double? cellRadius;

  /// The corner radius of the sheet or dialog. Defaults to 20.
  final double? containerRadius;

  /// Creates a theme extension. Every argument is optional.
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
