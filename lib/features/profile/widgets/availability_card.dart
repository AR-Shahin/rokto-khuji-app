import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_card.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/profile_service.dart';

/// The "Ready to donate" switch with the last / next donation date.
class AvailabilityCard extends StatefulWidget {
  const AvailabilityCard({super.key, required this.user});

  final User user;

  @override
  State<AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends State<AvailabilityCard> {
  late bool _available = widget.user.isAvailable;
  bool _saving = false;

  @override
  void didUpdateWidget(AvailabilityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving) _available = widget.user.isAvailable;
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _available = value; // update right away, undo if the call fails
      _saving = true;
    });
    try {
      final message = await context.read<ProfileService>().setAvailability(value);
      if (!mounted) return;
      showSuccess(context, message);
      await context.read<AuthProvider>().refreshUser();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _available = !value);
      showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    final String dateLine;
    if (user.lastDonationDate == null) {
      dateLine = tr('availability.never');
    } else if (!user.canDonateNow && user.nextDonationDate != null) {
      dateLine = tr('availability.next', {
        'last': formatDate(user.lastDonationDate),
        'next': formatDate(user.nextDonationDate),
      });
    } else {
      dateLine = tr('availability.last', {'last': formatDate(user.lastDonationDate)});
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.greenTint, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.favorite_border, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('availability.title'), style: AppFonts.body(weight: FontWeight.w700)),
                    Text(
                      _available ? tr('availability.on') : tr('availability.off'),
                      style: AppFonts.body(size: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Switch(value: _available, onChanged: _saving ? null : _toggle),
            ],
          ),
          const Divider(height: 22),
          IconLine(Icons.calendar_today_outlined, dateLine),
        ],
      ),
    );
  }
}
