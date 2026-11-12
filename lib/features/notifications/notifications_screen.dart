import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../requests/request_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _reload = 0;

  NotificationService get _service => context.read<NotificationService>();

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() => _reload++);
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    }
  }

  /// Marks it read and opens the related request (if any).
  Future<void> _open(AppNotification n) async {
    if (!n.isRead) _service.markRead(n.id).ignore();

    final requestId = n.bloodRequestId;
    if (requestId != null) {
      await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => RequestDetailScreen(requestId: requestId)));
    }
    if (mounted) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(tr('notifications.title')),
        actions: [TextButton(onPressed: () => _run(_service.markAllRead), child: Text(tr('notifications.read_all')))],
      ),
      body: PagedListView<AppNotification>(
        key: ValueKey(_reload),
        fetch: (page) => _service.list(page: page),
        padding: EdgeInsets.zero,
        spacing: 0,
        emptyIcon: Icons.notifications_none,
        emptyTitle: tr('notifications.empty'),
        itemBuilder: (context, n) => _NotificationTile(
          notification: n,
          onTap: () => _open(n),
          onDelete: () => _run(() => _service.delete(n.id)),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap, required this.onDelete});

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// Icon and colors for each notification type.
  (IconData, Color, Color) get _style {
    return switch (notification.type) {
      'new_blood_request' => (Icons.water_drop, AppColors.red, AppColors.redTint),
      'donation_overdue' => (Icons.warning_amber_rounded, AppColors.amber, AppColors.amberTint),
      'donor_accepted' => (Icons.check_circle_outline, AppColors.green, AppColors.greenTint),
      'search_widened' || 'search_exhausted' => (Icons.cell_tower, AppColors.blue, AppColors.blueTint),
      _ => (Icons.notifications_none, AppColors.ink2, AppColors.grayTint),
    };
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (icon, color, tint) = _style;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.isRead ? Colors.white : AppColors.redTint.withValues(alpha: 0.35),
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.title != null)
                    Text(n.title!, style: AppFonts.body(weight: n.isRead ? FontWeight.w600 : FontWeight.w700)),
                  if (n.body != null) Text(n.body!, style: AppFonts.body(size: 14, color: AppColors.ink2)),
                  const SizedBox(height: 4),
                  Text(timeAgo(n.createdAt), style: AppFonts.body(size: 12.5, color: AppColors.muted)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.muted),
              onSelected: (_) => onDelete(),
              itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(tr('common.delete')))],
            ),
          ],
        ),
      ),
    );
  }
}
