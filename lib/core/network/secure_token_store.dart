import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredTokens {
  final String accessToken;
  final String refreshToken;

  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
  });
}

abstract interface class TokenStore {
  Future<StoredTokens?> read();
  Future<void> write(StoredTokens tokens);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore._();

  static final SecureTokenStore instance = SecureTokenStore._();
  static const accessKey = 'auth_access_token';
  static const refreshKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<StoredTokens?> read() async {
    final access = await _storage.read(key: accessKey);
    final refresh = await _storage.read(key: refreshKey);
    if (access == null || refresh == null) return null;
    return StoredTokens(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> write(StoredTokens tokens) async {
    await _storage.write(key: accessKey, value: tokens.accessToken);
    await _storage.write(key: refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: accessKey);
    await _storage.delete(key: refreshKey);
  }
}

class MemoryTokenStore implements TokenStore {
  StoredTokens? value;

  MemoryTokenStore([this.value]);

  @override
  Future<void> clear() async => value = null;

  @override
  Future<StoredTokens?> read() async => value;

  @override
  Future<void> write(StoredTokens tokens) async => value = tokens;
}
