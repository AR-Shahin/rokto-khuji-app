import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/donor.dart';
import '../../providers/auth_provider.dart';
import '../../services/donor_service.dart';
import '../profile/widgets/review_tile.dart';
import '../requests/create_request_screen.dart';

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key, required this.donorId});

  final int donorId;

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  late Future<DonorDetails> _future = _load();

  Future<DonorDetails> _load() => context.read<DonorService>().details(widget.donorId);

  @override
  void didUpdateWidget(covariant DonorProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.donorId != widget.donorId) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRequest = context.watch<AuthProvider>().user?.isConsumer ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(tr('donor.title'))),
      body: FutureView<DonorDetails>(
        future: _future,
        onRetry: () => setState(() {
          _future = _load();
        }),
        builder: (context, details) {
          final d = details.donor;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _ProfileCard(donor: d),
                    const SizedBox(height: 14),
                    _ContactCard(donor: d),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tr('donor.reviews', {'n': localizeDigits(d.reviewCount)}),
                            style: AppFonts.heading(),
                          ),
                        ),
                        if (d.rating != null) ...[
                          const Icon(Icons.star_rounded, color: AppColors.star),
                          Text(
                            localizeDigits(d.rating!.toStringAsFixed(1)),
                            style: AppFonts.body(weight: FontWeight.w700),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (details.recentReviews.isEmpty)
                      Text(tr('donor.no_reviews'), style: AppFonts.body(size: 15, color: AppColors.muted)),
                    for (final review in details.recentReviews)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReviewTile(review: review),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: tr('common.call'),
                          kind: AppButtonKind.neutral,
                          icon: Icons.phone_outlined,
                          onPressed: d.phone == null ? null : () => callPhone(d.phone),
                        ),
                      ),
                      if (canRequest) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: tr('donor.send_request'),
                            icon: Icons.send_outlined,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(builder: (_) => CreateRequestScreen(area: d.area)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.donor});

  final Donor donor;

  @override
  Widget build(BuildContext context) {
    final d = donor;
    final line = [
      if (d.area != null) d.area!.label,
      if (d.gender != null) tr('gender.${d.gender}'),
      if (d.age != null) tr('donor.age', {'n': localizeDigits(d.age!)}),
    ].join(' · ');

    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(value, style: AppFonts.heading(size: 20)),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppFonts.body(size: 13, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          UserAvatar(name: d.name, photoUrl: d.photoUrl, size: 88),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(d.name, textAlign: TextAlign.center, style: AppFonts.heading(size: 22)),
              ),
              if (d.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 20, color: AppColors.blue),
              ],
            ],
          ),
          if (line.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              line,
              textAlign: TextAlign.center,
              style: AppFonts.body(size: 14, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              if (d.bloodGroup != null) AppBadge(tr('donor.group_donor', {'group': d.bloodGroup}), tone: BadgeTone.red),
              d.isAvailable
                  ? AppBadge(tr('donor.ready'), tone: BadgeTone.green)
                  : AppBadge(tr('donor.resting'), tone: BadgeTone.gray),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              stat(localizeDigits(d.totalDonations), tr('home.donations')),
              stat(d.rating == null ? '-' : localizeDigits(d.rating!.toStringAsFixed(1)), tr('home.rating')),
              stat(d.lastDonationDate == null ? '-' : formatDate(d.lastDonationDate), tr('donor.last_donation')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.donor});

  final Donor donor;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (donor.phone != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.phone_outlined, color: AppColors.green),
          title: Text(localizeDigits(donor.phone!)),
          onTap: () => callPhone(donor.phone),
        ),
      if (donor.whatsappNumber != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.chat_outlined, color: AppColors.green),
          title: Text('WhatsApp: ${localizeDigits(donor.whatsappNumber!)}'),
          onTap: () => openWhatsApp(donor.whatsappNumber),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('donor.contact'), style: AppFonts.body(weight: FontWeight.w700)),
          ...rows,
        ],
      ),
    );
  }
}
