import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BackendHealth {
  final String status;
  final String environment;
  final Uri endpoint;

  const BackendHealth({
    required this.status,
    required this.environment,
    required this.endpoint,
  });

  bool get isHealthy => status == 'ok';
}

class BackendApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? detail;
  final Map<String, dynamic>? payload;

  const BackendApiException(
    this.message, {
    this.statusCode,
    this.detail,
    this.payload,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;
}

class BackendApiService {
  static const defaultBaseUrl = 'http://10.0.2.2:8000';

  final http.Client _client;
  final bool _ownsClient;
  final Uri baseUri;
  final Duration timeout;

  BackendApiService({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 5),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        baseUri = _parseBaseUrl(baseUrl ?? _configuredBaseUrl());

  static String _configuredBaseUrl() {
    try {
      return dotenv.env['API_BASE_URL']?.trim().isNotEmpty == true
          ? dotenv.env['API_BASE_URL']!.trim()
          : defaultBaseUrl;
    } catch (_) {
      return defaultBaseUrl;
    }
  }

  static Uri _parseBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(value, 'baseUrl', 'URL HTTP(S) no válida');
    }
    return uri;
  }

  Future<BackendHealth> checkHealth() async {
    final endpoint = baseUri.replace(path: '${baseUri.path}/health');
    try {
      final response = await _client.get(endpoint,
          headers: const {'Accept': 'application/json'}).timeout(timeout);
      if (response.statusCode != 200) {
        throw BackendApiException(
          'El backend respondió con HTTP ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map<String, dynamic> || payload['status'] != 'ok') {
        throw const BackendApiException(
          'La respuesta de /health no tiene el formato esperado.',
        );
      }

      return BackendHealth(
        status: payload['status'] as String,
        environment: payload['environment']?.toString() ?? 'desconocido',
        endpoint: endpoint,
      );
    } on BackendApiException {
      rethrow;
    } catch (error) {
      throw BackendApiException('No se pudo conectar con $endpoint: $error');
    }
  }

  Future<BackendUser> register({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final response = await _send(
      'POST',
      '/api/v1/auth/register',
      body: {
        'email': email.trim(),
        'display_name': displayName.trim(),
        'password': password,
      },
    );
    return BackendUser.fromJson(_jsonObject(response));
  }

  Future<AuthTokenPair> login({
    required String email,
    required String password,
  }) async {
    final endpoint = _endpoint('/api/v1/auth/login');
    try {
      final response = await _client.post(
        endpoint,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'username': email.trim(), 'password': password},
      ).timeout(timeout);
      _throwForError(response);
      return AuthTokenPair.fromJson(_jsonObject(response));
    } on BackendApiException {
      rethrow;
    } catch (error) {
      throw BackendApiException('No se pudo conectar con $endpoint: $error');
    }
  }

  Future<AuthTokenPair> refresh(String refreshToken) async {
    final response = await _send(
      'POST',
      '/api/v1/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return AuthTokenPair.fromJson(_jsonObject(response));
  }

  Future<BackendUser> currentUser(String accessToken) async {
    final response = await _send(
      'GET',
      '/api/v1/auth/me',
      accessToken: accessToken,
    );
    return BackendUser.fromJson(_jsonObject(response));
  }

  Future<Map<String, dynamic>> getProtectedObject(
    String path,
    String accessToken,
  ) async {
    final response = await _send('GET', path, accessToken: accessToken);
    return _jsonObject(response);
  }

  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _send(
      'POST',
      '/api/v1/auth/logout',
      accessToken: accessToken,
      body: {'refresh_token': refreshToken},
    );
  }

  Future<List<BackendReminder>> listReminders(String accessToken) async {
    final response = await _send(
      'GET',
      '/api/v1/reminders',
      accessToken: accessToken,
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const BackendApiException(
        'La API devolvió una lista de recordatorios no válida.',
      );
    }
    return decoded
        .map((item) => BackendReminder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BackendReminder> syncReminder({
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _send(
      'POST',
      '/api/v1/reminders/sync',
      accessToken: accessToken,
      body: payload,
    );
    return BackendReminder.fromJson(_jsonObject(response));
  }

  Uri _endpoint(String path) => baseUri.replace(
        path: '${baseUri.path}${path.startsWith('/') ? path : '/$path'}',
      );

  Future<http.Response> _send(
    String method,
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
  }) async {
    final endpoint = _endpoint(path);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response =
              await _client.get(endpoint, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await _client
              .post(
                endpoint,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(timeout);
          break;
        default:
          throw ArgumentError.value(method, 'method', 'Método no soportado');
      }
      _throwForError(response);
      return response;
    } on BackendApiException {
      rethrow;
    } catch (error) {
      throw BackendApiException('No se pudo conectar con $endpoint: $error');
    }
  }

  static Map<String, dynamic> _jsonObject(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const BackendApiException('La API devolvió un formato inesperado.');
    }
    return decoded;
  }

  static void _throwForError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String? detail;
    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
        final rawDetail = decoded['detail'];
        detail = rawDetail is String
            ? rawDetail
            : rawDetail is Map<String, dynamic>
                ? rawDetail['message']?.toString()
                : rawDetail?.toString();
      }
    } catch (_) {}
    throw BackendApiException(
      detail ?? 'El backend respondió con HTTP ${response.statusCode}.',
      statusCode: response.statusCode,
      detail: detail,
      payload: payload,
    );
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class BackendReminder {
  final int id;
  final String clientId;
  final String text;
  final DateTime scheduledAt;
  final String reminderType;
  final bool isCompleted;
  final bool deleted;
  final int version;
  final DateTime clientUpdatedAt;
  final DateTime updatedAt;

  const BackendReminder({
    required this.id,
    required this.clientId,
    required this.text,
    required this.scheduledAt,
    required this.reminderType,
    required this.isCompleted,
    required this.deleted,
    required this.version,
    required this.clientUpdatedAt,
    required this.updatedAt,
  });

  factory BackendReminder.fromJson(Map<String, dynamic> json) =>
      BackendReminder(
        id: json['id'] as int,
        clientId: json['client_id'] as String,
        text: json['text'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        reminderType: json['reminder_type'] as String,
        isCompleted: json['is_completed'] as bool,
        deleted: json['deleted'] as bool,
        version: json['version'] as int,
        clientUpdatedAt: DateTime.parse(json['client_updated_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class BackendUser {
  final int id;
  final String email;
  final String displayName;
  final String role;
  final bool isActive;

  const BackendUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'display_name': displayName,
        'role': role,
        'is_active': isActive,
      };

  factory BackendUser.fromJson(Map<String, dynamic> json) => BackendUser(
        id: json['id'] as int,
        email: json['email'] as String,
        displayName: json['display_name'] as String,
        role: json['role'] as String,
        isActive: json['is_active'] as bool,
      );
}

class AuthTokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokenPair.fromJson(Map<String, dynamic> json) => AuthTokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresIn: json['expires_in'] as int,
      );
}
