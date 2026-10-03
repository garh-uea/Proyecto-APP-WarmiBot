import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/core/network/api_client.dart';
import 'package:warmibot/core/network/secure_token_store.dart';
import 'package:warmibot/domain/services/backend_api_service.dart';

import 'support/callback_http_adapter.dart';

BackendApiService _service(
  Future<TestHttpResponse> Function(RequestOptions request) callback, {
  TokenStore? tokenStore,
}) {
  final client = ApiClient.forTesting(
    dio: testDio(callback),
    tokenStore: tokenStore,
  );
  return BackendApiService(client: client);
}

void main() {
  test('consulta /health y valida una respuesta saludable', () async {
    final service = _service((request) async {
      expect(request.uri.toString(), 'http://10.0.2.2:8000/health');
      expect(request.headers['Accept'], 'application/json');
      return const TestHttpResponse(
        200,
        {'status': 'ok', 'environment': 'test'},
      );
    });

    final result = await service.checkHealth();

    expect(result.isHealthy, isTrue);
    expect(result.environment, 'test');
  });

  test('rechaza respuestas no saludables aunque sean HTTP 200', () async {
    final service = _service(
      (_) async => const TestHttpResponse(200, {'status': 'error'}),
    );
    expect(service.checkHealth, throwsA(isA<BackendApiException>()));
  });

  test('rechaza una URL base que no sea HTTP o HTTPS', () {
    expect(
      () => BackendApiService(baseUrl: 'ftp://servidor'),
      throwsArgumentError,
    );
  });

  test('login envía formulario OAuth2 y reconoce HTTP 401', () async {
    final service = _service((request) async {
      expect(request.path, '/api/v1/auth/login');
      expect(request.contentType, Headers.formUrlEncodedContentType);
      expect((request.data as Map)['username'], 'estudiante@uea.edu.ec');
      return const TestHttpResponse(
        401,
        {'detail': 'Correo o contraseña incorrectos'},
      );
    });

    expect(
      () => service.login(
        email: 'estudiante@uea.edu.ec',
        password: 'incorrecta',
      ),
      throwsA(
        isA<BackendApiException>()
            .having((error) => error.statusCode, 'statusCode', 401)
            .having((error) => error.isUnauthorized, 'isUnauthorized', isTrue),
      ),
    );
  });

  test('distingue HTTP 403 sin confundirlo con sesión expirada', () async {
    final service = _service(
      (_) async => const TestHttpResponse(
        403,
        {'detail': 'La cuenta está desactivada'},
      ),
    );

    expect(
      () => service.login(
        email: 'estudiante@uea.edu.ec',
        password: 'una-clave-valida',
      ),
      throwsA(
        isA<BackendApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having((error) => error.isForbidden, 'isForbidden', isTrue)
            .having(
              (error) => error.isUnauthorized,
              'isUnauthorized',
              isFalse,
            ),
      ),
    );
  });

  test('renueva el token una vez y reintenta la petición que recibió 401',
      () async {
    final store = MemoryTokenStore(const StoredTokens(
      accessToken: 'vencido',
      refreshToken: 'refresh-vigente',
    ));
    var protectedCalls = 0;
    var refreshCalls = 0;
    final service = _service((request) async {
      if (request.path == '/api/v1/auth/refresh') {
        refreshCalls++;
        return const TestHttpResponse(200, {
          'access_token': 'nuevo-access',
          'refresh_token': 'nuevo-refresh',
          'expires_in': 60,
          'token_type': 'bearer',
          'user': null,
        });
      }
      protectedCalls++;
      if (request.headers['Authorization'] == 'Bearer vencido') {
        return const TestHttpResponse(401, {'detail': 'Token expirado'});
      }
      expect(request.headers['Authorization'], 'Bearer nuevo-access');
      return const TestHttpResponse(200, {'resultado': 'real'});
    }, tokenStore: store);

    final result = await service.getProtectedObject('/api/v1/protegido');

    expect(result['resultado'], 'real');
    expect(refreshCalls, 1);
    expect(protectedCalls, 2);
    expect((await store.read())?.refreshToken, 'nuevo-refresh');
  });

  test('traduce HTTP 422 y conserva errores asociados a campos', () async {
    final store = MemoryTokenStore(const StoredTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
    ));
    final service = _service(
      (_) async => const TestHttpResponse(422, {
        'detail': [
          {
            'loc': ['body', 'client_id'],
            'msg': 'String should have at least 10 characters',
          },
          {
            'loc': ['body', 'base_version'],
            'msg': 'Input should be greater than or equal to 0',
          },
        ],
      }),
      tokenStore: store,
    );

    expect(
      service.forceValidation422Demo,
      throwsA(
        isA<BackendApiException>()
            .having((error) => error.statusCode, 'statusCode', 422)
            .having(
              (error) => error.family,
              'family',
              ApiFailureFamily.validation,
            )
            .having(
              (error) => error.fieldErrors.keys,
              'fields',
              containsAll(['client_id', 'base_version']),
            ),
      ),
    );
  });
}
