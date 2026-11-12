import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/organization_credit.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../providers/locale_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 190,
                child: SegmentedTabs<String>(
                  options: const {'bn': 'বাংলা', 'en': 'English'},
                  selected: AppStrings.languageCode,
                  onChanged: (code) async {
                    await locale.change(code);
                    restartNavigation();
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(color: AppColors.redTint, shape: BoxShape.circle),
                child: const Icon(Icons.water_drop, size: 84, color: AppColors.red),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              tr('welcome.title'),
              textAlign: TextAlign.center,
              style: AppFonts.heading(size: 28, weight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              tr('welcome.subtitle'),
              textAlign: TextAlign.center,
              style: AppFonts.body(size: 16, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            _Feature(Icons.place_outlined, tr('welcome.f1_title'), tr('welcome.f1_text')),
            _Feature(Icons.notifications_none, tr('welcome.f2_title'), tr('welcome.f2_text')),
            _Feature(Icons.favorite_border, tr('welcome.f3_title'), tr('welcome.f3_text')),
            const SizedBox(height: 24),
            AppButton(
              label: tr('welcome.register'),
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: tr('welcome.login'),
              kind: AppButtonKind.outline,
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LoginScreen())),
            ),
            const SizedBox(height: 28),
            const OrganizationCredit(),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.redTint, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.red),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.body(weight: FontWeight.w700)),
                Text(text, style: AppFonts.body(size: 14, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
