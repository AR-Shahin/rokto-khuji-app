import '../core/network/api_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  const DashboardService(this._api);

  final ApiClient _api;

  Future<Dashboard> fetch() async {
    final result = await _api.get('/dashboard');
    return Dashboard.fromJson(result.map);
  }
}
