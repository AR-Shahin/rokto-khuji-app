import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../services/auth_service.dart';

/// Sends the reset link by email. The link opens the website to set a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _loading = false;
  String? _sentMessage;
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _emailError = null;
    });
    try {
      final message = await context.read<AuthService>().forgotPassword(_email.text.trim());
      if (mounted) setState(() => _sentMessage = message ?? tr('forgot.sent'));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _emailError = e.errors['email']);
      if (e.errors.isEmpty) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(shape: const Border()),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.redTint, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.key_outlined, size: 30, color: AppColors.red),
              ),
              const SizedBox(height: 16),
              Text(tr('forgot.title'), style: AppFonts.heading(size: 26, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(tr('forgot.subtitle'), style: AppFonts.body(color: AppColors.muted)),
              const SizedBox(height: 24),
              AppTextField(
                label: tr('field.email'),
                controller: _email,
                icon: Icons.mail_outline,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                validator: Validators.email,
              ),
              const SizedBox(height: 20),
              AppButton(label: tr('forgot.submit'), icon: Icons.send_outlined, onPressed: _submit, loading: _loading),
              if (_sentMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.greenTint, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_sentMessage!, style: AppFonts.body(size: 15, color: AppColors.green)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('forgot.back'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
