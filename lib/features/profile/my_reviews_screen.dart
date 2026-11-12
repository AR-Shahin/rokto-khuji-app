import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../models/json.dart';
import '../../models/review.dart';
import '../../services/profile_service.dart';
import 'widgets/review_tile.dart';

/// Reviews I received, as a donor or as a requester.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  String _as = 'donor';
  ReviewSummary? _summary;

  @override
  Widget build(BuildContext context) {
    final service = context.read<ProfileService>();
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: Text(tr('reviews.title'))),
      body: Column(
        children: [
          if (summary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SummaryCard(summary: summary),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedTabs<String>(
              options: {
                'donor': tr('reviews.as_donor', {'n': localizeDigits(summary?.asDonorCount ?? 0)}),
                'requester': tr('reviews.as_requester', {'n': localizeDigits(summary?.asRequesterCount ?? 0)}),
              },
              selected: _as,
              onChanged: (value) => setState(() => _as = value),
            ),
          ),
          Expanded(
            child: PagedListView<Review>(
              key: ValueKey(_as),
              fetch: (page) => service.reviews(as: _as, page: page),
              onFirstPage: (page) {
                final raw = asJson(page.meta['summary']);
                if (raw != null) {
                  setState(() => _summary = ReviewSummary.fromJson(raw));
                }
              },
              emptyIcon: Icons.star_outline,
              emptyTitle: tr('reviews.empty'),
              itemBuilder: (context, review) => ReviewTile(review: review),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.total == 0 ? 1 : summary.total;

    return AppCard(
      child: Row(
        children: [
          Column(
            children: [
              Text(
                summary.average == null ? '-' : localizeDigits(summary.average!.toStringAsFixed(1)),
                style: AppFonts.heading(size: 36, weight: FontWeight.w800),
              ),
              StarRating(rating: (summary.average ?? 0).round(), size: 14),
              const SizedBox(height: 4),
              Text(
                tr('reviews.count', {'n': localizeDigits(summary.total)}),
                style: AppFonts.body(size: 13, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                for (final entry in summary.distribution.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 14, child: Text(localizeDigits(entry.key), style: AppFonts.body(size: 13))),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.value / total,
                              minHeight: 7,
                              color: AppColors.star,
                              backgroundColor: AppColors.grayTint,
                            ),
                          ),
                        ),
                      ],
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
