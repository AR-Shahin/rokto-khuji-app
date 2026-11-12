import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'change_password_screen.dart';
import 'widgets/settings_group.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _connectTelegram(BuildContext context) async {
    try {
      final url = await context.read<ProfileService>().telegramConnectUrl();
      if (url != null) {
        await openLink(url);
      } else if (context.mounted) {
        showError(context, ApiException(message: tr('settings.telegram_unavailable')));
      }
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _resendVerification(BuildContext context) async {
    try {
      final message = await context.read<AuthService>().resendVerificationEmail();
      if (context.mounted) showSuccess(context, message);
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _logoutAll(BuildContext context) async {
    final ok = await confirm(
      context,
      title: tr('settings.logout_all'),
      message: tr('settings.logout_all_text'),
      confirmLabel: tr('profile.logout'),
    );
    if (ok && context.mounted) {
      await context.read<AuthProvider>().logout(allDevices: true);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final password = await showDialog<String>(context: context, builder: (_) => const _DeleteAccountDialog());
    if (password == null || !context.mounted) return;

    try {
      await context.read<ProfileService>().deleteAccount(password);
      if (context.mounted) await context.read<AuthProvider>().clearSession();
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final locale = context.read<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _title(tr('settings.language')),
          SegmentedTabs<String>(
            options: const {'bn': 'বাংলা', 'en': 'English'},
            selected: AppStrings.languageCode,
            onChanged: (code) async {
              await locale.change(code);
              restartNavigation();
            },
          ),
          _title(tr('settings.security')),
          SettingsGroup(
            items: [
              SettingsTile(
                icon: Icons.lock_outline,
                label: tr('settings.change_password'),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen())),
              ),
              SettingsTile(
                icon: Icons.verified_user_outlined,
                label: tr('settings.email_verification'),
                trailing: (user?.emailVerified ?? false)
                    ? AppBadge(tr('profile.verified'), tone: BadgeTone.green)
                    : AppBadge(tr('verify.resend'), tone: BadgeTone.amber),
                onTap: () {
                  if (!(user?.emailVerified ?? false)) {
                    _resendVerification(context);
                  }
                },
              ),
              SettingsTile(
                icon: Icons.devices_outlined,
                label: tr('settings.logout_all'),
                onTap: () => _logoutAll(context),
              ),
            ],
          ),
          _title(tr('settings.notifications')),
          SettingsGroup(
            items: [
              SettingsTile(
                icon: Icons.send_outlined,
                label: tr('settings.telegram'),
                trailing: (user?.telegramLinked ?? false)
                    ? AppBadge(tr('settings.linked'), tone: BadgeTone.green)
                    : AppBadge(tr('settings.not_linked')),
                onTap: () {
                  if (!(user?.telegramLinked ?? false)) {
                    _connectTelegram(context);
                  }
                },
              ),
            ],
          ),
          _title(tr('settings.about')),
          SettingsGroup(
            items: [
              SettingsTile(
                icon: Icons.language,
                label: tr('settings.website'),
                onTap: () => openLink(AppConfig.website),
              ),
            ],
          ),
          _title(tr('settings.danger')),
          SettingsGroup(
            items: [
              SettingsTile(
                icon: Icons.delete_outline,
                label: tr('settings.delete_account'),
                danger: true,
                onTap: () => _deleteAccount(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(tr('settings.delete_text'), style: AppFonts.body(size: 13, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(text, style: AppFonts.heading(size: 16)),
    );
  }
}

/// Asks for the password before deleting. Returns the password, or null.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('settings.delete_account')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr('settings.delete_text')),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: InputDecoration(labelText: tr('field.password')),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'))),
        TextButton(
          onPressed: () {
            if (_password.text.isNotEmpty) {
              Navigator.pop(context, _password.text);
            }
          },
          child: Text(tr('common.delete'), style: const TextStyle(color: AppColors.red)),
        ),
      ],
    );
  }
}
