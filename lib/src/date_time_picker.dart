import 'dart:math';

import 'package:flutter/material.dart';

import 'calendar/calendar_view.dart';
import 'controller/date_time_picker_controller.dart';
import 'date_time_picker_config.dart';
import 'date_time_picker_labels.dart';
import 'date_time_picker_result.dart';
import 'picker_style.dart';
import 'time/time_picker.dart';
import 'time/time_wheel.dart';

class DateTimePicker extends StatefulWidget {
  final DateTimePickerConfig config;
  final ValueChanged<DateTimePickerResult> onSubmitted;
  final VoidCallback onCancelled;
  const DateTimePicker({super.key, required this.config, required this.onSubmitted, required this.onCancelled});

  // Below this width the calendar and the times stack instead of sitting side by side.
  static const double wideLayoutWidth = 640;

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  late final DateTimePickerController _controller = DateTimePickerController(widget.config)..addListener(_clearError);
  // Keeps the browsed month and view when a resize moves the calendar between the stacked and wide layouts.
  final GlobalKey _calendarKey = GlobalKey();
  int _movingWheels = 0;
  bool _isSubmitting = false;
  String? _error;

  bool get _canSubmit => _movingWheels == 0 && !_isSubmitting;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _onWheelMoving(bool isMoving) {
    if (!mounted) return;
    setState(() => _movingWheels = max(0, _movingWheels + (isMoving ? 1 : -1)));
  }

  void _confirm() {
    final String? error = _controller.validate();
    if (error != null) {
      setState(() => _error = error);
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
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
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
      setState(() => _error = error);
      return;
    }
    widget.onSubmitted(result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTimePickerLabels labels = widget.config.labels;
    return ListenableBuilder(
      listenable: _controller,
      builder: (BuildContext context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.config.isRange ? labels.rangeTitle : labels.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(labels.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          Flexible(child: SingleChildScrollView(child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWide = constraints.maxWidth >= DateTimePicker.wideLayoutWidth;
            final Widget calendar = CalendarView(key: _calendarKey, controller: _controller);
            final Widget times = _TimeSection(controller: _controller, isStacked: isWide, onMovingChanged: _onWheelMoving);
            if (!isWide) return Column(children: [calendar, const SizedBox(height: 12), times]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: calendar),
              const SizedBox(width: 24),
              SizedBox(width: 300, child: times),
            ]);
          }))),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(liveRegion: true, child: Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))),
            ),
          const SizedBox(height: 16),

          _ActionBar(
            labels: labels, showNowAction: widget.config.showNowAction, isSubmitting: _isSubmitting, canSubmit: _canSubmit,
            onNow: () => _submit(_controller.nowResult()), onCancel: widget.onCancelled, onConfirm: _confirm,
          ),
        ]),
      ),
    );
  }
}

class _TimeSection extends StatelessWidget {
  final DateTimePickerController controller;
  final bool isStacked;
  final ValueChanged<bool> onMovingChanged;
  const _TimeSection({required this.controller, required this.isStacked, required this.onMovingChanged});

  @override
  Widget build(BuildContext context) {
    final DateTimePickerConfig config = controller.config;
    final Widget start = _TimeCard(
      label: config.labels.startTime,
      child: config.startNowOnly
          ? _NowTime(label: config.labels.now, use24HourFormat: _use24HourFormat(context))
          : _ControllerTimePicker(controller: controller, isEnd: false, onMovingChanged: onMovingChanged),
    );
    if (!config.isRange) return start;

    final Widget end = _TimeCard(
      label: config.labels.endTime,
      child: _ControllerTimePicker(controller: controller, isEnd: true, onMovingChanged: onMovingChanged),
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
  const _ControllerTimePicker({required this.controller, required this.isEnd, required this.onMovingChanged});

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
      onChanged: isEnd ? controller.setEndTime : controller.setStartTime,
      onMovingChanged: onMovingChanged,
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _TimeCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: style.section, borderRadius: BorderRadius.circular(style.cellRadius + 4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        // Keeps the wheels a comfortable width when the card is wide.
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 320), child: child)),
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
    return Row(children: [
      if (showNowAction) Flexible(child: TextButton(style: textStyle, onPressed: isSubmitting ? null : onNow, child: Text(labels.now))),
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
// The picker body shared by the sheet and the dialog: title, calendar, start and end time cards, inline
// error and the now, cancel and confirm actions; it validates the pick, runs the caller's validator and
// hands back the result.
