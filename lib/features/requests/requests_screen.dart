import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/widgets/paged_list_view.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../models/blood_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/blood_request_service.dart';
import 'request_detail_screen.dart';
import 'widgets/request_card.dart';

enum _Tab { incoming, mine }

/// Two lists: requests sent to me (as donor) and requests I sent (as requester).
/// Only the tabs that fit the user's role are shown.
class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  _Tab? _tab;
  String? _incomingFilter; // null = all
  String _mineFilter = 'active';

  /// Bumped to reload the list after coming back from a detail screen.
  int _reload = 0;

  static const _incomingFilters = [null, 'pending', 'accepted', 'completed', 'declined'];
  static const _mineFilters = ['active', 'closed', 'canceled'];

  Future<void> _openDetail(BloodRequest request) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => RequestDetailScreen(requestId: request.id)));
    if (mounted) setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tabs = <_Tab, String>{
      if (user?.isDonor ?? true) _Tab.incoming: tr('requests.incoming'),
      if (user?.isConsumer ?? true) _Tab.mine: tr('requests.mine'),
    };
    final tab = tabs.containsKey(_tab) ? _tab! : tabs.keys.first;
    final service = context.read<BloodRequestService>();

    return Scaffold(
      appBar: AppBar(title: Text(tr('nav.requests'))),
      body: Column(
        children: [
          if (tabs.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedTabs<_Tab>(
                options: tabs,
                selected: tab,
                onChanged: (value) => setState(() => _tab = value),
              ),
            ),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: tab == _Tab.incoming
                  ? [
                      for (final f in _incomingFilters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SelectChip(
                            label: f == null ? tr('filter.all') : tr('response.$f'),
                            selected: _incomingFilter == f,
                            onTap: () => setState(() => _incomingFilter = f),
                          ),
                        ),
                    ]
                  : [
                      for (final f in _mineFilters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SelectChip(
                            label: tr('filter.$f'),
                            selected: _mineFilter == f,
                            onTap: () => setState(() => _mineFilter = f),
                          ),
                        ),
                    ],
            ),
          ),
          Expanded(
            child: tab == _Tab.incoming
                ? PagedListView<BloodRequest>(
                    key: ValueKey('incoming-$_incomingFilter-$_reload'),
                    fetch: (page) => service.incoming(status: _incomingFilter, page: page),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    emptyTitle: tr('requests.empty_incoming'),
                    emptyMessage: tr('requests.empty_incoming_text'),
                    itemBuilder: (context, r) => RequestCard(request: r, onTap: () => _openDetail(r)),
                  )
                : PagedListView<BloodRequest>(
                    key: ValueKey('mine-$_mineFilter-$_reload'),
                    fetch: (page) => service.mine(status: _mineFilter, page: page),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    emptyTitle: tr('requests.empty_mine'),
                    emptyMessage: tr('requests.empty_mine_text'),
                    itemBuilder: (context, r) => RequestCard(request: r, onTap: () => _openDetail(r)),
                  ),
          ),
        ],
      ),
    );
  }
}
