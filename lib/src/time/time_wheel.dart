import 'dart:ui' show FontFeature, PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';

import '../picker_style.dart';

class TimeWheel extends StatefulWidget {
  final int itemCount;
  final int selectedIndex;
  final String Function(int index) labelOf;
  final bool Function(int index) isDisabled;
  final String semanticsLabel;
  final ValueChanged<int> onSelected;
  final ValueChanged<bool> onMovingChanged;

  const TimeWheel({super.key,
    required this.itemCount, required this.selectedIndex, required this.labelOf, required this.isDisabled, required this.semanticsLabel,
    required this.onSelected, required this.onMovingChanged,
  });

  static const double itemExtent = 36;
  // Exactly three rows: the picked value with one neighbour above and below.
  static const double height = itemExtent * 3;

  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  late final FixedExtentScrollController _controller = FixedExtentScrollController(initialItem: widget.selectedIndex);
  bool _isMoving = false;
  // True while the wheel animates to its parent's value; such a move must never be committed back.
  bool _isFollowingParent = false;
  bool _isFocused = false;

  int get _currentIndex => _controller.selectedItem % widget.itemCount;

  @override
  void didUpdateWidget(TimeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMoving && _controller.hasClients && widget.selectedIndex != _currentIndex) {
      // Starting a scroll sends notifications, which must not reach the parent while it builds.
      WidgetsBinding.instance.addPostFrameCallback((_) => _moveTo(widget.selectedIndex));
    }
  }

  @override
  void dispose() {
    if (_isMoving) {
      final ValueChanged<bool> onMovingChanged = widget.onMovingChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) => onMovingChanged(false));
    }
    _controller.dispose();
    super.dispose();
  }

  void _moveTo(int index) {
    if (!mounted || !_controller.hasClients || _isMoving) return;
    final int item = _controller.selectedItem;
    int delta = index - item % widget.itemCount;
    if (delta == 0) return;
    // The wheel loops, so take the shorter way round.
    if (delta > widget.itemCount / 2) delta -= widget.itemCount;
    if (delta < -widget.itemCount / 2) delta += widget.itemCount;
    _isFollowingParent = true;
    _controller.animateToItem(item + delta, duration: const Duration(milliseconds: 200), curve: Curves.easeOutCubic);
  }

  void _step(int delta) {
    if (!_controller.hasClients) return;
    _controller.animateToItem(_controller.selectedItem + delta, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
  }

  void _setMoving(bool isMoving) {
    if (_isMoving == isMoving) return;
    _isMoving = isMoving;
    widget.onMovingChanged(isMoving);
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification) _setMoving(true);
    // A drag or mouse wheel takes over from a follow animation, so what it lands on is the user's choice.
    if (notification is UserScrollNotification && notification.direction != ScrollDirection.idle) _isFollowingParent = false;
    if (notification is ScrollEndNotification) _settle();
    return false;
  }

  void _settle() {
    final int item = _controller.selectedItem;
    // A mouse wheel or trackpad can stop between rows; snap first and commit on the next settle.
    if ((_controller.offset - item * TimeWheel.itemExtent).abs() > 0.5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.animateToItem(item, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
      });
      return;
    }
    _setMoving(false);
    if (_currentIndex == widget.selectedIndex) {
      _isFollowingParent = false;
      return;
    }
    if (_isFollowingParent) {
      // The parent changed its value again during the follow animation; chase it instead of overwriting it.
      _isFollowingParent = false;
      _moveTo(widget.selectedIndex);
      return;
    }
    widget.onSelected(_currentIndex);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _step(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _step(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final PickerStyle style = PickerStyle.of(context);
    final TextStyle text = Theme.of(context).textTheme.titleMedium!.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final int count = widget.itemCount;
    final int selected = widget.selectedIndex;

    return Semantics(
      label: widget.semanticsLabel,
      value: widget.labelOf(selected),
      increasedValue: widget.labelOf((selected + 1) % count),
      decreasedValue: widget.labelOf((selected - 1 + count) % count),
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: Focus(
        onFocusChange: (bool isFocused) => setState(() => _isFocused = isFocused),
        onKeyEvent: _onKey,
        child: ExcludeSemantics(child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: _isFocused ? style.selected : Colors.transparent, width: 1.5),
            borderRadius: BorderRadius.circular(style.cellRadius),
          ),
          child: SizedBox(
            height: TimeWheel.height,
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: ScrollConfiguration(
                behavior: const _WheelScrollBehavior(),
                child: ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: TimeWheel.itemExtent,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 1.5,
                  overAndUnderCenterOpacity: 0.5,
                  useMagnifier: true,
                  magnification: 1.1,
                  childDelegate: ListWheelChildLoopingListDelegate(children: List.generate(count, (int index) => Center(
                    child: Text(widget.labelOf(index), style: text.copyWith(color: widget.isDisabled(index) ? style.disabled : null)),
                  ))),
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }
}

// Lets a mouse drag the wheel on web and desktop, where only touch drags by default.
class _WheelScrollBehavior extends MaterialScrollBehavior {
  const _WheelScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

// SUMMARY
// Looping scroll wheel of time values that commits a value only once it settles on a row — after touch,
// mouse drag, mouse wheel, trackpad or arrow keys — reports while it moves, and follows its parent's value.
