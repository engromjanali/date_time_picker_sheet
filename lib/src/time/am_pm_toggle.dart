import 'package:flutter/material.dart';

import '../picker_style.dart';

class AmPmToggle extends StatelessWidget {
  final bool isPm;
  final bool isAmEnabled;
  final String amLabel;
  final String pmLabel;
  final ValueChanged<bool> onChanged;
  const AmPmToggle({super.key, required this.isPm, required this.isAmEnabled, required this.amLabel, required this.pmLabel, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: style.surface, borderRadius: BorderRadius.circular(style.cellRadius)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // A greyed AM stays tappable so the picker can explain why it is refused.
        _Segment(label: amLabel, isSelected: !isPm, isEnabled: isAmEnabled, onTap: () => onChanged(false)),
        _Segment(label: pmLabel, isSelected: isPm, isEnabled: true, onTap: () => onChanged(true)),
      ]),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  const _Segment({required this.label, required this.isSelected, required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final BorderRadius radius = BorderRadius.circular(style.cellRadius);
    return Material(
      type: MaterialType.transparency,
      child: MergeSemantics(child: Semantics(
        selected: isSelected, button: true,
        child: InkWell(
          onTap: !isSelected ? onTap : null,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          overlayColor: style.overlay,
          child: Ink(
            width: 48, height: 44,
            decoration: BoxDecoration(color: isSelected ? style.selected : null, borderRadius: radius),
            child: Center(child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected ? style.onSelected : isEnabled ? style.disabled : style.disabled.withValues(alpha: 0.4),
            ))),
          ),
        ),
      )),
    );
  }
}

// SUMMARY
// Vertical AM and PM switch with rounded hover, focus and press feedback; AM is greyed when the earliest
// allowed time is already in the afternoon but still reports taps, so the picker can say why it is refused.
