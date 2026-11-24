import 'package:flutter/material.dart';

import 'theme/date_time_picker_theme.dart';

class PickerStyle {
  final Color surface;
  final Color selected;
  final Color onSelected;
  final Color range;
  final Color section;
  final Color disabled;
  final double cellRadius;
  final double containerRadius;

  const PickerStyle._({
    required this.surface, required this.selected, required this.onSelected, required this.range, required this.section,
    required this.disabled, required this.cellRadius, required this.containerRadius,
  });

  factory PickerStyle.of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTimePickerThemeData? custom = theme.extension<DateTimePickerThemeData>();
    final Color selected = custom?.selectedColor ?? theme.colorScheme.primary;
    return PickerStyle._(
      surface: custom?.surfaceColor ?? theme.cardColor,
      selected: selected,
      onSelected: custom?.onSelectedColor ?? theme.colorScheme.onPrimary,
      range: custom?.rangeColor ?? selected.withValues(alpha: 0.12),
      section: custom?.sectionColor ?? theme.disabledColor.withValues(alpha: 0.08),
      disabled: theme.disabledColor,
      cellRadius: custom?.cellRadius ?? 8,
      containerRadius: custom?.containerRadius ?? 20,
    );
  }

  WidgetStateProperty<Color?> get overlay => WidgetStateProperty.resolveWith((Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) return selected.withValues(alpha: 0.16);
    if (states.contains(WidgetState.focused)) return selected.withValues(alpha: 0.14);
    if (states.contains(WidgetState.hovered)) return selected.withValues(alpha: 0.08);
    return null;
  });
}

// SUMMARY
// The picker's resolved colours and radii, taken from the app's DateTimePickerThemeData where set and the
// colour scheme otherwise, plus the shared hover, focus and press overlay.
