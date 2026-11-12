import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';

/// Turns any error into text for the user.
String errorMessage(Object error) {
  return error is ApiException ? error.message : tr('error.generic');
}

void showSuccess(BuildContext context, String? message) {
  if (message == null || message.isEmpty) return;
  _showSnackBar(context, message, AppColors.green);
}

void showError(BuildContext context, Object error) {
  _showSnackBar(context, errorMessage(error), AppColors.redDark);
}

void _showSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
}

Future<void> callPhone(String? phone) async {
  if (phone == null || phone.isEmpty) return;
  await launchUrl(Uri(scheme: 'tel', path: phone));
}

Future<void> openWhatsApp(String? phone) async {
  if (phone == null || phone.isEmpty) return;
  // Bangladeshi numbers are stored as 01XXXXXXXXX; WhatsApp needs 8801XXXXXXXXX.
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final international = digits.startsWith('880') ? digits : '88$digits';
  await openLink('https://wa.me/$international');
}

Future<void> openLink(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Date picker that returns null when the user cancels.
Future<DateTime?> pickDate(BuildContext context, {DateTime? initial, DateTime? first, DateTime? last}) {
  final now = DateTime.now();
  final firstDate = first ?? DateTime(1940);
  final lastDate = last ?? DateTime(now.year + 2);
  var initialDate = initial ?? now;
  if (initialDate.isBefore(firstDate)) initialDate = firstDate;
  if (initialDate.isAfter(lastDate)) initialDate = lastDate;

  return showDatePicker(context: context, initialDate: initialDate, firstDate: firstDate, lastDate: lastDate);
}

/// Yes / No dialog. Returns true only when the user confirms.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(tr('common.cancel'))),
        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return result ?? false;
}
