import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/user.dart';

/// Result of login / register.
class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final User user;
}

class AuthService {
  const AuthService(this._api);

  final ApiClient _api;

  Future<AuthSession> login({required String email, required String password}) async {
    final result = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password, 'device_name': AppConfig.deviceName},
    );
    return _session(result);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required int bloodGroupId,
    required String role,
    required int areaId,
  }) async {
    final result = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'blood_group_id': bloodGroupId,
        'role': role,
        'area_id': areaId,
        'device_name': AppConfig.deviceName,
      },
    );
    return _session(result);
  }

  /// Always returns the same message, whether the email exists or not.
  Future<String?> forgotPassword(String email) async {
    final result = await _api.post('/auth/forgot-password', body: {'email': email});
    return result.message;
  }

  Future<String?> resendVerificationEmail() async {
    final result = await _api.post('/auth/email/resend');
    return result.message;
  }

  Future<User> me() async {
    final result = await _api.get('/me');
    return User.fromJson(result.map);
  }

  Future<void> logout() => _api.post('/auth/logout');

  Future<void> logoutAll() => _api.post('/auth/logout-all');

  AuthSession _session(ApiResult result) {
    final data = result.map;
    return AuthSession(
      token: data['token'].toString(),
      user: User.fromJson((data['user'] as Map).cast<String, dynamic>()),
    );
  }
}
