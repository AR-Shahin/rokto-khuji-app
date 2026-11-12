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
import '../../core/widgets/organization_credit.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _hidePassword = true;
  bool _loading = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errors = {};
    });
    try {
      await context.read<AuthProvider>().login(email: _email.text.trim(), password: _password.text);
      // AppRoot switches to the home screen; close the screens opened from Welcome.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.errors);
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
              const Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.water_drop, size: 34, color: AppColors.red),
              ),
              const SizedBox(height: 12),
              Text(tr('login.title'), style: AppFonts.heading(size: 28, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(tr('login.subtitle'), style: AppFonts.body(color: AppColors.muted)),
              const SizedBox(height: 28),
              AppTextField(
                label: tr('field.email'),
                controller: _email,
                icon: Icons.mail_outline,
                hint: 'example@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _errors['email'],
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: tr('field.password'),
                controller: _password,
                icon: Icons.lock_outline,
                hint: '••••••••',
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                errorText: _errors['password'],
                validator: Validators.required,
                suffix: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  tooltip: tr('field.show_password'),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen())),
                  child: Text(tr('login.forgot')),
                ),
              ),
              const SizedBox(height: 8),
              AppButton(label: tr('login.submit'), onPressed: _submit, loading: _loading),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(tr('login.new_user'), style: AppFonts.body(color: AppColors.muted)),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
                    ),
                    child: Text(tr('welcome.register')),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const OrganizationCredit(),
            ],
          ),
        ),
      ),
    );
  }
}
