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
import '../../core/widgets/blood_group_grid.dart';
import '../../models/area.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meta_provider.dart';
import '../shared/area_picker_sheet.dart';

/// Two steps on one screen: 1) basic info, 2) blood group, role and area.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepOneFields = {'name', 'email', 'phone', 'password'};

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 1;
  int? _bloodGroupId;
  String _role = 'both';
  Area? _area;
  bool _acceptedTerms = true;
  bool _hidePassword = true;
  bool _loading = false;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    context.read<MetaProvider>().load();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_formKey.currentState!.validate()) setState(() => _step = 2);
  }

  void _back() {
    if (_step == 2) {
      setState(() => _step = 1);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickArea() async {
    final area = await showAreaPicker(context);
    if (area != null) setState(() => _area = area);
  }

  Future<void> _submit() async {
    final missing = <String, String>{
      if (_bloodGroupId == null) 'blood_group_id': tr('register.pick_group'),
      if (_area == null) 'area_id': tr('register.pick_area'),
    };
    if (missing.isNotEmpty) {
      setState(() => _errors = missing);
      return;
    }
    if (!_acceptedTerms) {
      showError(context, ApiException(message: tr('register.accept_terms')));
      return;
    }

    setState(() {
      _loading = true;
      _errors = {};
    });
    try {
      await context.read<AuthProvider>().register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirm.text,
        bloodGroupId: _bloodGroupId!,
        role: _role,
        areaId: _area!.id,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errors = e.errors;
        // Errors in step 1 fields: go back so the user can see them.
        if (e.errors.keys.any(_stepOneFields.contains)) _step = 1;
      });
      if (e.errors.isEmpty) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 1);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('register.title')),
              Text(
                _step == 1 ? tr('register.step1') : tr('register.step2'),
                style: AppFonts.body(size: 13, color: AppColors.muted),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: _step / 2, backgroundColor: AppColors.redTint, minHeight: 4),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(padding: const EdgeInsets.all(20), children: _step == 1 ? _stepOne() : _stepTwo()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _step == 1
                    ? AppButton(label: tr('register.next'), onPressed: _next)
                    : AppButton(label: tr('register.submit'), onPressed: _submit, loading: _loading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _stepOne() {
    const gap = SizedBox(height: 16);
    return [
      AppTextField(
        label: tr('field.name'),
        controller: _name,
        icon: Icons.person_outline,
        hint: tr('field.name_hint'),
        isRequired: true,
        textInputAction: TextInputAction.next,
        errorText: _errors['name'],
        validator: Validators.required,
      ),
      gap,
      AppTextField(
        label: tr('field.email'),
        controller: _email,
        icon: Icons.mail_outline,
        hint: 'example@email.com',
        helper: tr('register.email_help'),
        isRequired: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        errorText: _errors['email'],
        validator: Validators.email,
      ),
      gap,
      AppTextField(
        label: tr('field.phone'),
        controller: _phone,
        icon: Icons.phone_outlined,
        hint: '01XXXXXXXXX',
        helper: tr('register.phone_help'),
        isRequired: true,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        maxLength: 11,
        errorText: _errors['phone'],
        validator: Validators.phone,
      ),
      gap,
      AppTextField(
        label: tr('field.password'),
        controller: _password,
        icon: Icons.lock_outline,
        hint: tr('field.password_hint'),
        isRequired: true,
        obscureText: _hidePassword,
        textInputAction: TextInputAction.next,
        errorText: _errors['password'],
        validator: Validators.password,
        suffix: IconButton(
          onPressed: () => setState(() => _hidePassword = !_hidePassword),
          icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
      gap,
      AppTextField(
        label: tr('field.password_confirm'),
        controller: _confirm,
        icon: Icons.lock_outline,
        isRequired: true,
        obscureText: _hidePassword,
        validator: Validators.sameAs(() => _password.text),
      ),
    ];
  }

  List<Widget> _stepTwo() {
    final groups = context.watch<MetaProvider>().bloodGroups;
    final roles = {
      'both': (tr('role.both'), tr('role.both_text')),
      'donor': (tr('role.donor'), tr('role.donor_text')),
      'consumer': (tr('role.consumer'), tr('role.consumer_text')),
    };

    return [
      FieldLabel(tr('field.blood_group'), isRequired: true),
      const SizedBox(height: 10),
      BloodGroupGrid(groups: groups, selectedId: _bloodGroupId, onSelected: (id) => setState(() => _bloodGroupId = id)),
      _errorLine('blood_group_id'),
      const SizedBox(height: 22),
      FieldLabel(tr('field.role'), isRequired: true),
      const SizedBox(height: 8),
      for (final entry in roles.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RoleOption(
            title: entry.value.$1,
            text: entry.value.$2,
            selected: _role == entry.key,
            onTap: () => setState(() => _role = entry.key),
          ),
        ),
      const SizedBox(height: 14),
      PickerField(
        label: tr('field.area'),
        value: _area?.label,
        hint: tr('register.pick_area'),
        icon: Icons.place_outlined,
        isRequired: true,
        errorText: _errors['area_id'],
        onTap: _pickArea,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(tr('register.area_help'), style: AppFonts.body(size: 12.5, color: AppColors.muted)),
      ),
      const SizedBox(height: 14),
      CheckboxListTile(
        value: _acceptedTerms,
        onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(tr('register.terms'), style: AppFonts.body(size: 14.5)),
      ),
    ];
  }

  Widget _errorLine(String field) {
    final error = _errors[field];
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(error, style: AppFonts.body(size: 12.5, color: AppColors.redDark)),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({required this.title, required this.text, required this.selected, required this.onTap});

  final String title;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.redTint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.red : AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.red : AppColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFonts.body(weight: FontWeight.w700)),
                  Text(text, style: AppFonts.body(size: 13.5, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
