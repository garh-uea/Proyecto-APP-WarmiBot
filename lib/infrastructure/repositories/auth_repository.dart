import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/alarm_service.dart';
import '../../domain/services/backend_api_service.dart';
import 'reminders_repository.dart';

class AuthSession {
  final BackendUser user;
  final String accessToken;
  final String refreshToken;

  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthRepository {
  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userKey = 'auth_cached_user';

  final BackendApiService api;
  final FlutterSecureStorage storage;

  AuthRepository({
    BackendApiService? api,
    FlutterSecureStorage? storage,
  })  : api = api ?? BackendApiService(),
        storage = storage ?? const FlutterSecureStorage();

  Future<AuthSession?> restore() async {
    final access = await storage.read(key: _accessKey);
    final refresh = await storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    final cachedUser = await _readCachedUser();

    try {
      final user = await api.currentUser(access);
      await _saveUser(user);
      return AuthSession(
        user: user,
        accessToken: access,
        refreshToken: refresh,
      );
    } on BackendApiException catch (error) {
      if (error.isUnauthorized) {
        return _refreshSession(refresh, cachedUser: cachedUser);
      }
      if (error.statusCode == null && cachedUser != null) {
        return AuthSession(
          user: cachedUser,
          accessToken: access,
          refreshToken: refresh,
        );
      }
      rethrow;
    }
  }

  Future<AuthSession> signIn(String email, String password) async {
    final tokens = await api.login(email: email, password: password);
    final user = await api.currentUser(tokens.accessToken);
    await _save(tokens, user);
    return AuthSession(
      user: user,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<void> register({
    required String email,
    required String displayName,
    required String password,
  }) =>
      api.register(
        email: email,
        displayName: displayName,
        password: password,
      );

  Future<AuthSession?> renew(AuthSession session) =>
      _refreshSession(session.refreshToken, cachedUser: session.user);

  Future<AuthSession?> _refreshSession(
    String refreshToken, {
    BackendUser? cachedUser,
  }) async {
    try {
      final tokens = await api.refresh(refreshToken);
      final user = await api.currentUser(tokens.accessToken);
      await _save(tokens, user);
      return AuthSession(
        user: user,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on BackendApiException catch (error) {
      if (error.isUnauthorized) await clear();
      if (error.statusCode == null && cachedUser != null) {
        final access = await storage.read(key: _accessKey);
        if (access != null) {
          return AuthSession(
            user: cachedUser,
            accessToken: access,
            refreshToken: refreshToken,
          );
        }
      }
      return null;
    }
  }

  Future<void> signOut(AuthSession? session) async {
    if (session != null) {
      try {
        await api.logout(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
      } catch (_) {
        // El cierre local no debe quedar bloqueado por una API inaccesible.
      }
    }
    await clear();
    await RemindersRepository.instance.clearAllLocalData();
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    try {
      await AlarmService.instance.cancelAll();
    } catch (_) {
      // La limpieza de credenciales y SQLite ya se completó.
    }
  }

  Future<void> _save(AuthTokenPair tokens, BackendUser user) async {
    await storage.write(key: _accessKey, value: tokens.accessToken);
    await storage.write(key: _refreshKey, value: tokens.refreshToken);
    await _saveUser(user);
  }

  Future<void> _saveUser(BackendUser user) => storage.write(
        key: _userKey,
        value: jsonEncode(user.toJson()),
      );

  Future<BackendUser?> _readCachedUser() async {
    final encoded = await storage.read(key: _userKey);
    if (encoded == null) return null;
    try {
      return BackendUser.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await storage.deleteAll();
  }
}
