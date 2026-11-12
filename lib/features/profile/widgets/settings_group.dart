import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// White rounded box holding menu rows, separated by thin lines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.items});

  final List<SettingsTile> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[if (i > 0) const Divider(height: 1, indent: 52), items[i]],
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Red text, no arrow (logout, delete account).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.text;

    return ListTile(
      onTap: onTap,
      minTileHeight: 56,
      leading: Icon(icon, size: 22, color: danger ? AppColors.red : AppColors.ink2),
      title: Text(
        label,
        style: AppFonts.body(weight: FontWeight.w500, color: color),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          if (!danger) const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
