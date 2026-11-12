import 'json.dart';

class Area {
  const Area({
    required this.id,
    required this.name,
    this.type,
    this.parentId,
    this.breadcrumb,
    this.hasChildren = false,
  });

  factory Area.fromJson(Json json) {
    return Area(
      id: asInt(json['id']),
      name: asString(json['display_name']) ?? asString(json['name']) ?? '',
      type: asString(json['type']),
      parentId: json['parent_id'] == null ? null : asInt(json['parent_id']),
      breadcrumb: asString(json['breadcrumb']),
      hasChildren: asBool(json['has_children']),
    );
  }

  final int id;

  /// Name in the app language (the API picks Bangla or English).
  final String name;
  final String? type;
  final int? parentId;

  /// Full path, e.g. "Palakhal, Kachua, Chandpur". Not sent on every endpoint.
  final String? breadcrumb;
  final bool hasChildren;

  /// Best text to show for this area.
  String get label => breadcrumb ?? name;

  Area withBreadcrumb(String value) {
    return Area(id: id, name: name, type: type, parentId: parentId, breadcrumb: value, hasChildren: hasChildren);
  }
}
