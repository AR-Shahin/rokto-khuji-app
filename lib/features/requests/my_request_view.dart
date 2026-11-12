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
import '../../core/widgets/user_avatar.dart';
import '../../models/blood_request.dart';
import '../../services/blood_request_service.dart';
import 'widgets/close_request_sheet.dart';
import 'widgets/detail_parts.dart';
import 'widgets/rate_sheet.dart';

/// A request I sent: who accepted, contact them, close or cancel, rate donors.
class MyRequestView extends StatefulWidget {
  const MyRequestView({super.key, required this.request, required this.onChanged});

  final BloodRequest request;
  final ValueChanged<BloodRequest?> onChanged;

  @override
  State<MyRequestView> createState() => _MyRequestViewState();
}

class _MyRequestViewState extends State<MyRequestView> {
  bool _canceling = false;

  BloodRequest get _r => widget.request;

  Future<void> _cancel() async {
    final ok = await confirm(
      context,
      title: tr('detail.cancel_request_title'),
      message: tr('detail.cancel_request_text'),
      confirmLabel: tr('detail.cancel_request'),
    );
    if (!ok || !mounted) return;

    setState(() => _canceling = true);
    try {
      final result = await context.read<BloodRequestService>().cancel(_r.id);
      if (!mounted) return;
      showSuccess(context, result.message);
      widget.onChanged(result.request);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _canceling = false);
    }
  }

  Future<void> _close() async {
    final updated = await showCloseRequestSheet(context, _r);
    if (updated != null) widget.onChanged(updated);
  }

  Future<void> _rate(RequestTarget target) async {
    final donor = target.donor!;
    final service = context.read<BloodRequestService>();
    final saved = await showRateSheet(
      context,
      name: donor.name,
      photoUrl: donor.photoUrl,
      submit: (rating, remarks) => service.reviewDonor(_r.id, donor.id, rating: rating, remarks: remarks),
    );
    if (saved) widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final confirmed = r.confirmedTargets.where((t) => t.donor != null).toList();
    final waiting = r.targets.where((t) => t.status == 'pending').length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Row(
                  children: [
                    BloodGroupBadge(r.bloodGroup, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.patientName, style: AppFonts.body(size: 17, weight: FontWeight.w700)),
                          Text(
                            '${r.hospitalName} · ${tr('request.bags', {'n': localizeDigits(r.bags)})}',
                            style: AppFonts.body(size: 14, color: AppColors.muted),
                          ),
                          const SizedBox(height: 6),
                          AppBadge.requestStatus(r.status, r.statusLabel),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              RequestHero(request: r),
              const SizedBox(height: 14),
              DonorProgress(request: r),
              if (r.escalationLevel > 0 && r.searchArea != null) ...[
                const SizedBox(height: 14),
                AppCard(
                  color: r.escalationExhausted ? AppColors.amberTint : AppColors.blueTint,
                  borderColor: Colors.transparent,
                  child: IconLine(
                    Icons.cell_tower,
                    r.escalationExhausted
                        ? tr('request.search_exhausted')
                        : tr('request.search_widened', {'area': r.searchArea!.label}),
                    color: r.escalationExhausted ? AppColors.amber : AppColors.blue,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(tr('detail.accepted_donors', {'n': localizeDigits(confirmed.length)}), style: AppFonts.heading()),
              const SizedBox(height: 8),
              if (confirmed.isEmpty)
                AppCard(
                  child: Text(
                    tr('detail.no_accepted'),
                    textAlign: TextAlign.center,
                    style: AppFonts.body(size: 15, color: AppColors.muted),
                  ),
                ),
              for (final target in confirmed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DonorTile(
                    target: target,
                    canRate: target.status == 'completed' && !target.reviewed,
                    onRate: () => _rate(target),
                  ),
                ),
              if (waiting > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tr('detail.waiting', {'n': localizeDigits(waiting)}),
                    style: AppFonts.body(size: 14, color: AppColors.muted),
                  ),
                ),
              const SizedBox(height: 14),
              RequestInfoCard(request: r),
            ],
          ),
        ),
        if (r.isActive)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(label: tr('detail.close_request'), icon: Icons.check, onPressed: _close),
                  const SizedBox(height: 4),
                  AppButton(
                    label: tr('detail.cancel_request'),
                    kind: AppButtonKind.ghost,
                    height: 42,
                    loading: _canceling,
                    onPressed: _cancel,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DonorTile extends StatelessWidget {
  const _DonorTile({required this.target, required this.canRate, required this.onRate});

  final RequestTarget target;
  final bool canRate;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final donor = target.donor!;

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              UserAvatar(name: donor.name, photoUrl: donor.photoUrl, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(donor.name, style: AppFonts.body(weight: FontWeight.w700)),
                    if (donor.phone != null)
                      Text(localizeDigits(donor.phone!), style: AppFonts.body(size: 14, color: AppColors.muted)),
                  ],
                ),
              ),
              AppBadge.responseStatus(target.status, target.statusLabel),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: tr('common.call'),
                  kind: AppButtonKind.neutral,
                  icon: Icons.phone_outlined,
                  height: 44,
                  onPressed: () => callPhone(donor.phone),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'WhatsApp',
                  kind: AppButtonKind.neutral,
                  icon: Icons.chat_outlined,
                  height: 44,
                  onPressed: () => openWhatsApp(donor.phone),
                ),
              ),
              if (canRate) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: tr('detail.rate'),
                    kind: AppButtonKind.tonal,
                    icon: Icons.star_outline,
                    height: 44,
                    onPressed: onRate,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
