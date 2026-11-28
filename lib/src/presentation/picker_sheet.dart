import 'package:flutter/material.dart';

import '../date_time_picker.dart';
import '../date_time_picker_config.dart';
import '../picker_style.dart';

/// The picker inside a bottom sheet frame.
///
/// Use it when you show the picker with your own route, for example `showModalBottomSheet` (with
/// `isScrollControlled: true` and a transparent background) or a navigation package. Pops with the
/// [DateTimePickerResult] when the user confirms, and with nothing on cancel.
class DateTimePickerSheet extends StatelessWidget {
  /// What the picker shows and how it behaves.
  final DateTimePickerConfig config;

  /// Creates the sheet.
  const DateTimePickerSheet({super.key, this.config = const DateTimePickerConfig()});

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Material(
        color: style.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(style.containerRadius))),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(color: style.disabled.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
            ),
            Flexible(child: DateTimePicker(
              config: config,
              onSubmitted: (result) => Navigator.of(context).pop(result),
              onCancelled: () => Navigator.of(context).pop(),
            )),
          ])),
        ),
      ),
    );
  }
}

// SUMMARY
// Bottom-sheet frame for the picker: rounded top, drag handle, safe area and keyboard insets, capped at 90%
// of the screen height, closing with the result or nothing on cancel.
