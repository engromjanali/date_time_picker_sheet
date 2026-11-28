import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'calendar/calendar_view.dart';
import 'controller/date_time_picker_controller.dart';
import 'date_time_picker_config.dart';
import 'date_time_picker_labels.dart';
import 'date_time_picker_result.dart';
import 'picker_style.dart';
import 'theme/date_time_picker_theme.dart';
import 'time/time_picker.dart';
import 'time/time_wheel.dart';

/// The picker without a frame, for embedding in a page or in your own sheet or dialog.
///
/// [DateTimePickerSheet] and [DateTimePickerDialog] wrap this widget. It never closes itself: it calls [onSubmitted]
/// with the result, or [onCancelled], and leaves the closing to you.
class DateTimePicker extends StatefulWidget {
  /// What the picker shows and how it behaves.
  final DateTimePickerConfig config;

  /// Called with the result once the user confirms and the validator, if any, accepts it.
  final ValueChanged<DateTimePickerResult> onSubmitted;

  /// Called when the user taps Cancel.
  final VoidCallback onCancelled;

  /// Creates the picker body.
  const DateTimePicker({super.key, required this.config, required this.onSubmitted, required this.onCancelled});

  /// The width from which the calendar and the times sit side by side instead of stacking.
  static const double wideLayoutWidth = 640;

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late final DateTimePickerController _controller = DateTimePickerController(widget.config)..addListener(_hideSnack);
  // Keeps the browsed month and view when a resize moves the calendar between the stacked and wide layouts.
  final GlobalKey _calendarKey = GlobalKey();
  int _movingWheels = 0;
  bool _isSubmitting = false;
  String? _snack;
  Timer? _snackTimer;

  bool get _canSubmit => _movingWheels == 0 && !_isSubmitting;

  @override
  void dispose() {
    _snackTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // A new pick makes the last message stale.
  void _hideSnack() {
    if (_snack == null) return;
    _snackTimer?.cancel();
    setState(() => _snack = null);
  }

  void _onWheelMoving(bool isMoving) {
    if (!mounted) return;
    setState(() => _movingWheels = max(0, _movingWheels + (isMoving ? 1 : -1)));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    _snackTimer?.cancel();
    setState(() => _snack = message);
    _snackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _snack = null);
    });
  }

  void _confirm() {
    final String? error = _controller.validate();
    if (error != null) {
      _showSnack(error);
      return;
    }
    _submit(_controller.result());
  }

  Future<void> _submit(DateTimePickerResult result) async {
    final DateTimePickerValidator? validator = widget.config.validator;
    if (validator == null) {
      widget.onSubmitted(result);
      return;
    }
    _hideSnack();
    setState(() => _isSubmitting = true);
    String? error;
    try {
      error = await validator(result);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: exception, stack: stack, library: 'date_time_picker_sheet'));
      error = widget.config.labels.validationFailed;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
      return;
    }
    widget.onSubmitted(result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTimePickerLabels labels = widget.config.labels;
    final Color? primaryColor = widget.config.primaryColor;
    final Widget picker = ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.config.isRange ? labels.rangeTitle : labels.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(labels.subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),

          // The snack floats over the bottom of the content, so showing it never shifts the layout.
          Flexible(child: Stack(children: [
            SingleChildScrollView(child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
              final bool isWide = constraints.maxWidth >= DateTimePicker.wideLayoutWidth;
              final Widget calendar = CalendarView(key: _calendarKey, controller: _controller);
              final Widget times = _TimeSection(controller: _controller, isStacked: isWide, onMovingChanged: _onWheelMoving, onRejected: _showSnack);
              if (!isWide) return Column(children: [calendar, const SizedBox(height: 8), times]);
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: calendar),
                const SizedBox(width: 24),
                SizedBox(width: 300, child: times),
              ]);
            })),
            Positioned(left: 0, right: 0, bottom: 4, child: _SnackMessage(message: _snack)),
          ])),
          const SizedBox(height: 12),

          _ActionBar(
            labels: labels, showNowAction: widget.config.showNowAction, isSubmitting: _isSubmitting, canSubmit: _canSubmit,
            onNow: () => _submit(_controller.nowResult()), onCancel: widget.onCancelled, onConfirm: _confirm,
          ),
        ]),
      ),
    );
    if (primaryColor == null) return picker;
    return Theme(data: _withPrimaryColor(theme, primaryColor), child: picker);
  }

  ThemeData _withPrimaryColor(ThemeData theme, Color primaryColor) {
    // Only the selection colours change; every other picker override the app set is kept.
    final DateTimePickerThemeData current = theme.extension<DateTimePickerThemeData>() ?? const DateTimePickerThemeData();
    final bool isDarkColor = ThemeData.estimateBrightnessForColor(primaryColor) == Brightness.dark;
    final DateTimePickerThemeData picker = current.copyWith(
      selectedColor: primaryColor,
      onSelectedColor: current.onSelectedColor ?? (isDarkColor ? Colors.white : Colors.black),
    );
    return theme.copyWith(extensions: [
      ...theme.extensions.values.where((ThemeExtension<dynamic> extension) => extension is! DateTimePickerThemeData),
      picker,
    ]);
  }
}

