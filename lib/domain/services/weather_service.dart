// ============================================================
// WarmiBot — Servicio de Clima (OpenWeatherMap)
// Equivalente a: obtener_clima() en Python
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherResult {
  final String city;
  final double tempC;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final String description;
  final String icon;

  const WeatherResult({
    required this.city,
    required this.tempC,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
  });

  String get summary =>
      'El clima en $city es $description. '
      'Temperatura: ${tempC.toStringAsFixed(1)}°C, '
      'sensación térmica ${feelsLike.toStringAsFixed(1)}°C. '
      'Humedad del ${humidity.toStringAsFixed(0)}% y vientos a ${windSpeed.toStringAsFixed(1)} km/h.';
}

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<WeatherResult> getWeather(String city, {String country = 'EC'}) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'f7cfc5a8cd8d18811f53d863877cfbd5') {
      throw Exception('Configura tu API key de OpenWeatherMap en el archivo .env');
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q':     '$city,$country',
      'appid': apiKey,
      'units': 'metric',
      'lang':  'es',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final main    = data['main']    as Map<String, dynamic>;
      final weather = (data['weather'] as List).first as Map<String, dynamic>;
      final wind    = data['wind']    as Map<String, dynamic>;

      return WeatherResult(
        city:        data['name'] as String,
        tempC:       (main['temp']       as num).toDouble(),
        feelsLike:   (main['feels_like'] as num).toDouble(),
        humidity:    (main['humidity']   as num).toDouble(),
        windSpeed:   ((wind['speed'] as num).toDouble() * 3.6), // m/s → km/h
        description: weather['description'] as String,
        icon:        weather['icon']        as String,
      );
    } else if (response.statusCode == 404) {
      throw Exception('No encontré la ciudad "$city". ¿La escribiste bien?');
    } else {
      throw Exception('Error al consultar el clima (código ${response.statusCode})');
    }
  }
}
