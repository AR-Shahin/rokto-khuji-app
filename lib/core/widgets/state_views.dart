import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../l10n/app_strings.dart';
import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import 'app_button.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Icon + title + text + optional button. Base for the empty and error states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor = AppColors.red,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: iconColor),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: AppFonts.heading()),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppFonts.body(size: 15, color: AppColors.muted),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                kind: AppButtonKind.neutral,
                expand: false,
                height: 44,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when a request failed. Knows the "no internet" and
/// "verify your email first" cases.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final error = this.error;

    if (error is ApiException && error.isEmailNotVerified) {
      return VerifyEmailNotice(onVerified: onRetry);
    }

    final isNetwork = error is ApiException && error.isNetwork;
    return MessageView(
      icon: isNetwork ? Icons.wifi_off : Icons.error_outline,
      iconColor: AppColors.muted,
      title: isNetwork ? tr('error.no_internet') : tr('error.title'),
      message: isNetwork ? tr('error.check_connection') : errorMessage(error),
      actionLabel: tr('common.retry'),
      onAction: onRetry,
    );
  }
}

/// Donor search and creating a request need a verified email.
class VerifyEmailNotice extends StatefulWidget {
  const VerifyEmailNotice({super.key, required this.onVerified});

  /// Called after the user says "I have verified" and the server agrees.
  final VoidCallback onVerified;

  @override
  State<VerifyEmailNotice> createState() => _VerifyEmailNoticeState();
}

class _VerifyEmailNoticeState extends State<VerifyEmailNotice> {
  bool _sending = false;
  bool _checking = false;

  Future<void> _resend() async {
    setState(() => _sending = true);
    try {
      final message = await context.read<AuthService>().resendVerificationEmail();
      if (mounted) showSuccess(context, message);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.refreshUser();
      if (!mounted) return;
      if (auth.user?.emailVerified ?? false) {
        widget.onVerified();
      } else {
        showError(context, ApiException(message: tr('verify.not_yet')));
      }
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.amberTint, borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mail_outline, size: 40, color: AppColors.amber),
              const SizedBox(height: 10),
              Text(tr('verify.title'), style: AppFonts.heading()),
              const SizedBox(height: 6),
              Text(
                tr('verify.needed'),
                textAlign: TextAlign.center,
                style: AppFonts.body(size: 15, color: AppColors.ink2),
              ),
              const SizedBox(height: 16),
              AppButton(label: tr('verify.done'), onPressed: _check, loading: _checking, height: 46),
              const SizedBox(height: 8),
              AppButton(
                label: tr('verify.resend'),
                onPressed: _resend,
                loading: _sending,
                kind: AppButtonKind.neutral,
                height: 46,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading / error / data for one [future]. Keeps screens free of boilerplate.
class FutureView<T> extends StatelessWidget {
  const FutureView({super.key, required this.future, required this.onRetry, required this.builder});

  final Future<T> future;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingView();
        }
        if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: onRetry);
        return builder(context, snapshot.data as T);
      },
    );
  }
}
