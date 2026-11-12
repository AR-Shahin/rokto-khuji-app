import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badges.dart';
import '../../../models/blood_request.dart';

/// Red header: blood group, bags, priority and when it is needed.
class RequestHero extends StatelessWidget {
  const RequestHero({super.key, required this.request});

  final BloodRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final when = r.hasTime ? formatDateTime(r.neededAt) : formatDate(r.neededAt);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('detail.needed'), style: AppFonts.body(size: 14, color: Colors.white)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(r.bloodGroup ?? '-', style: AppFonts.latin(size: 36, color: Colors.white)),
                        const SizedBox(width: 8),
                        Text(
                          tr('request.bags', {'n': localizeDigits(r.bags)}),
                          style: AppFonts.body(size: 17, weight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  r.priorityLabel,
                  style: AppFonts.body(size: 13, weight: FontWeight.w700, color: AppColors.redDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.redDark, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.isOverdue && r.isActive ? tr('detail.time_passed', {'time': when}) : when,
                    style: AppFonts.body(weight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient, hospital, location, reason and note.
class RequestInfoCard extends StatelessWidget {
  const RequestInfoCard({super.key, required this.request});

  final BloodRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final rows = <(IconData, String, String?)>[
      (Icons.person_outline, tr('field.patient'), r.patientName),
      (Icons.local_hospital_outlined, tr('field.hospital'), r.hospitalName),
      (Icons.place_outlined, tr('field.area'), r.area?.label),
      (Icons.pin_drop_outlined, tr('field.location'), r.location),
      (Icons.description_outlined, tr('field.reason'), r.reason),
      (Icons.notes, tr('field.note'), r.note),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (final row in rows.where((row) => row.$3 != null && row.$3!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.$1, size: 20, color: AppColors.muted),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 92,
                    child: Text(row.$2, style: AppFonts.body(size: 14, color: AppColors.muted)),
                  ),
                  Expanded(
                    child: Text(row.$3!, style: AppFonts.body(size: 15, weight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "1 / 2 donors found" with a progress bar.
class DonorProgress extends StatelessWidget {
  const DonorProgress({super.key, required this.request});

  final BloodRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final got = r.acceptedCount + r.completedCount;
    final left = (r.bags - got).clamp(0, r.bags);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('detail.found', {'got': localizeDigits(got), 'need': localizeDigits(r.bags)}),
                  style: AppFonts.body(weight: FontWeight.w700),
                ),
              ),
              if (left > 0)
                AppBadge(tr('detail.need_more', {'n': localizeDigits(left)}), tone: BadgeTone.amber)
              else
                AppBadge(tr('detail.enough'), tone: BadgeTone.green),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: r.bags == 0 ? 0 : (got / r.bags).clamp(0, 1).toDouble(),
              minHeight: 8,
              color: AppColors.green,
              backgroundColor: AppColors.greenTint,
            ),
          ),
          if (r.notifiedCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              tr('detail.notified', {'n': localizeDigits(r.notifiedCount)}),
              style: AppFonts.body(size: 13, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
