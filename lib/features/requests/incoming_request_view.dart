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
import 'widgets/complete_donation_sheet.dart';
import 'widgets/detail_parts.dart';
import 'widgets/rate_sheet.dart';

/// A request that was sent to me as a donor.
class IncomingRequestView extends StatefulWidget {
  const IncomingRequestView({super.key, required this.request, required this.onChanged});

  final BloodRequest request;

  /// Called after an action; null means "reload from the server".
  final ValueChanged<BloodRequest?> onChanged;

  @override
  State<IncomingRequestView> createState() => _IncomingRequestViewState();
}

class _IncomingRequestViewState extends State<IncomingRequestView> {
  bool _busy = false;

  BloodRequest get _r => widget.request;

  Future<void> _respond({required bool accept}) async {
    if (!accept && _r.myStatus == 'accepted') {
      final ok = await confirm(
        context,
        title: tr('detail.cancel_accept_title'),
        message: tr('detail.cancel_accept_text'),
        confirmLabel: tr('detail.cancel_accept'),
      );
      if (!ok || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      final result = await context.read<BloodRequestService>().respond(_r.id, accept: accept);
      if (!mounted) return;
      showSuccess(context, result.message);
      widget.onChanged(null);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete() async {
    if (await showCompleteDonationSheet(context, _r)) widget.onChanged(null);
  }

  Future<void> _rateRequester() async {
    final requester = _r.requester;
    final service = context.read<BloodRequestService>();
    final saved = await showRateSheet(
      context,
      name: requester?.name ?? _r.patientName,
      photoUrl: requester?.photoUrl,
      submit: (rating, remarks) => service.reviewRequester(_r.id, rating: rating, remarks: remarks),
    );
    if (saved) widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    final status = r.myStatus ?? 'pending';
    final phone = r.contactNumber ?? r.requester?.phone;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              RequestHero(request: r),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(tr('detail.my_answer'), style: AppFonts.body(color: AppColors.muted)),
                  const SizedBox(width: 8),
                  AppBadge.responseStatus(status, tr('response.$status')),
                  const Spacer(),
                  AppBadge.requestStatus(r.status, r.statusLabel),
                ],
              ),
              const SizedBox(height: 14),
              RequestInfoCard(request: r),
              const SizedBox(height: 14),
              AppCard(
                child: Row(
                  children: [
                    UserAvatar(name: r.requester?.name ?? '?', photoUrl: r.requester?.photoUrl, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('detail.requester'), style: AppFonts.body(size: 13, color: AppColors.muted)),
                          Text(r.requester?.name ?? '-', style: AppFonts.body(weight: FontWeight.w700)),
                          if (phone != null)
                            Text(localizeDigits(phone), style: AppFonts.body(size: 14, color: AppColors.ink2)),
                        ],
                      ),
                    ),
                    if (phone != null)
                      IconButton.filledTonal(
                        onPressed: () => callPhone(phone),
                        tooltip: tr('common.call'),
                        icon: const Icon(Icons.phone, color: AppColors.green),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DonorProgress(request: r),
            ],
          ),
        ),
        _actions(status),
      ],
    );
  }

  /// Bottom buttons depend on my answer and on the request status.
  Widget _actions(String status) {
    final r = _r;
    final buttons = <Widget>[];

    if (status == 'pending' && r.status == 'pending') {
      buttons.add(
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: tr('detail.decline'),
                kind: AppButtonKind.neutral,
                icon: Icons.close,
                onPressed: _busy ? null : () => _respond(accept: false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: tr('detail.accept'),
                icon: Icons.check,
                loading: _busy,
                onPressed: () => _respond(accept: true),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'accepted' && r.isActive) {
      buttons
        ..add(
          AppButton(
            label: tr('detail.complete'),
            kind: AppButtonKind.success,
            icon: Icons.check_circle_outline,
            onPressed: _busy ? null : _complete,
          ),
        )
        ..add(const SizedBox(height: 6))
        ..add(
          AppButton(
            label: tr('detail.cancel_accept'),
            kind: AppButtonKind.ghost,
            height: 42,
            loading: _busy,
            onPressed: () => _respond(accept: false),
          ),
        );
    } else if (status == 'completed' && !r.reviewedRequester) {
      buttons.add(
        AppButton(
          label: tr('detail.rate_requester'),
          kind: AppButtonKind.tonal,
          icon: Icons.star_outline,
          onPressed: _rateRequester,
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }
}
