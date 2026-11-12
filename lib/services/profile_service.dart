import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/json.dart';
import '../models/paged.dart';
import '../models/review.dart';
import '../models/testimonial.dart';
import '../models/user.dart';

/// A saved profile and the message to show.
class ProfileUpdate {
  const ProfileUpdate({required this.user, this.message});

  final User user;
  final String? message;
}

/// Everything under /me: profile, photo, password, reviews, story.
class ProfileService {
  const ProfileService(this._api);

  final ApiClient _api;

  /// Send only the fields that changed.
  Future<ProfileUpdate> update(Json fields) async {
    final result = await _api.patch('/me', body: fields);
    return ProfileUpdate(user: User.fromJson(result.map), message: result.message);
  }

  /// bio, facebook, instagram, twitter, linkedin, youtube, website
  Future<ProfileUpdate> updateSocial(Json fields) async {
    final result = await _api.put('/me/social', body: fields);
    return ProfileUpdate(user: User.fromJson(result.map), message: result.message);
  }

  /// JPG or PNG, up to 2 MB.
  Future<String?> uploadPhoto(String filePath) async {
    final result = await _api.upload('/me/photo', field: 'photo', filePath: filePath);
    return result.message;
  }

  Future<void> deletePhoto() => _api.delete('/me/photo');

  /// The "ready to donate" switch.
  Future<String?> setAvailability(bool isAvailable) async {
    final result = await _api.patch('/me/availability', body: {'is_available': isAvailable});
    return result.message;
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final result = await _api.put(
      '/me/password',
      body: {'current_password': currentPassword, 'password': newPassword, 'password_confirmation': confirmation},
    );
    return result.message;
  }

  /// Link that opens the Telegram bot. Null when already linked or not set up.
  Future<String?> telegramConnectUrl() async {
    final result = await _api.get('/me/telegram');
    return asString(result.map['connect_url']);
  }

  Future<void> deleteAccount(String password) {
    return _api.delete('/me', body: {'password': password});
  }

  /// [as]: donor / requester
  Future<Paged<Review>> reviews({required String as, int page = 1}) async {
    final result = await _api.get('/me/reviews', query: {'as': as, 'page': page, 'per_page': AppConfig.pageSize});
    return Paged.fromApi(result.list, result.meta, Review.fromJson);
  }

  /// Null when the user has not shared a story yet.
  Future<Testimonial?> testimonial() async {
    final result = await _api.get('/me/testimonial');
    final data = asJson(result.data);
    return data == null ? null : Testimonial.fromJson(data);
  }

  Future<String?> submitTestimonial(String content) async {
    final result = await _api.post('/me/testimonial', body: {'content': content});
    return result.message;
  }
}
