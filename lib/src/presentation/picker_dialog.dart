import 'package:flutter/material.dart';

import '../date_time_picker.dart';
import '../date_time_picker_config.dart';
import '../picker_style.dart';

/// The picker inside a dialog frame.
///
/// Use it when you show the picker with your own route, for example `showDialog` or a navigation package. Pops with
/// the [DateTimePickerResult] when the user confirms, and with nothing on cancel.
class DateTimePickerDialog extends StatelessWidget {
  /// What the picker shows and how it behaves.
  final DateTimePickerConfig config;

  /// Creates the dialog.
  const DateTimePickerDialog({super.key, this.config = const DateTimePickerConfig()});

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    return Dialog(
      backgroundColor: style.surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(style.containerRadius)),
      child: ConstrainedBox(
        // A range is wide enough to put the calendar and both times side by side.
        constraints: BoxConstraints(maxWidth: config.isRange ? 760 : 420),
        child: DateTimePicker(
          config: config,
          onSubmitted: (result) => Navigator.of(context).pop(result),
          onCancelled: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// SUMMARY
// Dialog frame for the picker: rounded, width-capped (wider for a range so the times sit beside the
// calendar), closing with the result or nothing on cancel or Escape.