class _TimeSection extends StatelessWidget {
  final DateTimePickerController controller;
  final bool isStacked;
  final ValueChanged<bool> onMovingChanged;
  final ValueChanged<String> onRejected;
  const _TimeSection({required this.controller, required this.isStacked, required this.onMovingChanged, required this.onRejected});

  @override
  Widget build(BuildContext context) {
    final DateTimePickerConfig config = controller.config;
    final Widget start = _TimeCard(
      label: config.labels.startTime,
      isInline: !config.isRange,
      child: config.startNowOnly
          ? _NowTime(label: config.labels.now, use24HourFormat: _use24HourFormat(context))
          : _ControllerTimePicker(controller: controller, isEnd: false, onMovingChanged: onMovingChanged, onRejected: onRejected),
    );
    if (!config.isRange) return start;

    final Widget end = _TimeCard(
      label: config.labels.endTime,
      isInline: false,
      child: _ControllerTimePicker(controller: controller, isEnd: true, onMovingChanged: onMovingChanged, onRejected: onRejected),
    );
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      // Side by side, each card needs about 150 px at normal text size to fit its wheels and AM/PM.
      final bool isTooNarrow = constraints.maxWidth < MediaQuery.textScalerOf(context).scale(312);
      if (isStacked || isTooNarrow) return Column(children: [start, const SizedBox(height: 12), end]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: start), const SizedBox(width: 12), Expanded(child: end)]);
    });
  }

  bool _use24HourFormat(BuildContext context) => controller.config.use24HourFormat ?? MediaQuery.alwaysUse24HourFormatOf(context);
}

class _ControllerTimePicker extends StatelessWidget {
  final DateTimePickerController controller;
  final bool isEnd;
  final ValueChanged<bool> onMovingChanged;
  final ValueChanged<String> onRejected;
  const _ControllerTimePicker({required this.controller, required this.isEnd, required this.onMovingChanged, required this.onRejected});

  void _onChanged(TimeOfDay time) {
    final bool isAccepted = isEnd ? controller.setEndTime(time) : controller.setStartTime(time);
    if (isAccepted) return;
    final DateTimePickerLabels labels = controller.config.labels;
    onRejected(isEnd ? labels.endNotAfterStart : labels.startInPast);
  }

