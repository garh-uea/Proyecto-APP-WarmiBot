import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_environment.dart';
import '../../core/network/api_failure.dart';
import '../../core/network/secure_token_store.dart';
import '../../infrastructure/models/backend_models.dart';

export '../../core/network/api_failure.dart' show ApiFailureFamily;
export '../../infrastructure/models/backend_models.dart';

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

class BackendApiException extends ApiFailure {
  const BackendApiException(
    String message, {
    super.statusCode,
    super.payload,
    super.fieldErrors,
    super.family = ApiFailureFamily.validation,
  }) : super(message: message);

  factory BackendApiException.fromFailure(ApiFailure failure) =>
      BackendApiException(
        failure.message,
        statusCode: failure.statusCode,
        payload: failure.payload,
        fieldErrors: failure.fieldErrors,
        family: failure.family,
      );
}

class BackendApiService {
  static const defaultBaseUrl = 'http://10.0.2.2:8000';

  final ApiClient _client;
  final Uri baseUri;

  BackendApiService({ApiClient? client, String? baseUrl})
      : baseUri = _parseBaseUrl(baseUrl ?? ApiEnvironment.baseUri.toString()),
        _client = client ??
            (baseUrl == null
                ? ApiClient.instance
                : ApiClient.forTesting(
                    dio: Dio(),
                    baseUrl: _parseBaseUrl(baseUrl).toString(),
                  ));

  static Uri _parseBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(value, 'baseUrl', 'URL HTTP(S) no válida');
    }
    if ((ApiEnvironment.isProduction || ApiEnvironment.isReleaseBuild) &&
        uri.scheme != 'https') {
      throw ArgumentError.value(value, 'baseUrl', 'Producción exige HTTPS');
    }
    return uri;
  }

  Future<BackendHealth> checkHealth() async {
    final data = await _get('/health', public: true);
    if (data['status'] != 'ok') {
      throw const BackendApiException(
        'La respuesta de /health no tiene el formato esperado.',
      );
    }
    return BackendHealth(
      status: data['status'] as String,
      environment: data['environment']?.toString() ?? 'desconocido',
      endpoint: baseUri.replace(path: '${baseUri.path}/health'),
    );
  }

  Future<BackendUser> register({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final data = await _post(
      '/api/v1/auth/register',
      public: true,
      body: {
        'email': email.trim(),
        'display_name': displayName.trim(),
        'password': password,
      },
    );
    return BackendUser.fromJson(data);
  }

  Future<AuthTokenPair> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<dynamic>(
        '/api/v1/auth/login',
        data: {'username': email.trim(), 'password': password},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          extra: const {
            skipAuthKey: true,
            skipRefreshKey: true,
            skipRetryKey: true,
          },
        ),
      );
      return AuthTokenPair.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw BackendApiException.fromFailure(ApiFailureMapper.fromDio(error));
    }
  }

  Future<AuthTokenPair> refresh(String refreshToken) async {
    final data = await _post(
      '/api/v1/auth/refresh',
      public: true,
      disableRefresh: true,
      body: {'refresh_token': refreshToken},
    );
    return AuthTokenPair.fromJson(data);
  }

  Future<BackendUser> currentUser([String? _]) async =>
      BackendUser.fromJson(await _get('/api/v1/auth/me'));

  Future<Map<String, dynamic>> getProtectedObject(
    String path, [
    String? _,
  ]) =>
      _get(path);

  Future<void> logout({
    String? accessToken,
    required String refreshToken,
  }) async {
    await _post('/api/v1/auth/logout', body: {'refresh_token': refreshToken});
  }

  Future<List<BackendReminder>> listReminders([String? _]) async {
    try {
      final response = await _client.dio.get<dynamic>('/api/v1/reminders');
      final data = response.data;
      if (data is! List) {
        throw const BackendApiException(
          'La API devolvió una lista de recordatorios no válida.',
        );
      }
      return data.map((item) => BackendReminder.fromJson(_map(item))).toList();
    } on DioException catch (error) {
      throw BackendApiException.fromFailure(ApiFailureMapper.fromDio(error));
    }
  }

  Future<BackendReminder> syncReminder({
    String? accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final data = await _post(
      '/api/v1/reminders/sync',
      body: payload,
      idempotent: true,
    );
    return BackendReminder.fromJson(data);
  }

  Future<BackendUser> forceAutomaticRefreshDemo() async {
    if (!ApiEnvironment.diagnosticsEnabled) {
      throw const BackendApiException(
        'La demostración de renovación solo está disponible en desarrollo.',
      );
    }
    final previous = await _client.tokenStore.read();
    if (previous == null) {
      throw const BackendApiException('No existe una sesión para renovar.');
    }
    await _client.tokenStore.write(StoredTokens(
      accessToken: 'access-token-expirado-para-demostracion',
      refreshToken: previous.refreshToken,
    ));
    try {
      return await currentUser();
    } catch (_) {
      await _client.tokenStore.write(previous);
      rethrow;
    }
  }

  Future<void> forceValidation422Demo() async {
    await _post(
      '/api/v1/reminders/sync',
      body: {
        'client_id': 'corto',
        'operation': 'upsert',
        'text': 'Validación controlada',
        'scheduled_at': DateTime.now().toUtc().toIso8601String(),
        'reminder_type': 'reminder',
        'is_completed': false,
        'base_version': -1,
        'client_updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      idempotent: true,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool public = false,
  }) async {
    try {
      final response = await _client.dio.get<dynamic>(
        path,
        options: Options(extra: {
          if (public) skipAuthKey: true,
          if (public) skipRefreshKey: true,
        }),
      );
      return _map(response.data);
    } on DioException catch (error) {
      throw BackendApiException.fromFailure(ApiFailureMapper.fromDio(error));
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    bool public = false,
    bool disableRefresh = false,
    bool idempotent = false,
  }) async {
    try {
      final response = await _client.dio.post<dynamic>(
        path,
        data: body,
        options: Options(extra: {
          if (public) skipAuthKey: true,
          if (public || disableRefresh) skipRefreshKey: true,
          if (!idempotent) skipRetryKey: true,
          if (idempotent) idempotentKey: true,
        }),
      );
      if (response.statusCode == 204 || response.data == null) return const {};
      return _map(response.data);
    } on DioException catch (error) {
      throw BackendApiException.fromFailure(ApiFailureMapper.fromDio(error));
    }
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const BackendApiException('La API devolvió un formato inesperado.');
  }

  void close() {
    // Dio es compartido por toda la aplicación y no se cierra por pantalla.
  }
}
