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
import '../../../models/blood_request.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/blood_request_service.dart';

/// Donor marks an accepted donation as done. Returns true when saved.
Future<bool> showCompleteDonationSheet(BuildContext context, BloodRequest request) async {
  final saved = await showAppSheet<bool>(context, child: _CompleteSheet(request: request));
  return saved ?? false;
}

class _CompleteSheet extends StatefulWidget {
  const _CompleteSheet({required this.request});

  final BloodRequest request;

  @override
  State<_CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<_CompleteSheet> {
  late DateTime _date = _defaultDate();
  bool _didDonate = true;
  bool _saving = false;

  /// The day the blood was needed, but never a future day.
  DateTime _defaultDate() {
    final needed = widget.request.neededAt?.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    if (needed == null || needed.isAfter(today)) return today;
    return DateUtils.dateOnly(needed);
  }

  Future<void> _pickDate() async {
    final date = await pickDate(context, initial: _date, last: DateTime.now());
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await context.read<BloodRequestService>().complete(
        widget.request.id,
        donationDate: _date,
        didDonate: _didDonate,
      );
      if (!mounted) return;
      showSuccess(context, result.message);
      // The last donation date changed on the server.
      context.read<AuthProvider>().refreshUser().ignore();
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
        SheetTitle(tr('complete.title'), subtitle: '${widget.request.patientName} · ${widget.request.hospitalName}'),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _didDonate,
          onChanged: (value) => setState(() => _didDonate = value),
          contentPadding: EdgeInsets.zero,
          title: Text(tr('complete.i_donated'), style: AppFonts.body(weight: FontWeight.w700)),
          subtitle: Text(tr('complete.i_donated_help'), style: AppFonts.body(size: 13, color: AppColors.muted)),
        ),
        const SizedBox(height: 8),
        PickerField(
          label: tr('field.donation_date'),
          value: formatDate(_date),
          icon: Icons.calendar_today_outlined,
          onTap: _pickDate,
        ),
        if (_didDonate) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(14)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tr('complete.gap_info'), style: AppFonts.body(size: 13.5, color: AppColors.blue)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: tr('common.cancel'),
                kind: AppButtonKind.neutral,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: tr('common.confirm'),
                kind: AppButtonKind.success,
                icon: Icons.check,
                loading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
