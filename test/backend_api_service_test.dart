import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warmibot/domain/services/backend_api_service.dart';

void main() {
  test('consulta /health y valida una respuesta saludable', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'http://10.0.2.2:800/health');
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
}
