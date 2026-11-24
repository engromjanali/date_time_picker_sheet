# date_time_picker_sheet

A date and time picker that opens as a **bottom sheet** or a **dialog**. It has:

- A calendar with **day, month and year views**. Tap the title to switch views.
- **Scroll-wheel time** input that works with touch, mouse, trackpad and keyboard.
- **Single** or **range** selection.
- Built-in rules: date bounds, "start now", "today only", and minute steps.
- An optional **async validator** whose error is shown inside the picker.

It uses only Flutter and `intl`, with no other dependencies.

## Install

```yaml
dependencies:
  date_time_picker_sheet:
    path: ../date_time_picker_sheet
```

## Usage

```dart
import 'package:date_time_picker_sheet/date_time_picker_sheet.dart';

final DateTimePickerResult? result = await showDateTimePicker(
  context,
  presentation: DateTimePickerPresentation.auto, // sheet | dialog | auto
  config: const DateTimePickerConfig(),
);
if (result != null) print(result.start);
```

A range with server-side validation:

```dart
final DateTimePickerResult? trip = await showDateTimePicker(
  context,
  config: DateTimePickerConfig(
    mode: DateTimePickerMode.range,
    initialStart: savedStart,
    initialEnd: savedEnd,
    startNowOnly: !provider.takesScheduledTrips,
    minuteInterval: 5,
    validator: (DateTimePickerResult picked) async {
      final bool free = await api.isAvailable(picked.start, picked.end!);
      return free ? null : 'This vehicle is booked for that time';
    },
    labels: DateTimePickerLabels(
      rangeTitle: 'select_start_and_return_date_and_time'.tr,
      confirm: 'confirm'.tr,
      cancel: 'cancel'.tr,
    ),
  ),
);
```

`showDateTimePicker` returns `null` when the picker is dismissed. With a validator, the picker closes only when the validator returns `null`.

### Your own route or GetX

The frames are plain widgets, so you can show them however you like:

```dart
final result = await Get.bottomSheet<DateTimePickerResult>(
  const DateTimePickerSheet(config: DateTimePickerConfig()),
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
);
final result = await Get.dialog<DateTimePickerResult>(const DateTimePickerDialog());
```

`DateTimePicker(config:, onSubmitted:, onCancelled:)` is the frameless body, for embedding the picker in a page.

## Config

| Field | Default | Meaning |
|---|---|---|
| `mode` | `single` | `single` picks one moment; `range` picks a start and an end. |
| `initialStart` / `initialEnd` | earliest slot / start + 1 h | Where the picker opens. Values outside the bounds fall back to the earliest slot. |
| `firstDate` | now | Earliest allowed start. When set, it takes priority over `allowPast`. |
| `allowPast` | `false` | Allows past days and times, back 100 years. The picker still opens on the current time. Cannot be combined with `startNowOnly`. |
| `lastDate` | 31 Dec, 5 years ahead | Latest selectable day. Only the date counts; its time of day is ignored. |
| `startNowOnly` | `false` | Range only. The start is fixed to now and only the end is picked. |
| `todayOnly` | `false` | Only today can be picked. |
| `use24HourFormat` | device setting | Forces 12- or 24-hour wheels. |
| `minuteInterval` | `1` | Minute step. Must divide 60. |
| `showNowAction` | `false` | Single only. Adds a "Now" button that returns `isNow: true`. |
| `validator` | none | `FutureOr<String?>`. Return a message to keep the picker open. |
| `labels` | English | Every visible string, including validation messages. AM/PM default to `MaterialLocalizations`. |

`DateTimePickerResult` holds `start`, `end` (range only) and `isNow`.

## Theming

Colors come from the app theme: `colorScheme.primary` for selection, `cardColor` for the surface. To override them, add the extension to your theme:

```dart
ThemeData(
  extensions: const [
    DateTimePickerThemeData(selectedColor: Color(0xFF039D55), cellRadius: 10, containerRadius: 24),
  ],
)
```

Month names are formatted with `intl`. Apps that use `flutter_localizations` get them in their own locale automatically.

## Behaviour notes

- Times before the earliest allowed slot are greyed out. If a wheel lands on one, it moves forward to the first allowed time.
- In a range, the end is always kept at least one minute step after the start.
- Confirm is disabled while a wheel is still moving, so a half-finished scroll is never submitted.
- RTL, dark theme, text scaling and screen readers are supported. Day cells announce their full date, and the wheels can be adjusted by screen readers and arrow keys.

## Development

```bash
flutter analyze
flutter test                              # unit, widget and golden tests
flutter test --update-goldens test/golden_test.dart
cd example && flutter run -d chrome      # gallery with every option
```
