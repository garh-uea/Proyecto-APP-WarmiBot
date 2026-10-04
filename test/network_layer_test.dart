import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/core/network/api_client.dart';
import 'package:warmibot/core/network/api_failure.dart';
import 'package:warmibot/core/network/secure_token_store.dart';
import 'package:warmibot/domain/services/backend_api_service.dart';

import 'support/callback_http_adapter.dart';

void main() {
  group('serialización generada', () {
    test('traduce snake_case del servidor al modelo de usuario', () {
      final user = BackendUser.fromJson(const {
        'id': 12,
        'email': 'grupo12@uea.edu.ec',
        'display_name': 'Grupo 12',
        'role': 'user',
        'is_active': true,
        'created_at': '2026-09-12T12:00:00Z',
      });

      expect(user.displayName, 'Grupo 12');
      expect(user.isActive, isTrue);
      expect(user.toJson()['display_name'], 'Grupo 12');
    });

    test('traduce campos y fechas del recordatorio', () {
      final reminder = BackendReminder.fromJson(const {
        'id': 8,
        'client_id': 'cliente-unico-123',
        'text': 'Exponer WarmiBot',
        'scheduled_at': '2026-09-12T14:00:00Z',
        'reminder_type': 'reminder',
        'is_completed': false,
        'deleted': false,
        'version': 2,
        'client_updated_at': '2026-09-12T13:00:00Z',
        'updated_at': '2026-09-12T13:00:01Z',
      });

      expect(reminder.clientId, 'cliente-unico-123');
      expect(reminder.scheduledAt.isUtc, isTrue);
      expect(reminder.toJson()['reminder_type'], 'reminder');
    });
  });

  group('cuatro familias de fallo', () {
    final request = RequestOptions(path: '/prueba');

    test('conectividad', () {
      final failure = ApiFailureMapper.fromDio(DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      ));
      expect(failure.family, ApiFailureFamily.connectivity);
    });

    test('tiempo de espera', () {
      final failure = ApiFailureMapper.fromDio(DioException(
        requestOptions: request,
        type: DioExceptionType.receiveTimeout,
      ));
      expect(failure.family, ApiFailureFamily.timeout);
    });

    test('servidor', () {
      final failure = ApiFailureMapper.fromDio(DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 503,
          data: const {'detail': 'No disponible'},
        ),
        type: DioExceptionType.badResponse,
      ));
      expect(failure.family, ApiFailureFamily.server);
    });

    test('validación', () {
      final failure = ApiFailureMapper.fromDio(DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 422,
          data: const {
            'detail': [
              {
                'loc': ['body', 'text'],
                'msg': 'Campo obligatorio',
              }
            ],
          },
        ),
        type: DioExceptionType.badResponse,
      ));
      expect(failure.family, ApiFailureFamily.validation);
      expect(failure.fieldErrors['text'], 'Campo obligatorio');
    });
  });

  test('reintenta POST solo si es idempotente y lleva client_id', () async {
    var calls = 0;
    final dio = testDio((_) async {
      calls++;
      if (calls == 1) {
        return const TestHttpResponse(503, {'detail': 'Temporal'});
      }
      return const TestHttpResponse(200, {
        'id': 1,
        'client_id': 'cliente-unico-123',
        'text': 'Exponer',
        'scheduled_at': '2026-09-12T14:00:00Z',
        'reminder_type': 'reminder',
        'is_completed': false,
        'deleted': false,
        'version': 1,
        'client_updated_at': '2026-09-12T13:00:00Z',
        'updated_at': '2026-09-12T13:00:01Z',
      });
    });
    final client = ApiClient.forTesting(
      dio: dio,
      tokenStore: MemoryTokenStore(const StoredTokens(
        accessToken: 'access',
        refreshToken: 'refresh',
      )),
    );
    final service = BackendApiService(client: client);

    await service.syncReminder(payload: {
      'client_id': 'cliente-unico-123',
      'operation': 'upsert',
    });

    expect(calls, 2);
  });
}
