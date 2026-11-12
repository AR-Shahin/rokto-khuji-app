import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'my_reviews_screen.dart';
import 'settings_screen.dart';
import 'share_story_screen.dart';
import 'widgets/availability_card.dart';
import 'widgets/settings_group.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await confirm(
      context,
      title: tr('profile.logout'),
      message: tr('profile.logout_confirm'),
      confirmLabel: tr('profile.logout'),
    );
    if (ok && context.mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Scaffold(body: LoadingView());

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('nav.profile')),
        actions: [
          IconButton(
            onPressed: () => _open(context, const SettingsScreen()),
            tooltip: tr('settings.title'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<AuthProvider>().refreshUser,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(user: user, onEdit: () => _open(context, const EditProfileScreen())),
            const SizedBox(height: 14),
            if (user.isDonor) ...[AvailabilityCard(user: user), const SizedBox(height: 14)],
            SettingsGroup(
              items: [
                SettingsTile(
                  icon: Icons.edit_outlined,
                  label: tr('profile.edit'),
                  onTap: () => _open(context, const EditProfileScreen()),
                ),
                SettingsTile(
                  icon: Icons.star_outline,
                  label: tr('reviews.title'),
                  onTap: () => _open(context, const MyReviewsScreen()),
                ),
                if (user.isConsumer)
                  SettingsTile(
                    icon: Icons.format_quote_outlined,
                    label: tr('story.title'),
                    onTap: () => _open(context, const ShareStoryScreen()),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SettingsGroup(
              items: [
                SettingsTile(
                  icon: Icons.settings_outlined,
                  label: tr('settings.title'),
                  onTap: () => _open(context, const SettingsScreen()),
                ),
                SettingsTile(
                  icon: Icons.help_outline,
                  label: tr('profile.help'),
                  onTap: () => openLink(AppConfig.website),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SettingsGroup(
              items: [
                SettingsTile(
                  icon: Icons.logout,
                  label: tr('profile.logout'),
                  danger: true,
                  onTap: () => _logout(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tr('profile.version', {'v': localizeDigits(AppConfig.appVersion)}),
              textAlign: TextAlign.center,
              style: AppFonts.body(size: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.onEdit});

  final User user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(value, style: AppFonts.heading(size: 20)),
            Text(label, style: AppFonts.body(size: 13, color: AppColors.muted)),
          ],
        ),
      );
    }

    final rating = user.isDonor ? user.ratingAsDonor : user.ratingAsRequester;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 76),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(user.name, style: AppFonts.heading(size: 20))),
                        if (user.emailVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 18, color: AppColors.blue),
                        ],
                      ],
                    ),
                    Text(user.email, style: AppFonts.body(size: 14, color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (user.bloodGroup != null) AppBadge(user.bloodGroup!.name, tone: BadgeTone.solid),
                        AppBadge(tr('role.${user.role}')),
                        if (user.badge != null) AppBadge(user.badge!, tone: BadgeTone.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              stat(localizeDigits(user.totalDonations), tr('home.donations')),
              stat(rating > 0 ? localizeDigits(rating.toStringAsFixed(1)) : '-', tr('home.rating')),
              stat('${localizeDigits(user.profileCompletion)}%', tr('profile.complete')),
            ],
          ),
        ],
      ),
    );
  }
}
