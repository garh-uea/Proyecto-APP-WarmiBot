import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_environment.dart';
import 'secure_token_store.dart';

const skipAuthKey = 'skipAuth';
const skipRefreshKey = 'skipRefresh';
const skipRetryKey = 'skipRetry';
const authRetriedKey = 'authRetried';
const retryAttemptKey = 'retryAttempt';
const idempotentKey = 'idempotent';

class NetworkTrace {
  final String message;
  final DateTime occurredAt;

  const NetworkTrace(this.message, this.occurredAt);
}

class NetworkDiagnostics {
  NetworkDiagnostics._();
  static final NetworkDiagnostics instance = NetworkDiagnostics._();

  final ValueNotifier<NetworkTrace?> trace = ValueNotifier(null);

  void record(String message) {
    if (ApiEnvironment.diagnosticsEnabled) {
      trace.value = NetworkTrace(message, DateTime.now());
    }
  }
}

class ApiClient {
  ApiClient._({
    required Dio dio,
    required this.tokenStore,
    required Uri baseUri,
  }) : _dio = dio {
    _configure(baseUri);
  }

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._production();

  factory ApiClient.forTesting({
    required Dio dio,
    TokenStore? tokenStore,
    String baseUrl = 'http://10.0.2.2:8000',
  }) =>
      ApiClient._(
        dio: dio,
        tokenStore: tokenStore ?? MemoryTokenStore(),
        baseUri: Uri.parse(baseUrl),
      );

  ApiClient._production()
      : _dio = Dio(),
        tokenStore = SecureTokenStore.instance {
    _configure(ApiEnvironment.baseUri);
  }

  final Dio _dio;
  final TokenStore tokenStore;

  Dio get dio => _dio;

  void _configure(Uri baseUri) {
    _dio.options = BaseOptions(
      baseUrl: baseUri.toString(),
      connectTimeout: ApiEnvironment.connectTimeout,
      sendTimeout: ApiEnvironment.sendTimeout,
      receiveTimeout: ApiEnvironment.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    );
    _dio.interceptors.clear();
    _dio.interceptors.addAll([
      _AuthenticationInterceptor(tokenStore, baseUri),
      _AutomaticRefreshInterceptor(_dio, tokenStore, baseUri),
      _IdempotentRetryInterceptor(_dio),
      if (ApiEnvironment.diagnosticsEnabled) _SafeDevelopmentLogInterceptor(),
    ]);
  }
}

class _AuthenticationInterceptor extends Interceptor {
  final TokenStore _store;
  final Uri _baseUri;

  _AuthenticationInterceptor(this._store, this._baseUri);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuthKey] != true && _isOwnApi(options.uri)) {
      final tokens = await _store.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  bool _isOwnApi(Uri uri) =>
      uri.scheme == _baseUri.scheme &&
      uri.host == _baseUri.host &&
      uri.port == _baseUri.port;
}

class _AutomaticRefreshInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final TokenStore _store;
  final Uri _baseUri;
  Future<StoredTokens?>? _activeRefresh;

  _AutomaticRefreshInterceptor(this._dio, this._store, this._baseUri);

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    final request = error.requestOptions;
    final shouldRefresh = error.response?.statusCode == 401 &&
        request.extra[skipRefreshKey] != true &&
        request.extra[authRetriedKey] != true &&
        _isOwnApi(request.uri);
    if (!shouldRefresh) return handler.next(error);

    final refreshed = await _refreshOnce();
    if (refreshed == null) return handler.next(error);

    try {
      final retried = request.copyWith(
        headers: Map<String, dynamic>.from(request.headers)
          ..['Authorization'] = 'Bearer ${refreshed.accessToken}',
        extra: Map<String, dynamic>.from(request.extra)
          ..[authRetriedKey] = true,
      );
      final response = await _dio.fetch<dynamic>(retried);
      NetworkDiagnostics.instance.record(
        'HTTP 401 interceptado → token renovado → petición reintentada con HTTP ${response.statusCode}',
      );
      handler.resolve(response);
    } on DioException {
      handler.next(error);
    }
  }

  Future<StoredTokens?> _refreshOnce() {
    final active = _activeRefresh;
    if (active != null) return active;
    final future = _performRefresh();
    _activeRefresh = future;
    future.whenComplete(() {
      if (identical(_activeRefresh, future)) _activeRefresh = null;
    });
    return future;
  }

  Future<StoredTokens?> _performRefresh() async {
    final current = await _store.read();
    if (current == null) return null;
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': current.refreshToken},
        options: Options(extra: {
          skipAuthKey: true,
          skipRefreshKey: true,
          skipRetryKey: true,
        }),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final refreshed = StoredTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      await _store.write(refreshed);
      return refreshed;
    } on DioException {
      return null;
    }
  }

  bool _isOwnApi(Uri uri) =>
      uri.scheme == _baseUri.scheme &&
      uri.host == _baseUri.host &&
      uri.port == _baseUri.port;
}

class _IdempotentRetryInterceptor extends Interceptor {
  final Dio _dio;
  _IdempotentRetryInterceptor(this._dio);

  static const _maxRetries = 2;
  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    final request = error.requestOptions;
    final attempt = request.extra[retryAttemptKey] as int? ?? 0;
    if (request.extra[skipRetryKey] == true ||
        attempt >= _maxRetries ||
        !_canRetry(request) ||
        !_isTransient(error)) {
      return handler.next(error);
    }

    await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
    try {
      final retried = request.copyWith(
        extra: Map<String, dynamic>.from(request.extra)
          ..[retryAttemptKey] = attempt + 1,
      );
      handler.resolve(await _dio.fetch<dynamic>(retried));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _canRetry(RequestOptions request) {
    if (_idempotentMethods.contains(request.method.toUpperCase())) {
      return true;
    }
    if (request.extra[idempotentKey] != true || request.data is! Map) {
      return false;
    }
    final clientId = (request.data as Map)['client_id'];
    return clientId is String && clientId.isNotEmpty;
  }

  bool _isTransient(DioException error) =>
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      (error.response?.statusCode ?? 0) >= 500;
}

class _SafeDevelopmentLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[HTTP] ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[HTTP] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint(
        '[HTTP] ${error.response?.statusCode ?? 'sin respuesta'} ${error.requestOptions.uri}');
    handler.next(error);
  }
}
