/// Small helpers for reading API JSON safely (no code generation needed).
typedef Json = Map<String, dynamic>;

Json? asJson(dynamic value) => value is Map ? value.cast<String, dynamic>() : null;

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? fallback;
}

double? asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}

bool asBool(dynamic value) => value == true || value == 1 || value == '1';

String? asString(dynamic value) {
  final text = value?.toString();
  return (text == null || text.isEmpty) ? null : text;
}

DateTime? asDate(dynamic value) => value == null ? null : DateTime.tryParse(value.toString());

List<T> asList<T>(dynamic value, T Function(Json json) fromJson) {
  if (value is! List) return <T>[];
  return value.whereType<Map>().map((item) => fromJson(item.cast<String, dynamic>())).toList();
}
