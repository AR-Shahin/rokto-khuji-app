import '../core/network/api_client.dart';
import '../models/area.dart';
import '../models/blood_group.dart';
import '../models/json.dart';

/// Public lookups: blood groups and the area tree.
class MetaService {
  const MetaService(this._api);

  final ApiClient _api;

  Future<List<BloodGroup>> bloodGroups() async {
    final result = await _api.get('/meta');
    return asList(result.map['blood_groups'], BloodGroup.fromJson);
  }

  /// Divisions when [parentId] is null, otherwise the children of that area.
  Future<List<Area>> areas({int? parentId}) async {
    final result = await _api.get('/areas', query: {'parent_id': parentId});
    return asList(result.list, Area.fromJson);
  }

  /// Needs at least 2 letters. Works with Bangla and English names.
  Future<List<Area>> searchAreas(String text) async {
    final result = await _api.get('/areas/search', query: {'q': text});
    return asList(result.list, Area.fromJson);
  }
}
