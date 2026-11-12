import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/bottom_sheet.dart';
import '../../../core/widgets/user_avatar.dart';

/// Star rating + comment. [submit] does the API call and returns the message.
/// Used both for "rate the donor" and "rate the requester". Returns true when saved.
Future<bool> showRateSheet(
  BuildContext context, {
  required String name,
  String? photoUrl,
  required Future<String?> Function(int rating, String? remarks) submit,
}) async {
  final saved = await showAppSheet<bool>(
    context,
    child: _RateSheet(name: name, photoUrl: photoUrl, submit: submit),
  );
  return saved ?? false;
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({required this.name, required this.photoUrl, required this.submit});

  final String name;
  final String? photoUrl;
  final Future<String?> Function(int rating, String? remarks) submit;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  final _remarks = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final remarks = _remarks.text.trim();
      final message = await widget.submit(_rating, remarks.isEmpty ? null : remarks);
      if (!mounted) return;
      showSuccess(context, message);
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: UserAvatar(name: widget.name, photoUrl: widget.photoUrl, size: 72),
        ),
        const SizedBox(height: 12),
        Text(tr('rate.title', {'name': widget.name}), textAlign: TextAlign.center, style: AppFonts.heading(size: 20)),
        const SizedBox(height: 4),
        Text(
          tr('rate.subtitle'),
          textAlign: TextAlign.center,
          style: AppFonts.body(size: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Center(
          child: StarRating(rating: _rating, size: 42, onChanged: (value) => setState(() => _rating = value)),
        ),
        const SizedBox(height: 6),
        Text(
          tr('rate.level_$_rating'),
          textAlign: TextAlign.center,
          style: AppFonts.body(weight: FontWeight.w600, color: AppColors.amber),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: tr('rate.comment'),
          controller: _remarks,
          hint: tr('rate.comment_hint'),
          maxLines: 3,
          maxLength: 500,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: tr('common.later'),
                kind: AppButtonKind.neutral,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(label: tr('rate.submit'), loading: _saving, onPressed: _save),
            ),
          ],
        ),
      ],
    );
  }
}
