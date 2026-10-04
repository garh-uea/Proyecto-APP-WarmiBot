import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/domain/services/weather_service.dart';

import 'support/callback_http_adapter.dart';

void main() {
  test('consulta Open-Meteo cuando no existe una clave de OpenWeather',
      () async {
    final client = testDio((request) async {
      if (request.uri.host == 'geocoding-api.open-meteo.com') {
        expect(request.uri.queryParameters['name'], 'Tena');
        return const TestHttpResponse(200, {
          'results': [
            {
              'name': 'Tena',
              'latitude': -0.9938,
              'longitude': -77.8129,
            }
          ],
        });
      }
      if (request.uri.host == 'api.open-meteo.com') {
        return const TestHttpResponse(200, {
          'current': {
            'temperature_2m': 24.5,
            'relative_humidity_2m': 86,
            'apparent_temperature': 26.1,
            'weather_code': 61,
            'wind_speed_10m': 5.4,
          },
        });
      }
      return const TestHttpResponse(500, {'detail': 'No esperado'});
    });

    final result = await WeatherService(client: client).getWeather('Tena');

    expect(result.city, 'Tena');
    expect(result.tempC, 24.5);
    expect(result.description, 'con lluvia');
    expect(result.summary, contains('El clima en Tena'));
  });

  test('informa cuando no encuentra la ciudad', () async {
    final Dio client = testDio(
      (_) async => const TestHttpResponse(200, {'results': []}),
    );

    expect(
      () => WeatherService(client: client).getWeather('Ciudad inexistente'),
      throwsA(isA<Exception>()),
    );
  });
}
