import 'package:flutter/material.dart';

import 'date_time_picker_config.dart';
import 'date_time_picker_result.dart';
import 'presentation/picker_dialog.dart';
import 'presentation/picker_sheet.dart';

/// How [showDateTimePicker] presents the picker.
enum DateTimePickerPresentation {
  /// A dialog on screens 600 logical pixels wide or more, a bottom sheet on narrower ones.
  auto,

  /// Always a bottom sheet.
  sheet,

  /// Always a dialog.
  dialog,
}

/// Opens the picker and returns what the user picked, or null if it was dismissed.
///
/// The picker closes itself when the user confirms, and a [DateTimePickerConfig.validator] can keep it open until
/// the pick is accepted.
Future<DateTimePickerResult?> showDateTimePicker(
  BuildContext context, {
  DateTimePickerConfig config = const DateTimePickerConfig(),
  DateTimePickerPresentation presentation = DateTimePickerPresentation.auto,
}) {
  final bool asDialog = presentation == DateTimePickerPresentation.dialog
      || (presentation == DateTimePickerPresentation.auto && MediaQuery.sizeOf(context).width >= 600);
  if (asDialog) {
    return showDialog<DateTimePickerResult>(context: context, builder: (_) => DateTimePickerDialog(config: config));
  }
  return showModalBottomSheet<DateTimePickerResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DateTimePickerSheet(config: config),
  );
}

// SUMMARY
// Opens the picker as a bottom sheet, a dialog, or whichever suits the screen width, and returns the picked
// result, or null when it is dismissed.
