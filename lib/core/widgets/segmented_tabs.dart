import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Gray track with a white pill for the selected option (2-3 options).
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({super.key, required this.options, required this.selected, required this.onChanged});

  /// value -> label
  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.segmentTrack, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(entry.key),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: entry.key == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: entry.key == selected
                        ? const [BoxShadow(color: AppColors.shadow, blurRadius: 3, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    entry.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(
                      size: 15,
                      weight: FontWeight.w600,
                      color: entry.key == selected ? AppColors.text : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded chip that is red when selected (filters, blood groups).
class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap, this.latin = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Use the Space Grotesk font (for blood groups like "AB+").
  final bool latin;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.ink2;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.red : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.red : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: latin ? AppFonts.latin(color: color) : AppFonts.body(size: 15, weight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
