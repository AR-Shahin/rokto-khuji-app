import 'package:material_ui/material_ui.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../services/blood_request_service.dart';
import 'request_detail_screen.dart';

class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key, required this.created});

  final CreatedRequest created;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(color: AppColors.greenTint, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 60, color: AppColors.green),
              ),
              const SizedBox(height: 24),
              Text(
                tr('sent.title'),
                textAlign: TextAlign.center,
                style: AppFonts.heading(size: 26, weight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                created.notifiedDonors > 0
                    ? tr('sent.text', {
                        'n': localizeDigits(created.notifiedDonors),
                        'group': created.request.bloodGroup ?? '',
                      })
                    : tr('sent.text_none'),
                textAlign: TextAlign.center,
                style: AppFonts.body(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.cell_tower, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(tr('sent.escalation'), style: AppFonts.body(size: 14, color: AppColors.blue)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: tr('sent.view'),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(builder: (_) => RequestDetailScreen(requestId: created.request.id)),
                ),
              ),
              const SizedBox(height: 10),
              AppButton(label: tr('sent.home'), kind: AppButtonKind.neutral, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
