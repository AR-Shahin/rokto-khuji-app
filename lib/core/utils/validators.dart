import '../l10n/app_strings.dart';

/// Form checks done on the phone before calling the API.
/// The server still validates everything; its errors are shown under the fields.
class Validators {
  const Validators._();

  static String? required(String? value) {
    return (value == null || value.trim().isEmpty) ? tr('validation.required') : null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return tr('validation.required');
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : tr('validation.email');
  }

  /// Bangladeshi mobile: 01XXXXXXXXX (11 digits).
  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return tr('validation.required');
    return RegExp(r'^01[3-9]\d{8}$').hasMatch(text) ? null : tr('validation.phone');
  }

  /// Same check as [phone], but empty is allowed.
  static String? optionalPhone(String? value) {
    return (value == null || value.trim().isEmpty) ? null : phone(value);
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return tr('validation.required');
    return value.length < 8 ? tr('validation.password_min') : null;
  }

  /// Returns a validator that checks the value equals [other]'s current text.
  static String? Function(String?) sameAs(String Function() other) {
    return (value) => value == other() ? null : tr('validation.password_match');
  }
}
