import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "An initiative of" + the Dreamfil Youth Welfare Organization logo.
class OrganizationCredit extends StatelessWidget {
  const OrganizationCredit({super.key, this.logoSize = 132});

  static const String logoAsset = 'assets/images/dreamfil_logo.jpg';

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${tr('credit.initiative')} ${tr('credit.organization')}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr('credit.initiative'),
                  style: AppFonts.body(size: 13, weight: FontWeight.w600, color: AppColors.muted),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Image.asset(logoAsset, width: logoSize, height: logoSize, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
