import 'package:material_ui/material_ui.dart';
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
import '../../core/widgets/blood_group_grid.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/state_views.dart';
import '../../models/area.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meta_provider.dart';
import '../../services/blood_request_service.dart';
import '../shared/area_picker_sheet.dart';
import 'request_sent_screen.dart';

/// Blood request form. The server sends it to matching donors in the area
/// and widens the area by itself if nobody answers in time.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, this.bloodGroupId, this.area});

  /// Pre-filled from the donor search.
  final int? bloodGroupId;
  final Area? area;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _hospital = TextEditingController();
  final _contact = TextEditingController();
  final _location = TextEditingController();
  final _reason = TextEditingController();
  final _note = TextEditingController();

  String _priority = 'urgent';
  late int? _bloodGroupId = widget.bloodGroupId;
  late Area? _area = widget.area;
  int _bags = 1;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  TimeOfDay? _time;

  bool _saving = false;
  bool _needsVerification = false;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    context.read<MetaProvider>().load();
    final user = context.read<AuthProvider>().user;
    _contact.text = user?.phone ?? '';
    _area ??= user?.area;
    _needsVerification = !(user?.emailVerified ?? true);
  }

  @override
  void dispose() {
    for (final c in [_patient, _hospital, _contact, _location, _reason, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickArea() async {
    final area = await showAreaPicker(context);
    if (area != null) setState(() => _area = area);
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await pickDate(context, initial: _date, first: today, last: today.add(const Duration(days: 90)));
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0));
    if (time != null) setState(() => _time = time);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    final missing = <String, String>{
      if (_bloodGroupId == null) 'blood_group_id': tr('register.pick_group'),
      if (_area == null) 'area_id': tr('register.pick_area'),
    };
    if (!formOk || missing.isNotEmpty) {
      setState(() => _errors = missing);
      return;
    }

    setState(() {
      _saving = true;
      _errors = {};
    });
    try {
      final created = await context.read<BloodRequestService>().create({
        'patient_name': _patient.text.trim(),
        'hospital_name': _hospital.text.trim(),
        'blood_group_id': _bloodGroupId,
        'area_id': _area!.id,
        'bags': _bags,
        'needed_date': apiDate(_date),
        if (_time != null) 'needed_time': '${_two(_time!.hour)}:${_two(_time!.minute)}',
        'contact_number': _contact.text.trim(),
        'priority': _priority,
        'location': _location.text.trim(),
        'reason': _reason.text.trim(),
        'note': _note.text.trim(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => RequestSentScreen(created: created)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errors = e.errors;
        _needsVerification = e.isEmailNotVerified;
      });
      if (e.errors.isEmpty && !e.isEmailNotVerified) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needsVerification) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('request.title'))),
        body: VerifyEmailNotice(onVerified: () => setState(() => _needsVerification = false)),
      );
    }

    final groups = context.watch<MetaProvider>().bloodGroups;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(tr('request.title'))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _InfoBox(text: tr('request.info')),
                    gap,
                    FieldLabel(tr('field.priority')),
                    const SizedBox(height: 8),
                    SegmentedTabs<String>(
                      options: {
                        'regular': tr('priority.regular'),
                        'urgent': tr('priority.urgent'),
                        'critical': tr('priority.critical'),
                      },
                      selected: _priority,
                      onChanged: (value) => setState(() => _priority = value),
                    ),
                    gap,
                    FieldLabel(tr('field.blood_group'), isRequired: true),
                    const SizedBox(height: 8),
                    BloodGroupGrid(
                      groups: groups,
                      selectedId: _bloodGroupId,
                      onSelected: (id) => setState(() => _bloodGroupId = id),
                    ),
                    _error('blood_group_id'),
                    gap,
                    PickerField(
                      label: tr('field.area'),
                      value: _area?.label,
                      hint: tr('register.pick_area'),
                      icon: Icons.place_outlined,
                      isRequired: true,
                      errorText: _errors['area_id'],
                      onTap: _pickArea,
                    ),
                    gap,
                    AppTextField(
                      label: tr('field.patient'),
                      controller: _patient,
                      icon: Icons.person_outline,
                      hint: tr('request.patient_hint'),
                      isRequired: true,
                      errorText: _errors['patient_name'],
                      validator: Validators.required,
                    ),
                    gap,
                    AppTextField(
                      label: tr('field.hospital'),
                      controller: _hospital,
                      icon: Icons.local_hospital_outlined,
                      hint: tr('request.hospital_hint'),
                      isRequired: true,
                      errorText: _errors['hospital_name'],
                      validator: Validators.required,
                    ),
                    gap,
                    _BagStepper(value: _bags, onChanged: (value) => setState(() => _bags = value)),
                    _error('bags'),
                    gap,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PickerField(
                            label: tr('field.date'),
                            value: formatDate(_date),
                            icon: Icons.calendar_today_outlined,
                            isRequired: true,
                            errorText: _errors['needed_date'],
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PickerField(
                            label: tr('field.time'),
                            value: _time?.format(context),
                            hint: tr('common.optional'),
                            icon: Icons.schedule,
                            errorText: _errors['needed_time'],
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    gap,
                    AppTextField(
                      label: tr('field.contact'),
                      controller: _contact,
                      icon: Icons.phone_outlined,
                      helper: tr('request.contact_help'),
                      isRequired: true,
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      errorText: _errors['contact_number'],
                      validator: Validators.phone,
                    ),
                    gap,
                    AppTextField(
                      label: tr('field.location'),
                      controller: _location,
                      icon: Icons.pin_drop_outlined,
                      hint: tr('request.location_hint'),
                      errorText: _errors['location'],
                    ),
                    gap,
                    AppTextField(
                      label: tr('field.reason'),
                      controller: _reason,
                      hint: tr('request.reason_hint'),
                      errorText: _errors['reason'],
                    ),
                    gap,
                    AppTextField(
                      label: tr('field.note'),
                      controller: _note,
                      hint: tr('request.note_hint'),
                      maxLines: 3,
                      maxLength: 1000,
                      errorText: _errors['note'],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: AppButton(
                label: tr('request.submit'),
                icon: Icons.send_outlined,
                loading: _saving,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String field) {
    final error = _errors[field];
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(error, style: AppFonts.body(size: 12.5, color: AppColors.redDark)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.redTint, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cell_tower, color: AppColors.redDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppFonts.body(size: 14, color: AppColors.redDark)),
          ),
        ],
      ),
    );
  }
}

/// "Bags: − 2 +" (1 to 10).
class _BagStepper extends StatelessWidget {
  const _BagStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap) {
      return IconButton.outlined(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(side: const BorderSide(color: AppColors.border, width: 1.5)),
      );
    }

    return Row(
      children: [
        Expanded(child: FieldLabel(tr('field.bags'), isRequired: true)),
        button(Icons.remove, value > 1 ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 48,
          child: Text(localizeDigits(value), textAlign: TextAlign.center, style: AppFonts.heading(size: 22)),
        ),
        button(Icons.add, value < 10 ? () => onChanged(value + 1) : null),
      ],
    );
  }
}
