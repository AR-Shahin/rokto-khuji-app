import 'package:material_ui/material_ui.dart';

import '../../models/paged.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../utils/ui_helpers.dart';
import 'state_views.dart';

/// A list that loads page by page as the user scrolls (uses `meta.has_more`),
/// with pull-to-refresh, empty state and error state built in.
///
/// To reload from outside (e.g. a filter changed), give it a new `key`.
class PagedListView<T> extends StatefulWidget {
  const PagedListView({
    super.key,
    required this.fetch,
    required this.itemBuilder,
    required this.emptyTitle,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
    this.onFirstPage,
  });

  final Future<Paged<T>> Function(int page) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final EdgeInsets padding;
  final double spacing;

  /// Called every time page 1 arrives (handy for showing the total).
  final ValueChanged<Paged<T>>? onFirstPage;

  @override
  State<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends State<PagedListView<T>> {
  final List<T> _items = [];
  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadNextPage();
  }

  Future<void> _refresh() => _loadNextPage(restart: true);

  Future<void> _loadNextPage({bool restart = false}) async {
    if (_loading) return;
    if (!restart && !_hasMore) return;

    final page = restart ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.fetch(page);
      if (!mounted) return;
      setState(() {
        if (restart) _items.clear();
        _items.addAll(result.items);
        _page = page;
        _hasMore = result.hasMore;
      });
      if (page == 1) widget.onFirstPage?.call(result);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 300 && _error == null) {
      _loadNextPage();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_loading) return const LoadingView();
      if (_error != null) return ErrorView(error: _error!, onRetry: _refresh);
      return MessageView(
        icon: widget.emptyIcon,
        title: widget.emptyTitle,
        message: widget.emptyMessage,
        actionLabel: tr('common.refresh'),
        onAction: _refresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: _items.length + 1,
          separatorBuilder: (_, _) => SizedBox(height: widget.spacing),
          itemBuilder: (context, index) {
            if (index < _items.length) {
              return widget.itemBuilder(context, _items[index]);
            }
            return _footer();
          },
        ),
      ),
    );
  }

  /// Last row: spinner while loading more, retry when a page failed.
  Widget _footer() {
    if (_error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadNextPage,
          icon: const Icon(Icons.refresh, color: AppColors.red),
          label: Text(errorMessage(_error!)),
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
  }
}
