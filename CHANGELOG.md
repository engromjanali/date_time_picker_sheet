## 0.1.0

First public release.

* A date and time picker shown as a bottom sheet, a dialog, or `auto` (a dialog on screens 600 logical pixels wide or more) through `showDateTimePicker`. The picker returns its result when it closes.
* Single mode, and range mode with a continuous band between the start and end day, a preview under the mouse, and a start and an end time.
* A calendar with day, month and year views, switched from the title. Arrows and swipes stop at the date limits.
* Time wheels that work with touch, mouse drag, mouse wheel, trackpad and arrow keys. 12- or 24-hour time (following the device setting by default) and a configurable minute step.
* `firstDate` and `lastDate` limits, plus `allowPast`, `startNowOnly`, `todayOnly` and an optional "Now" action.
* A refused time, picked by wheel or by a greyed AM, keeps the previous time and shows a snackbar inside the picker. The messages are `startInPast` ("You can't select a past time.") and `endNotAfterStart`.
* An async `validator` that can reject a pick with a message while the confirm button shows a loader.
* `DateTimePickerLabels` for every visible string, `DateTimePickerConfig.primaryColor` for a single picker, and the `DateTimePickerThemeData` theme extension for app-wide colors and radii.
* Right to left, dark theme, large text and screen-reader labels.
* `DateTimePickerSheet`, `DateTimePickerDialog` and `DateTimePicker` for showing the picker with your own route or inside a page.
