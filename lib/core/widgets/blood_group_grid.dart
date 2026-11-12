import 'package:material_ui/material_ui.dart';

import '../../models/blood_group.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 4 x 2 grid of blood group buttons (register, edit profile, create request).
class BloodGroupGrid extends StatelessWidget {
  const BloodGroupGrid({super.key, required this.groups, required this.selectedId, required this.onSelected});

  final List<BloodGroup> groups;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
