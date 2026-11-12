import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/app_notification.dart';
import '../models/paged.dart';

class NotificationService {
  const NotificationService(this._api);

  final ApiClient _api;

  Future<Paged<AppNotification>> list({int page = 1}) async {
    final result = await _api.get('/me/notifications', query: {'page': page, 'per_page': AppConfig.pageSize});
    return Paged.fromApi(result.list, result.meta, AppNotification.fromJson);
  }

  Future<void> markRead(String id) => _api.post('/me/notifications/$id/read');

  Future<void> markAllRead() => _api.post('/me/notifications/read-all');

  Future<void> delete(String id) => _api.delete('/me/notifications/$id');

  /// Call these two when Firebase Cloud Messaging is added to the app.
  Future<void> registerDevice({required String fcmToken, required String platform}) {
    return _api.post(
      '/me/devices',
      body: {'token': fcmToken, 'platform': platform, 'device_name': AppConfig.deviceName},
    );
  }

  Future<void> removeDevice(String fcmToken) {
    return _api.delete('/me/devices', body: {'token': fcmToken});
  }
}
