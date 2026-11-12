import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/widgets/state_views.dart';
import '../../models/blood_request.dart';
import '../../services/blood_request_service.dart';
import 'incoming_request_view.dart';
import 'my_request_view.dart';

/// Opens any blood request. Shows the requester view for my own request,
/// otherwise the donor view (accept / decline / complete).
class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final int requestId;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  BloodRequest? _request;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final request = await context.read<BloodRequestService>().details(widget.requestId);
      if (mounted) setState(() => _request = request);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Actions return the fresh request; the donor view needs a reload
  /// because `my_response` is only filled by the detail endpoint.
  void _update(BloodRequest? fresh) {
    if (fresh != null && fresh.isMine) {
      setState(() => _request = fresh);
    } else {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return Scaffold(
      appBar: AppBar(title: Text(request?.isMine ?? false ? tr('detail.my_title') : tr('detail.title'))),
      body: request == null
          ? (_error == null ? const LoadingView() : ErrorView(error: _error!, onRetry: _load))
          : RefreshIndicator(
              onRefresh: _load,
              child: request.isMine
                  ? MyRequestView(request: request, onChanged: _update)
                  : IncomingRequestView(request: request, onChanged: _update),
            ),
    );
  }
}
