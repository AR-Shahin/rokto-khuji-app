import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../models/blood_group.dart';
import '../../providers/meta_provider.dart';
import '../config/app_config.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';

/// 4 x 2 grid of blood group buttons (register, edit profile, create request).
/// While the list is not loaded it shows a spinner, or the error with a retry button.
class BloodGroupGrid extends StatelessWidget {
  const BloodGroupGrid({super.key, required this.groups, required this.selectedId, required this.onSelected});

  final List<BloodGroup> groups;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const BloodGroupsUnavailable();

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        for (final group in groups)
          _GroupButton(name: group.name, selected: group.id == selectedId, onTap: () => onSelected(group.id)),
      ],
    );
  }
}

/// Spinner while blood groups load; the reason and a retry button when loading failed.
class BloodGroupsUnavailable extends StatelessWidget {
  const BloodGroupsUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final meta = context.watch<MetaProvider>();
    final error = meta.error;

    if (error == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.redTint, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.redDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('meta.groups_failed'),
                  style: AppFonts.body(size: 14.5, weight: FontWeight.w600, color: AppColors.redDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(errorMessage(error), style: AppFonts.body(size: 13.5, color: AppColors.ink2)),
          // Helps developers see which server the app is calling.
          if (kDebugMode) Text('API: ${AppConfig.apiBaseUrl}', style: AppFonts.body(size: 12, color: AppColors.muted)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: meta.isLoading ? null : meta.load,
              icon: const Icon(Icons.refresh),
              label: Text(tr('common.retry')),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupButton extends StatelessWidget {
  const _GroupButton({required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.red : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.red : AppColors.border, width: 1.5),
          ),
          child: Text(name, style: AppFonts.latin(size: 18, color: selected ? Colors.white : AppColors.text)),
        ),
      ),
    );
  }
}
