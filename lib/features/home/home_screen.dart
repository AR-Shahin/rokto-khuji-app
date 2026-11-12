import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/dashboard.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/dashboard_service.dart';
import '../notifications/notifications_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/widgets/availability_card.dart';
import '../requests/request_detail_screen.dart';
import '../requests/widgets/request_card.dart';
import 'overdue_sheet.dart';

/// Dashboard: greeting, overdue alert, ready-to-donate switch, stats and new requests.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Switches the bottom tab (1 = find donors, 2 = requests).
  final ValueChanged<int> onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Dashboard? _data;
  Object? _error;

  /// The overdue sheet opens by itself once each time the app is opened.
  static bool _overdueShownThisLaunch = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<DashboardService>().fetch();
      if (!mounted) return;
      context.read<AuthProvider>().setUser(data.user);
      setState(() {
        _data = data;
        _error = null;
      });

      if (data.overdue.total > 0 && !_overdueShownThisLaunch) {
        _overdueShownThisLaunch = true;
        _openOverdue();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _openOverdue() async {
    final overdue = _data?.overdue;
    if (overdue == null) return;
    final changed = await showOverdueSheet(context, overdue);
    if (changed && mounted) _load();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      body: SafeArea(
        child: data == null
            ? (_error == null ? const LoadingView() : ErrorView(error: _error!, onRetry: _load))
            : RefreshIndicator(onRefresh: _load, child: _content(data)),
      ),
    );
  }

  Widget _content(Dashboard data) {
    final user = data.user;
    const gap = SizedBox(height: 14);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _Header(
          user: user,
          unread: data.unreadNotifications,
          onProfile: () => widget.onOpenTab(3),
          onBell: () => _open(const NotificationsScreen()),
        ),
        gap,
        if (!user.emailVerified) ...[
          _Banner(
            icon: Icons.mail_outline,
            color: AppColors.amber,
            background: AppColors.amberTint,
            title: tr('verify.title'),
            text: tr('verify.needed'),
            onTap: () => widget.onOpenTab(1),
          ),
          gap,
        ],
        if (data.overdue.total > 0) ...[
          _Banner(
            icon: Icons.warning_amber_rounded,
            color: Colors.white,
            background: AppColors.red,
            title: tr('overdue.banner', {'n': localizeDigits(data.overdue.total)}),
            text: tr('overdue.banner_text'),
            onTap: _openOverdue,
          ),
          gap,
        ],
        if (user.isDonor) ...[AvailabilityCard(user: user), gap],
        _Stats(user: user),
        gap,
        if (user.profileCompletion < 100) ...[
          _ProfileCompletion(user: user, onComplete: () => _open(const EditProfileScreen())),
          gap,
        ],
        Row(
          children: [
            Expanded(child: _QuickAction(Icons.search, tr('nav.find'), () => widget.onOpenTab(1))),
            const SizedBox(width: 12),
            Expanded(child: _QuickAction(Icons.inbox_outlined, tr('nav.requests'), () => widget.onOpenTab(2))),
          ],
        ),
        if (user.isDonor) ...[
          const SizedBox(height: 18),
          SectionTitle(tr('home.new_requests'), actionLabel: tr('common.see_all'), onAction: () => widget.onOpenTab(2)),
          const SizedBox(height: 6),
          if (data.newRequests.isEmpty)
            AppCard(
              child: Text(
                tr('home.no_new_requests'),
                textAlign: TextAlign.center,
                style: AppFonts.body(size: 15, color: AppColors.muted),
              ),
            )
          else
            for (final request in data.newRequests)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestCard(
                  request: request,
                  onTap: () => _open(RequestDetailScreen(requestId: request.id)),
                ),
              ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user, required this.unread, required this.onProfile, required this.onBell});

  final User user;
  final int unread;
  final VoidCallback onProfile;
  final VoidCallback onBell;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('home.good_morning');
    if (hour < 17) return tr('home.good_afternoon');
    return tr('home.good_evening');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfile,
          child: UserAvatar(name: user.name, photoUrl: user.photoUrl, size: 46),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: AppFonts.body(size: 14, color: AppColors.muted)),
              Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.heading(size: 20)),
            ],
          ),
        ),
        IconButton(
          onPressed: onBell,
          tooltip: tr('notifications.title'),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(localizeDigits(unread > 99 ? '99+' : unread)),
            child: const Icon(Icons.notifications_none, size: 26),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.body(weight: FontWeight.w700, color: color),
                    ),
                    Text(text, style: AppFonts.body(size: 13.5, color: color)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label, {bool latin = false, Color color = AppColors.text}) {
      return Expanded(
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: latin ? AppFonts.latin(size: 22, color: color) : AppFonts.heading(size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppFonts.body(size: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
    }

    final rating = user.isDonor ? user.ratingAsDonor : user.ratingAsRequester;
    return Row(
      children: [
        stat(user.bloodGroup?.name ?? '-', tr('home.blood_group'), latin: true, color: AppColors.red),
        const SizedBox(width: 10),
        stat(localizeDigits(user.totalDonations), tr('home.donations')),
        const SizedBox(width: 10),
        stat(rating > 0 ? localizeDigits(rating.toStringAsFixed(1)) : '-', tr('home.rating')),
      ],
    );
  }
}

class _ProfileCompletion extends StatelessWidget {
  const _ProfileCompletion({required this.user, required this.onComplete});

  final User user;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('home.profile_done', {'n': localizeDigits(user.profileCompletion)}),
                  style: AppFonts.body(weight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onComplete, child: Text(tr('home.complete_profile'))),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: user.profileCompletion / 100,
              minHeight: 8,
              backgroundColor: AppColors.redTint,
            ),
          ),
          if (user.missingFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tr('home.missing', {'fields': user.missingFields.join(', ')}),
              style: AppFonts.body(size: 13, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.red),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: AppFonts.body(weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
