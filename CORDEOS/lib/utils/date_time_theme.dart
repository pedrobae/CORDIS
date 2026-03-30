import 'package:flutter/material.dart';

class DateTimePickerTheme {
  static DatePickerThemeData datePickerTheme(BuildContext context) {
    return DatePickerThemeData(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: ContinuousRectangleBorder(),
    );
  }

  static TimePickerThemeData timePickerTheme(BuildContext context) {
    return TimePickerThemeData(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: ContinuousRectangleBorder(),
    );
  }
}
