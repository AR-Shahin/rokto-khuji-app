import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badges.dart';
import '../../../models/blood_request.dart';

/// Card for a blood request in lists (Home, Incoming, My requests).
class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, required this.onTap});

  final BloodRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final badges = <Widget>[
      if (r.priority != 'regular') AppBadge.priority(r.priority, r.priorityLabel),
      if (r.myStatus != null)
        AppBadge.responseStatus(r.myStatus!, tr('response.${r.myStatus}'))
      else
        AppBadge.requestStatus(r.status, r.statusLabel),
      if (r.isOverdue && r.isActive) AppBadge(tr('request.overdue'), tone: BadgeTone.red),
    ];

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BloodGroupBadge(r.bloodGroup, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(size: 16.5, weight: FontWeight.w700),
                    ),
                    Text(
                      tr('request.bags', {'n': localizeDigits(r.bags)}),
                      style: AppFonts.body(size: 14, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text(timeAgo(r.createdAt), style: AppFonts.body(size: 12.5, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          IconLine(Icons.local_hospital_outlined, r.hospitalName),
          if (r.area != null) ...[const SizedBox(height: 4), IconLine(Icons.place_outlined, r.area!.label)],
          const SizedBox(height: 4),
          IconLine(
            Icons.schedule,
            r.hasTime ? formatDateTime(r.neededAt) : formatDate(r.neededAt),
            color: r.isOverdue && r.isActive ? AppColors.redDark : AppColors.ink2,
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: badges),
          if (r.isMine && r.escalationLevel > 0 && r.searchArea != null) ...[
            const SizedBox(height: 10),
            _EscalationNote(area: r.searchArea!.label, exhausted: r.escalationExhausted),
          ],
        ],
      ),
    );
  }
}

/// "Search widened to Kachua upazila" note for the requester.
class _EscalationNote extends StatelessWidget {
  const _EscalationNote({required this.area, required this.exhausted});

  final String area;
  final bool exhausted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: exhausted ? AppColors.amberTint : AppColors.blueTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cell_tower, size: 18, color: exhausted ? AppColors.amber : AppColors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exhausted ? tr('request.search_exhausted') : tr('request.search_widened', {'area': area}),
              style: AppFonts.body(size: 13.5, color: exhausted ? AppColors.amber : AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
