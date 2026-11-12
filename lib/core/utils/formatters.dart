import 'package:intl/intl.dart';

import '../l10n/app_strings.dart';

const List<String> _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Shows numbers in Bangla digits when the app is in Bangla.
String localizeDigits(Object value) {
  final text = value.toString();
  if (AppStrings.languageCode != 'bn') return text;

  final buffer = StringBuffer();
  for (final unit in text.codeUnits) {
    final isDigit = unit >= 48 && unit <= 57;
    buffer.write(isDigit ? _bnDigits[unit - 48] : String.fromCharCode(unit));
  }
  return buffer.toString();
}

/// 12 Nov 2026
String formatDate(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('d MMM yyyy', AppStrings.languageCode).format(date.toLocal());
}

/// 12 Nov, 4:00 PM
String formatDateTime(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('d MMM, h:mm a', AppStrings.languageCode).format(date.toLocal());
}

/// The format the API expects: 2026-11-12
String apiDate(DateTime date) => DateFormat('yyyy-MM-dd', 'en').format(date);

/// "10 minutes ago", "2 days ago", or the date when it is older than a week.
String timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date.toLocal());

  if (diff.inMinutes < 1) return tr('time.just_now');
  if (diff.inMinutes < 60) return tr('time.minutes_ago', {'n': localizeDigits(diff.inMinutes)});
  if (diff.inHours < 24) return tr('time.hours_ago', {'n': localizeDigits(diff.inHours)});
  if (diff.inDays < 7) return tr('time.days_ago', {'n': localizeDigits(diff.inDays)});
  return formatDate(date);
}

/// "Rakib Hasan" -> "RH". Used when a user has no photo.
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final first = String.fromCharCode(parts.first.runes.first);
  if (parts.length == 1) return first.toUpperCase();
  final last = String.fromCharCode(parts.last.runes.first);
  return (first + last).toUpperCase();
}
