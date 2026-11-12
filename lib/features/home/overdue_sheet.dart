import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/bottom_sheet.dart';
import '../../models/blood_request.dart';
import '../../models/dashboard.dart';
import '../../services/blood_request_service.dart';
import '../requests/request_detail_screen.dart';
import '../requests/widgets/complete_donation_sheet.dart';

/// "Donation not completed yet" popup. Lists every overdue donation:
///  - as a donor: complete it or say you could not donate,
///  - as a requester: open the request to close or cancel it.
///
/// Returns true when something changed (so Home reloads).
Future<bool> showOverdueSheet(BuildContext context, OverdueDonations overdue) async {
  final changed = await showAppSheet<bool>(context, child: _OverdueSheet(overdue: overdue));
  return changed ?? false;
}

class _OverdueSheet extends StatefulWidget {
  const _OverdueSheet({required this.overdue});

  final OverdueDonations overdue;

  @override
  State<_OverdueSheet> createState() => _OverdueSheetState();
}

class _OverdueSheetState extends State<_OverdueSheet> {
  /// Ids already handled in this sheet; they disappear from the list.
  final Set<int> _done = {};
  int? _busyId;

  List<BloodRequest> get _asDonor => widget.overdue.asDonor.where((r) => !_done.contains(r.id)).toList();
  List<BloodRequest> get _asRequester => widget.overdue.asRequester.where((r) => !_done.contains(r.id)).toList();

  void _finish(int id) {
    setState(() => _done.add(id));
    if (_asDonor.isEmpty && _asRequester.isEmpty) Navigator.pop(context, true);
  }

  Future<void> _complete(BloodRequest request) async {
    final done = await showCompleteDonationSheet(context, request);
    if (done && mounted) _finish(request.id);
  }

  Future<void> _couldNotDonate(BloodRequest request) async {
    setState(() => _busyId = request.id);
    try {
      final result = await context.read<BloodRequestService>().respond(request.id, accept: false);
      if (!mounted) return;
      showSuccess(context, result.message);
      _finish(request.id);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _openMyRequest(BloodRequest request) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => RequestDetailScreen(requestId: request.id)));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.redTint, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.red),
            ),
            const SizedBox(width: 12),
            Expanded(child: SheetTitle(tr('overdue.title'), subtitle: tr('overdue.subtitle'))),
          ],
        ),
        const SizedBox(height: 16),
        for (final r in _asDonor)
          _item(
            r,
            badge: AppBadge(tr('overdue.you_accepted'), tone: BadgeTone.blue),
            actions: [
              AppButton(
                label: tr('overdue.mark_complete'),
                icon: Icons.check,
                height: 46,
                onPressed: () => _complete(r),
              ),
              const SizedBox(height: 6),
              AppButton(
                label: tr('overdue.could_not'),
                kind: AppButtonKind.ghost,
                icon: Icons.close,
                height: 42,
                loading: _busyId == r.id,
                onPressed: () => _couldNotDonate(r),
              ),
            ],
          ),
        for (final r in _asRequester)
          _item(
            r,
            badge: AppBadge(tr('overdue.your_request'), tone: BadgeTone.amber),
            actions: [
              AppButton(
                label: tr('overdue.close_or_cancel'),
                icon: Icons.open_in_new,
                height: 46,
                onPressed: () => _openMyRequest(r),
              ),
            ],
          ),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(tr('overdue.keeps_showing'), style: AppFonts.body(size: 13, color: AppColors.muted)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppButton(
          label: tr('overdue.later'),
          kind: AppButtonKind.neutral,
          onPressed: () => Navigator.pop(context, _done.isNotEmpty),
        ),
      ],
    );
  }

  Widget _item(BloodRequest r, {required Widget badge, required List<Widget> actions}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        color: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                BloodGroupBadge(r.bloodGroup),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      badge,
                      const SizedBox(height: 4),
                      Text(r.patientName, style: AppFonts.body(weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            IconLine(Icons.local_hospital_outlined, r.hospitalName),
            const SizedBox(height: 4),
            IconLine(
              Icons.schedule,
              tr('overdue.was_needed', {'time': r.hasTime ? formatDateTime(r.neededAt) : formatDate(r.neededAt)}),
              color: AppColors.redDark,
            ),
            const SizedBox(height: 12),
            ...actions,
          ],
        ),
      ),
    );
  }
}
