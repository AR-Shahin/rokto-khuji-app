import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/blood_group_grid.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/area.dart';
import '../../models/json.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meta_provider.dart';
import '../../services/profile_service.dart';
import '../shared/area_picker_sheet.dart';

/// Edit everything on the profile. Only changed fields are sent to the API.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _socialFields = ['facebook', 'instagram', 'twitter', 'linkedin', 'youtube', 'website'];

  final _formKey = GlobalKey<FormState>();
  late final User _user = context.read<AuthProvider>().user!;

  late final _name = TextEditingController(text: _user.name);
  late final _email = TextEditingController(text: _user.email);
  late final _phone = TextEditingController(text: _user.phone);
  late final _secondaryPhone = TextEditingController(text: _user.secondaryPhone);
  late final _whatsapp = TextEditingController(text: _user.whatsappNumber);
  late final _telegram = TextEditingController(text: _user.telegramNumber);
  late final _bio = TextEditingController(text: asString(_user.social['bio']));
  late final Map<String, TextEditingController> _social = {
    for (final field in _socialFields) field: TextEditingController(text: asString(_user.social[field])),
  };

  late String? _gender = _user.gender;
  late DateTime? _dateOfBirth = _user.dateOfBirth;
  late DateTime? _lastDonation = _user.lastDonationDate;
  late int? _bloodGroupId = _user.bloodGroup?.id;
  late Area? _area = _user.area;

  bool _saving = false;
  bool _photoBusy = false;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    context.read<MetaProvider>().load();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _secondaryPhone, _whatsapp, _telegram, _bio, ..._social.values]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- Photo ----------------------------------------------------------------

  Future<void> _changePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85, // keeps it well under the 2 MB limit
    );
    if (file == null || !mounted) return;

    await _photoAction(() => context.read<ProfileService>().uploadPhoto(file.path));
  }

  Future<void> _removePhoto() async {
    await _photoAction(() async {
      await context.read<ProfileService>().deletePhoto();
      return null;
    });
  }

  Future<void> _photoAction(Future<String?> Function() action) async {
    setState(() => _photoBusy = true);
    try {
      final message = await action();
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (mounted) showSuccess(context, message ?? tr('profile.saved'));
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  // ---- Save -------------------------------------------------------------------

  /// Only the fields whose value is different from the current profile.
  Json _changedFields() {
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    String? date(DateTime? d) => d == null ? null : apiDate(d);

    final current = <String, Object?>{
      'name': _user.name,
      'email': _user.email,
      'phone': _user.phone,
      'secondary_phone': _user.secondaryPhone,
      'whatsapp_number': _user.whatsappNumber,
      'telegram_number': _user.telegramNumber,
      'gender': _user.gender,
      'date_of_birth': date(_user.dateOfBirth),
      'last_donation_date': date(_user.lastDonationDate),
      'blood_group_id': _user.bloodGroup?.id,
      'area_id': _user.area?.id,
    };
    final edited = <String, Object?>{
      'name': text(_name),
      'email': text(_email),
      'phone': text(_phone),
      'secondary_phone': text(_secondaryPhone),
      'whatsapp_number': text(_whatsapp),
      'telegram_number': text(_telegram),
      'gender': _gender,
      'date_of_birth': date(_dateOfBirth),
      'last_donation_date': date(_lastDonation),
      'blood_group_id': _bloodGroupId,
      'area_id': _area?.id,
    };

    return {
      for (final entry in edited.entries)
        if (entry.value != current[entry.key]) entry.key: entry.value,
    };
  }

  Json _changedSocial() {
    final edited = <String, Object?>{
      'bio': _bio.text.trim(),
      for (final field in _socialFields) field: _social[field]!.text.trim(),
    };
    final changed = edited.entries.any((e) => (e.value ?? '') != (asString(_user.social[e.key]) ?? ''));
    // PUT replaces the whole block, so send every social field when one changed.
    return changed ? {for (final e in edited.entries) e.key: (e.value as String).isEmpty ? null : e.value} : {};
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fields = _changedFields();
    final social = _changedSocial();
    if (fields.isEmpty && social.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _errors = {};
    });
    final service = context.read<ProfileService>();
    final auth = context.read<AuthProvider>();
    try {
      String? message;
      if (fields.isNotEmpty) {
        final result = await service.update(fields);
        auth.setUser(result.user);
        message = result.message;
      }
      if (social.isNotEmpty) {
        final result = await service.updateSocial(social);
        auth.setUser(result.user);
        message ??= result.message;
      }
      if (!mounted) return;
      showSuccess(context, message);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.errors);
      showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user ?? _user;
    final groups = context.watch<MetaProvider>().bloodGroups;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(tr('profile.edit'))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _PhotoPicker(
                      user: user,
                      busy: _photoBusy,
                      onChange: _changePhoto,
                      onRemove: user.photoUrl == null ? null : _removePhoto,
                    ),
                    _section(tr('profile.basic')),
                    AppTextField(
                      label: tr('field.name'),
                      controller: _name,
                      icon: Icons.person_outline,
                      isRequired: true,
                      errorText: _errors['name'],
                      validator: Validators.required,
                    ),
                    gap,
                    AppTextField(
                      label: tr('field.email'),
                      controller: _email,
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      helper: tr('profile.email_help'),
                      errorText: _errors['email'],
                      validator: Validators.email,
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Center(
                          widthFactor: 1,
                          child: user.emailVerified
                              ? AppBadge(tr('profile.verified'), tone: BadgeTone.green)
                              : AppBadge(tr('profile.not_verified'), tone: BadgeTone.amber),
                        ),
                      ),
                    ),
                    gap,
                    FieldLabel(tr('field.gender')),
                    const SizedBox(height: 8),
                    SegmentedTabs<String?>(
                      options: {'male': tr('gender.male'), 'female': tr('gender.female'), 'other': tr('gender.other')},
                      selected: _gender,
                      onChanged: (value) => setState(() => _gender = value),
                    ),
                    gap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PickerField(
                            label: tr('field.dob'),
                            value: _dateOfBirth == null ? null : formatDate(_dateOfBirth),
                            hint: tr('common.choose'),
                            icon: Icons.cake_outlined,
                            errorText: _errors['date_of_birth'],
                            onTap: () async {
                              final d = await pickDate(
                                context,
                                initial: _dateOfBirth ?? DateTime(2000),
                                last: DateTime.now(),
                              );
                              if (d != null) setState(() => _dateOfBirth = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PickerField(
                            label: tr('field.last_donation'),
                            value: _lastDonation == null ? null : formatDate(_lastDonation),
                            hint: tr('common.choose'),
                            icon: Icons.water_drop_outlined,
                            errorText: _errors['last_donation_date'],
                            onTap: () async {
                              final d = await pickDate(context, initial: _lastDonation, last: DateTime.now());
                              if (d != null) setState(() => _lastDonation = d);
                            },
                          ),
                        ),
                      ],
                    ),
                    gap,
                    FieldLabel(tr('field.blood_group'), isRequired: true),
                    const SizedBox(height: 8),
                    BloodGroupGrid(
                      groups: groups,
                      selectedId: _bloodGroupId,
                      onSelected: (id) => setState(() => _bloodGroupId = id),
                    ),
                    gap,
                    PickerField(
                      label: tr('field.area'),
                      value: _area?.label,
                      icon: Icons.place_outlined,
                      isRequired: true,
                      errorText: _errors['area_id'],
                      onTap: () async {
                        final area = await showAreaPicker(context);
                        if (area != null) setState(() => _area = area);
                      },
                    ),
                    _section(tr('profile.phones')),
                    _phoneField(tr('field.phone'), _phone, 'phone', isRequired: true),
                    gap,
                    _phoneField(tr('field.secondary_phone'), _secondaryPhone, 'secondary_phone'),
                    gap,
                    _phoneField(tr('field.whatsapp'), _whatsapp, 'whatsapp_number'),
                    gap,
                    _phoneField(tr('field.telegram'), _telegram, 'telegram_number'),
                    _section(tr('profile.about')),
                    AppTextField(
                      label: tr('field.bio'),
                      controller: _bio,
                      hint: tr('profile.bio_hint'),
                      maxLines: 3,
                      maxLength: 500,
                      errorText: _errors['bio'],
                    ),
                    for (final field in _socialFields) ...[
                      gap,
                      AppTextField(
                        label: tr('social.$field'),
                        controller: _social[field],
                        icon: Icons.link,
                        hint: 'https://',
                        keyboardType: TextInputType.url,
                        errorText: _errors[field],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: AppButton(label: tr('profile.save'), icon: Icons.check, loading: _saving, onPressed: _save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(title, style: AppFonts.heading()),
    );
  }

  Widget _phoneField(String label, TextEditingController controller, String field, {bool isRequired = false}) {
    return AppTextField(
      label: label,
      controller: controller,
      icon: Icons.phone_outlined,
      hint: isRequired ? null : tr('common.optional'),
      isRequired: isRequired,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      errorText: _errors[field],
      validator: isRequired ? Validators.phone : Validators.optionalPhone,
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.user, required this.busy, required this.onChange, this.onRemove});

  final User user;
  final bool busy;
  final VoidCallback onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 96),
            if (busy) const CircularProgressIndicator(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: busy ? null : onChange,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(tr('profile.change_photo')),
            ),
            if (onRemove != null)
              TextButton(
                onPressed: busy ? null : onRemove,
                child: Text(tr('common.delete'), style: const TextStyle(color: AppColors.muted)),
              ),
          ],
        ),
        Text(tr('profile.photo_help'), style: AppFonts.body(size: 12.5, color: AppColors.muted)),
      ],
    );
  }
}
