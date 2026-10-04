import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/secure_token_store.dart';
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
  static const _userKey = 'auth_cached_user';

  final BackendApiService api;
  final FlutterSecureStorage storage;
  final TokenStore tokenStore;

  AuthRepository({
    BackendApiService? api,
    FlutterSecureStorage? storage,
    TokenStore? tokenStore,
  })  : api = api ?? BackendApiService(),
        storage = storage ?? const FlutterSecureStorage(),
        tokenStore = tokenStore ?? SecureTokenStore.instance;

  Future<AuthSession?> restore() async {
    final stored = await tokenStore.read();
    if (stored == null) return null;
    final access = stored.accessToken;
    final refresh = stored.refreshToken;
    final cachedUser = await _readCachedUser();

    try {
      final user = await api.currentUser(access);
      await _saveUser(user);
      final current = await tokenStore.read() ?? stored;
      return AuthSession(
        user: user,
        accessToken: current.accessToken,
        refreshToken: current.refreshToken,
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
    await tokenStore.write(StoredTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    ));
    final user = tokens.user ?? await api.currentUser();
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
      await tokenStore.write(StoredTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      ));
      final user = tokens.user ?? await api.currentUser();
      await _save(tokens, user);
      return AuthSession(
        user: user,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    } on BackendApiException catch (error) {
      if (error.isUnauthorized) await clear();
      if (error.statusCode == null && cachedUser != null) {
        final stored = await tokenStore.read();
        if (stored != null) {
          return AuthSession(
            user: cachedUser,
            accessToken: stored.accessToken,
            refreshToken: stored.refreshToken,
          );
        }
      }
      return null;
    }
  }

  Future<void> signOut(AuthSession? session) async {
    if (session != null) {
      try {
        final stored = await tokenStore.read();
        await api.logout(
          refreshToken: stored?.refreshToken ?? session.refreshToken,
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
    await tokenStore.write(StoredTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    ));
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
    await tokenStore.clear();
    await storage.deleteAll();
  }
}
