import 'json.dart';

/// One page of a list endpoint.
class Paged<T> {
  const Paged({required this.items, required this.hasMore, required this.total, this.meta = const {}});

  factory Paged.fromApi(List<dynamic> data, Json meta, T Function(Json json) fromJson) {
    return Paged(
      items: asList(data, fromJson),
      hasMore: asBool(meta['has_more']),
      total: asInt(meta['total']),
      meta: meta,
    );
  }

  final List<T> items;
  final bool hasMore;
  final int total;

  /// Full `meta` object, for endpoints that send extra info (e.g. review summary).
  final Json meta;
}
