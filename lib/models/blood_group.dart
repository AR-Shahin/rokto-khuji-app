import 'json.dart';

class BloodGroup {
  const BloodGroup({required this.id, required this.name});

  factory BloodGroup.fromJson(Json json) {
    return BloodGroup(id: asInt(json['id']), name: asString(json['name']) ?? '');
  }

  final int id;
  final String name;
}
