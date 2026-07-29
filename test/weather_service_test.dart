import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:warmibot/domain/services/weather_service.dart';

void main() {
  test('consulta Open-Meteo cuando no existe una clave de OpenWeather',
      () async {
    final client = MockClient((request) async {
      if (request.url.host == 'geocoding-api.open-meteo.com') {
        expect(request.url.queryParameters['name'], 'Tena');
        return http.Response(
          jsonEncode({
            'results': [
              {
                'name': 'Tena',
                'latitude': -0.9938,
                'longitude': -77.8129,
              }
            ],
          }),
          200,
        );
      }
      if (request.url.host == 'api.open-meteo.com') {
        return http.Response(
          jsonEncode({
            'current': {
              'temperature_2m': 24.5,
              'relative_humidity_2m': 86,
              'apparent_temperature': 26.1,
              'weather_code': 61,
              'wind_speed_10m': 5.4,
            },
          }),
          200,
        );
      }
      return http.Response('No esperado', 500);
    });

    final result = await WeatherService(client: client).getWeather('Tena');

    expect(result.city, 'Tena');
    expect(result.tempC, 24.5);
    expect(result.description, 'con lluvia');
    expect(result.summary, contains('El clima en Tena'));
  });

  test('informa cuando no encuentra la ciudad', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'results': []}), 200),
    );

    expect(
      () => WeatherService(client: client).getWeather('Ciudad inexistente'),
      throwsA(isA<Exception>()),
    );
  });
}
