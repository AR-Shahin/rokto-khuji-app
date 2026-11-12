import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum BadgeTone { red, green, amber, blue, gray, solid }

/// Small rounded label, e.g. "Urgent", "Accepted".
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.tone = BadgeTone.gray});

  final String label;
  final BadgeTone tone;

  /// Colors for a request status (pending / resolved / closed / canceled).
  factory AppBadge.requestStatus(String status, String label) {
    final tone = switch (status) {
      'pending' => BadgeTone.amber,
      'resolved' => BadgeTone.green,
      'canceled' => BadgeTone.red,
      _ => BadgeTone.gray,
    };
    return AppBadge(label, tone: tone);
  }

  /// Colors for a donor's answer (pending / accepted / declined / completed).
  factory AppBadge.responseStatus(String status, String label) {
    final tone = switch (status) {
      'pending' => BadgeTone.blue,
      'accepted' || 'completed' => BadgeTone.green,
      _ => BadgeTone.gray,
    };
    return AppBadge(label, tone: tone);
  }

  /// Colors for priority (critical / urgent / regular).
  factory AppBadge.priority(String priority, String label) {
    final tone = switch (priority) {
      'critical' => BadgeTone.solid,
      'urgent' => BadgeTone.red,
      _ => BadgeTone.gray,
    };
    return AppBadge(label, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (tone) {
      BadgeTone.red => (AppColors.redTint, AppColors.redDark),
      BadgeTone.green => (AppColors.greenTint, AppColors.green),
      BadgeTone.amber => (AppColors.amberTint, AppColors.amber),
      BadgeTone.blue => (AppColors.blueTint, AppColors.blue),
      BadgeTone.gray => (AppColors.grayTint, AppColors.ink2),
      BadgeTone.solid => (AppColors.red, Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppFonts.body(size: 12.5, weight: FontWeight.w600, color: foreground),
      ),
    );
  }
}

/// Red circle with the blood group, e.g. "B+".
class BloodGroupBadge extends StatelessWidget {
  const BloodGroupBadge(this.group, {super.key, this.size = 40});

  final String? group;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
      child: Text(
        group ?? '?',
        style: AppFonts.latin(size: size * 0.38, color: Colors.white),
      ),
    );
  }
}

/// Row of 5 stars. Pass [onChanged] to make it tappable (rating sheet).
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 15, this.onChanged});

  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(star),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: onChanged == null ? 0 : 4),
              child: Icon(
                star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: size,
                color: star <= rating ? AppColors.star : AppColors.disabled,
              ),
            ),
          ),
      ],
    );
  }
}
