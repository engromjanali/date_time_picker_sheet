## 0.1.0

Breaking: the 0.0.1 `DateTimePickerSheet(onConfirm: ...)` API is replaced.

* Shown as a bottom sheet, a dialog, or `auto` (dialog on screens 600px and wider) through `showDateTimePicker`. The picker returns its result when it closes.
* Own calendar replaces `syncfusion_flutter_datepicker`, so no commercial licence is needed. It has day, month and year views, a continuous range band, a range preview on hover, and arrows and swipe kept inside the date bounds.
* Time wheels rebuilt on `ListWheelScrollView`. They work with touch, mouse drag, mouse wheel, trackpad and arrow keys. A wheel stopped between rows snaps back to one, which fixes the confirm button getting stuck disabled on web.
* 12- or 24-hour time (following the device setting by default), minute steps, and times before the earliest allowed slot shown disabled.
* Picking a blocked time, by wheel or greyed AM, keeps the previous time and shows a snackbar inside the picker. The message is `startInPast` ("You can't select a past time.") for the start and `endNotAfterStart` for the end. Validation and validator errors use the same snackbar.
* A range that opens on a single day takes the first tap on a later day as its end, keeping the start.
* Compact layout. Every day, past or upcoming, sits on a rounded tile. In single mode the start-time label sits beside the wheels.
* `firstDate` and `lastDate` bounds, plus `allowPast`, `startNowOnly`, `todayOnly` and an optional "Now" action.
* The calendar header always keeps its arrows at the end. The month title shows in full and scales down rather than being cut on narrow screens.
* Cancel and Confirm stack instead of overflowing on very narrow screens or with long translations.
* Async `validator`: an error shows as a snackbar and keeps the picker open, and a loader shows while it runs.
* `DateTimePickerThemeData` theme extension, with RTL, dark theme, semantics labels and large text supported.
* `DateTimePickerConfig.primaryColor` sets the selection color for a single picker, with readable text on it.

## 0.0.1

* First version, taken from the 6amMart User App rental date and time picker.
