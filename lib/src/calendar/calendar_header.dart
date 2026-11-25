import 'package:flutter/material.dart';

import '../picker_style.dart';

class CalendarHeader extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final bool showArrows;
  final String previousTooltip;
  final String nextTooltip;
  final VoidCallback onTitleTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const CalendarHeader({super.key,
    required this.title, required this.isExpanded, required this.showArrows, required this.previousTooltip, required this.nextTooltip,
    required this.onTitleTap, required this.onPrevious, required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    return SizedBox(
      height: 40,
      child: Row(children: [
        // The title takes all the room the arrows leave, so the arrows always sit at the end.
        Expanded(child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: InkWell(
            onTap: onTitleTap,
            borderRadius: BorderRadius.circular(style.cellRadius),
            overlayColor: style.overlay,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                // Shown in full when it fits, shrunk rather than cut when the header is narrow.
                Flexible(child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(title, maxLines: 1, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 4),
                AnimatedRotation(turns: isExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.arrow_drop_down)),
              ]),
            ),
          ),
        )),

        if (showArrows) ...[
          IconButton(tooltip: previousTooltip, onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
          IconButton(tooltip: nextTooltip, onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ],
      ]),
    );
  }
}

// SUMMARY
// Calendar header: a tappable month-or-year title that switches between the day, month and year views, and
// previous and next arrows that disable at the date bounds.
