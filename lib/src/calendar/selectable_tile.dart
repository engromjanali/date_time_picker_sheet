import 'package:flutter/material.dart';

import '../picker_style.dart';

class SelectableTile extends StatelessWidget {
  final String label;
  final String semanticsLabel;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  const SelectableTile({super.key, required this.label, required this.semanticsLabel, required this.isSelected, required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final TextStyle text = Theme.of(context).textTheme.bodyLarge!;
    final BorderRadius radius = BorderRadius.circular(style.cellRadius);
    return Padding(
      padding: const EdgeInsets.all(4),
      // Its own Material so ink is painted above the picker surface, not under it.
      child: Material(
        type: MaterialType.transparency,
        child: MergeSemantics(child: Semantics(
          label: semanticsLabel, selected: isSelected, button: true,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            customBorder: RoundedRectangleBorder(borderRadius: radius),
            overlayColor: style.overlay,
            child: Ink(
              decoration: BoxDecoration(color: isSelected ? style.selected : null, borderRadius: radius),
              child: Center(child: ExcludeSemantics(child: Text(label, style: text.copyWith(
                color: isSelected ? style.onSelected : isEnabled ? null : style.disabled,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              )))),
            ),
          ),
        )),
      ),
    );
  }
}

// SUMMARY
// Rounded, tappable month or year tile with hover, focus and press feedback, a filled selected look and a
// greyed disabled look, announced to screen readers with its full label.
