import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/donor.dart';

/// One donor in the search results, with a call button.
class DonorTile extends StatelessWidget {
  const DonorTile({super.key, required this.donor, required this.onTap});

  final Donor donor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = donor;
    final details = [
      if (d.area != null) d.area!.name,
      if (d.age != null) tr('donor.age', {'n': localizeDigits(d.age!)}),
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          UserAvatar(name: d.name, photoUrl: d.photoUrl, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(weight: FontWeight.w700),
                      ),
                    ),
                    if (d.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, size: 16, color: AppColors.blue),
                    ],
                  ],
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(size: 13.5, color: AppColors.muted),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (d.bloodGroup != null) AppBadge(d.bloodGroup!, tone: BadgeTone.red),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text(
                          d.rating == null ? tr('donor.new') : localizeDigits(d.rating!.toStringAsFixed(1)),
                          style: AppFonts.body(size: 13, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      tr('donor.donations', {'n': localizeDigits(d.totalDonations)}),
                      style: AppFonts.body(size: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (d.phone != null)
            IconButton(
              onPressed: () => callPhone(d.phone),
              tooltip: tr('common.call'),
              icon: const Icon(Icons.phone, color: AppColors.green),
            ),
        ],
      ),
    );
  }
}
