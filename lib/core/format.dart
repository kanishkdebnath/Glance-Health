/// Display formatting.
// ponytail: English only. Swap these for intl's NumberFormat and DateFormat
// when localisation lands; every screen already goes through this file.
library;

String thousands(num n) => n.round().toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// ("7", "h"), ("18", "m") for use with MetricText.
List<(String, String)> hoursMinutesParts(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return [if (h > 0) ('$h', 'h'), ('$m', 'm')];
}

String hoursMinutes(Duration d) =>
    hoursMinutesParts(d).map((p) => '${p.$1}${p.$2}').join(' ');

String clockTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Tuesday, 20 October"
String longDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// "T" for Tuesday, for chart labels.
String weekdayInitial(DateTime d) => _weekdays[d.weekday - 1][0];
