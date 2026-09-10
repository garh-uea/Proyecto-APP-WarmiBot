import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warmibot/domain/services/backend_api_service.dart';

void main() {
  test('consulta /health y valida una respuesta saludable', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://10.0.2.2:8000/health');
      expect(request.headers['Accept'], 'application/json');
      return http.Response(
        jsonEncode({'status': 'ok', 'environment': 'test'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = BackendApiService(client: client);

    final result = await service.checkHealth();

    expect(result.isHealthy, isTrue);
    expect(result.environment, 'test');
  });

  test('rechaza respuestas no saludables aunque sean HTTP 200', () async {
    final service = BackendApiService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'status': 'error'}), 200),
      ),
    );

    expect(
      service.checkHealth,
      throwsA(isA<BackendApiException>()),
    );
  });

  test('rechaza una URL base que no sea HTTP o HTTPS', () {
    expect(
      () => BackendApiService(baseUrl: 'ftp://servidor'),
      throwsArgumentError,
    );
  });

  test('login envía formulario OAuth2 y reconoce HTTP 401', () async {
    final service = BackendApiService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        expect(request.headers['Content-Type'],
            contains('application/x-www-form-urlencoded'));
        expect(request.bodyFields['username'], 'estudiante@uea.edu.ec');
        return http.Response(
          jsonEncode({'detail': 'Correo o contraseña incorrectos'}),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

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
    final service = BackendApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'La cuenta está desactivada'}),
          403,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
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
            .having((error) => error.isUnauthorized, 'isUnauthorized', isFalse),
      ),
    );
  });
}
