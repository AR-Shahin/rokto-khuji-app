import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../models/review.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final name = review.reviewer?.name ?? tr('review.anonymous');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(name: name, photoUrl: review.reviewer?.photoUrl, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppFonts.body(weight: FontWeight.w700)),
                    StarRating(rating: review.rating, size: 15),
                  ],
                ),
              ),
              Text(timeAgo(review.createdAt), style: AppFonts.body(size: 12.5, color: AppColors.muted)),
            ],
          ),
          if (review.remarks != null) ...[
            const SizedBox(height: 8),
            Text(review.remarks!, style: AppFonts.body(size: 15)),
          ],
          if (review.patientName != null) ...[
            const SizedBox(height: 6),
            Text(
              tr('review.for_request', {'name': review.patientName}),
              style: AppFonts.body(size: 13, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
