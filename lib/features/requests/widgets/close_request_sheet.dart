import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/bottom_sheet.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/blood_request.dart';
import '../../../services/blood_request_service.dart';

/// Requester closes the request and picks who actually donated.
/// Returns the updated request, or null when the sheet was closed.
Future<BloodRequest?> showCloseRequestSheet(BuildContext context, BloodRequest request) {
  return showAppSheet<BloodRequest>(context, child: _CloseSheet(request: request));
}

class _CloseSheet extends StatefulWidget {
  const _CloseSheet({required this.request});

  final BloodRequest request;

  @override
  State<_CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<_CloseSheet> {
  late final Set<int> _selected = {
    for (final t in widget.request.confirmedTargets)
      if (t.donor != null) t.donor!.id,
  };
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  bool _saving = false;

  Future<void> _pickDate() async {
    final date = await pickDate(context, initial: _date, last: DateTime.now());
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await context.read<BloodRequestService>().close(
        widget.request.id,
        donationDate: _date,
        donorIds: _selected.toList(),
      );
      if (!mounted) return;
      showSuccess(context, result.message);
      Navigator.pop(context, result.request);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donors = widget.request.confirmedTargets.where((t) => t.donor != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(tr('close.title'), subtitle: tr('close.subtitle')),
        const SizedBox(height: 12),
        if (donors.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(tr('close.no_donors'), style: AppFonts.body(size: 14.5, color: AppColors.muted)),
          ),
        for (final target in donors)
          CheckboxListTile(
            value: _selected.contains(target.donor!.id),
            onChanged: (checked) => setState(() {
              checked == true ? _selected.add(target.donor!.id) : _selected.remove(target.donor!.id);
            }),
            contentPadding: EdgeInsets.zero,
            secondary: UserAvatar(name: target.donor!.name, photoUrl: target.donor!.photoUrl, size: 40),
            title: Text(target.donor!.name, style: AppFonts.body(weight: FontWeight.w600)),
            subtitle: target.donor!.phone == null ? null : Text(localizeDigits(target.donor!.phone!)),
          ),
        const SizedBox(height: 8),
        PickerField(
          label: tr('field.donation_date'),
          value: formatDate(_date),
          icon: Icons.calendar_today_outlined,
          onTap: _pickDate,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: tr('common.cancel'),
                kind: AppButtonKind.neutral,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(label: tr('close.submit'), loading: _saving, onPressed: _save),
            ),
          ],
        ),
      ],
    );
  }
}
