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

  String get summary => 'El clima en $city es $description. '
      'Temperatura: ${tempC.toStringAsFixed(1)}°C, '
      'sensación térmica ${feelsLike.toStringAsFixed(1)}°C. '
      'Humedad del ${humidity.toStringAsFixed(0)}% y vientos a ${windSpeed.toStringAsFixed(1)} km/h.';
}

class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();
  static final WeatherService instance = WeatherService();

  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _geocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String _forecastUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherResult> getWeather(String city, {String country = 'EC'}) async {
    final cleanCity = city.trim();
    if (cleanCity.isEmpty) {
      throw Exception(
          'Escribe el nombre de una ciudad para consultar el clima.');
    }

    var apiKey = '';
    try {
      apiKey = dotenv.env['OPENWEATHER_API_KEY']?.trim() ?? '';
    } catch (_) {
      // Las pruebas y compilaciones sin .env usan directamente el respaldo.
    }
    if (RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(apiKey)) {
      try {
        return await _getOpenWeather(cleanCity, country, apiKey);
      } catch (_) {
        // Open-Meteo mantiene operativa la función si la clave está vencida,
        // mal configurada o el proveedor principal no responde.
      }
    }

    return _getOpenMeteo(cleanCity, country);
  }

  Future<WeatherResult> _getOpenWeather(
    String city,
    String country,
    String apiKey,
  ) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': country.isEmpty ? city : '$city,$country',
      'appid': apiKey,
      'units': 'metric',
      'lang': 'es',
    });

    final response = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final main = data['main'] as Map<String, dynamic>;
      final weather = (data['weather'] as List).first as Map<String, dynamic>;
      final wind = data['wind'] as Map<String, dynamic>;

      return WeatherResult(
        city: data['name'] as String,
        tempC: (main['temp'] as num).toDouble(),
        feelsLike: (main['feels_like'] as num).toDouble(),
        humidity: (main['humidity'] as num).toDouble(),
        windSpeed: ((wind['speed'] as num).toDouble() * 3.6),
        description: weather['description'] as String,
        icon: weather['icon'] as String,
      );
    }
    throw Exception('OpenWeather respondió con código ${response.statusCode}.');
  }

  Future<WeatherResult> _getOpenMeteo(String city, String country) async {
    var location = await _findLocation(city, country);
    location ??= await _findLocation(city, '');
    if (location == null) {
      throw Exception('No encontré la ciudad "$city". ¿La escribiste bien?');
    }

    final uri = Uri.parse(_forecastUrl).replace(queryParameters: {
      'latitude': (location['latitude'] as num).toString(),
      'longitude': (location['longitude'] as num).toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      'temperature_unit': 'celsius',
      'wind_speed_unit': 'kmh',
      'timezone': 'auto',
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception(
        'El servicio meteorológico no respondió correctamente '
        '(código ${response.statusCode}).',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;
    if (current == null) {
      throw Exception('El servicio meteorológico no devolvió datos actuales.');
    }
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? -1;
    final locationName = location['name'] as String? ?? city;

    return WeatherResult(
      city: locationName,
      tempC: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toDouble(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      description: _weatherDescription(weatherCode),
      icon: weatherCode.toString(),
    );
  }

  Future<Map<String, dynamic>?> _findLocation(
    String city,
    String country,
  ) async {
    final parameters = <String, String>{
      'name': city,
      'count': '1',
      'language': 'es',
      'format': 'json',
    };
    if (country.isNotEmpty) parameters['countryCode'] = country;

    final uri = Uri.parse(_geocodingUrl).replace(queryParameters: parameters);
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;
    return Map<String, dynamic>.from(results.first as Map);
  }

  String _weatherDescription(int code) {
    if (code == 0) return 'cielo despejado';
    if (code == 1) return 'mayormente despejado';
    if (code == 2) return 'parcialmente nublado';
    if (code == 3) return 'nublado';
    if (code == 45 || code == 48) return 'con niebla';
    if ({51, 53, 55, 56, 57}.contains(code)) return 'con llovizna';
    if ({61, 63, 65, 66, 67, 80, 81, 82}.contains(code)) {
      return 'con lluvia';
    }
    if ({71, 73, 75, 77, 85, 86}.contains(code)) return 'con nieve';
    if ({95, 96, 99}.contains(code)) return 'con tormenta';
    return 'con condiciones variables';
  }
}