  @override
  Widget build(BuildContext context) {
    final DateTimePickerConfig config = controller.config;
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return TimePicker(
      value: isEnd ? controller.endTime : controller.startTime,
      minimum: isEnd ? controller.minimumEndTime : controller.minimumStartTime,
      use24HourFormat: config.use24HourFormat ?? MediaQuery.alwaysUse24HourFormatOf(context),
      minuteInterval: config.minuteInterval,
      amLabel: config.labels.am ?? localizations.anteMeridiemAbbreviation,
      pmLabel: config.labels.pm ?? localizations.postMeridiemAbbreviation,
      onChanged: _onChanged,
      onMovingChanged: onMovingChanged,
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final bool isInline;
  final Widget child;
  const _TimeCard({required this.label, required this.isInline, required this.child});

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final TextStyle? labelStyle = Theme.of(context).textTheme.titleSmall;
    // Keeps the wheels a comfortable width when the card is wide.
    final Widget wheels = ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: child);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: style.section, borderRadius: BorderRadius.circular(style.cellRadius + 4)),
      child: isInline
          ? Row(children: [
              // Capped so a long translation wraps instead of squeezing the wheels.
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 110), child: Text(label, maxLines: 2, style: labelStyle)),
              const SizedBox(width: 12),
              Expanded(child: Align(alignment: AlignmentDirectional.centerEnd, child: wheels)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
              const SizedBox(height: 6),
              Center(child: wheels),
            ]),
    );
  }
}

class _NowTime extends StatelessWidget {
  final String label;
  final bool use24HourFormat;
  const _NowTime({required this.label, required this.use24HourFormat});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.now(), alwaysUse24HourFormat: use24HourFormat);
    return SizedBox(
      height: TimeWheel.height,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(time, style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
      ]),
    );
  }
}

class _SnackMessage extends StatelessWidget {
  final String? message;
  const _SnackMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    // Drawn inside the picker: a ScaffoldMessenger snack would land behind the sheet or dialog's barrier.
    final ThemeData theme = Theme.of(context);
    final SnackBarThemeData snackTheme = theme.snackBarTheme;
    final String? text = message;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation), child: child),
      ),
      child: text == null ? const SizedBox.shrink() : Semantics(
        key: ValueKey<String>(text),
        liveRegion: true,
        child: Material(
          color: snackTheme.backgroundColor ?? theme.colorScheme.inverseSurface,
          elevation: snackTheme.elevation ?? 6,
          shape: snackTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(text, style: snackTheme.contentTextStyle ?? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onInverseSurface)),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final DateTimePickerLabels labels;
  final bool showNowAction;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onNow;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ActionBar({
    required this.labels, required this.showNowAction, required this.isSubmitting, required this.canSubmit, required this.onNow,
    required this.onCancel, required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final ButtonStyle textStyle = TextButton.styleFrom(foregroundColor: style.selected);
    final Color nowHovered = style.section.withValues(alpha: (style.section.a * 2.5).clamp(0, 1));
    final ButtonStyle nowStyle = textStyle.copyWith(
      // The time cards' light fill at rest, a deeper shade of it under the pointer or finger.
      backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        final bool isActive = states.contains(WidgetState.hovered) || states.contains(WidgetState.focused) || states.contains(WidgetState.pressed);
        return isActive ? nowHovered : style.section;
      }),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
    );
    return Row(children: [
      // Natural width only; making it flexible split the bar in half and pushed Cancel and Confirm into a stack.
      if (showNowAction) TextButton(style: nowStyle, onPressed: isSubmitting ? null : onNow, child: Text(labels.now)),
      // Stacks Cancel over Confirm when a narrow screen or long translation cannot fit them side by side.
      Expanded(child: OverflowBar(
        alignment: MainAxisAlignment.end,
        overflowAlignment: OverflowBarAlignment.end,
        spacing: 8,
        overflowSpacing: 4,
        children: [
          TextButton(style: textStyle, onPressed: isSubmitting ? null : onCancel, child: Text(labels.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: style.selected, foregroundColor: style.onSelected),
            onPressed: canSubmit ? onConfirm : null,
            child: isSubmitting
                ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: style.disabled))
                : Text(labels.confirm),
          ),
        ],
      )),
    ]);
  }
}

// SUMMARY
// The picker body shared by the sheet and the dialog: title, calendar, start and end time cards, a snack
// for refused times and validation errors, and the now, cancel and confirm actions; it validates the pick,
// runs the caller's validator and hands back the result.
