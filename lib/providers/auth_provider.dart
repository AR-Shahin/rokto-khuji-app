import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// App just opened, we do not know yet.
  unknown,

  /// A token exists but the server could not be reached at startup.
  offline,
  guest,
  loggedIn,
}

/// Holds the logged-in user for the whole app.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService, required TokenStorage tokenStorage, required ApiClient apiClient})
    : _auth = authService,
      _tokens = tokenStorage {
    // The server rejected the token (expired, banned, logged out elsewhere).
    apiClient.onUnauthorized = _dropSession;
  }

  final AuthService _auth;
  final TokenStorage _tokens;

  AuthStatus status = AuthStatus.unknown;
  User? user;

  bool get isLoggedIn => status == AuthStatus.loggedIn;

  /// Run once when the app starts: restores the session if a token is saved.
  Future<void> bootstrap() async {
    status = AuthStatus.unknown;
    notifyListeners();

    final token = await _tokens.read();
    if (token == null) {
      status = AuthStatus.guest;
      notifyListeners();
      return;
    }

    try {
      user = await _auth.me();
      status = AuthStatus.loggedIn;
    } on ApiException catch (e) {
      status = e.isNetwork ? AuthStatus.offline : AuthStatus.guest;
      if (!e.isNetwork) await _tokens.clear();
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    await _startSession(await _auth.login(email: email, password: password));
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required int bloodGroupId,
    required String role,
    required int areaId,
  }) async {
    await _startSession(
      await _auth.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        bloodGroupId: bloodGroupId,
        role: role,
        areaId: areaId,
      ),
    );
  }

  /// Reloads the user from the server (e.g. after the email was verified).
  Future<void> refreshUser() async {
    user = await _auth.me();
    notifyListeners();
  }

  /// Use after an API call already returned the fresh user.
  void setUser(User value) {
    user = value;
    notifyListeners();
  }

  Future<void> logout({bool allDevices = false}) async {
    try {
      await (allDevices ? _auth.logoutAll() : _auth.logout());
    } on ApiException {
      // Even if the server call fails we still log out on this phone.
    }
    await _dropSession();
  }

  /// Use after the account was deleted: only local data is left to clear.
  Future<void> clearSession() => _dropSession();

  Future<void> _startSession(AuthSession session) async {
    await _tokens.save(session.token);
    user = session.user;
    status = AuthStatus.loggedIn;
    notifyListeners();
  }

  Future<void> _dropSession() async {
    if (status == AuthStatus.guest) return;
    await _tokens.clear();
    user = null;
    status = AuthStatus.guest;
    notifyListeners();
  }
}
