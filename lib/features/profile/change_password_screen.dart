import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../services/profile_service.dart';

/// Other phones are logged out after the change; this one stays logged in.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errors = {};
    });
    try {
      final message = await context.read<ProfileService>().changePassword(
        currentPassword: _current.text,
        newPassword: _password.text,
        confirmation: _confirm.text,
      );
      if (!mounted) return;
      showSuccess(context, message);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.errors);
      if (e.errors.isEmpty) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings.change_password'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
              label: tr('field.current_password'),
              controller: _current,
              icon: Icons.lock_outline,
              obscureText: true,
              errorText: _errors['current_password'],
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: tr('field.new_password'),
              controller: _password,
              icon: Icons.lock_reset,
              obscureText: true,
              hint: tr('field.password_hint'),
              errorText: _errors['password'],
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: tr('field.password_confirm'),
              controller: _confirm,
              icon: Icons.lock_reset,
              obscureText: true,
              validator: Validators.sameAs(() => _password.text),
            ),
            const SizedBox(height: 24),
            AppButton(label: tr('common.save'), loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
