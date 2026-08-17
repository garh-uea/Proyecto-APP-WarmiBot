import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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

class BackendApiException implements Exception {
  final String message;

  const BackendApiException(this.message);

  @override
  String toString() => message;
}

class BackendApiService {
  static const defaultBaseUrl = 'http://10.0.2.2:800';

  final http.Client _client;
  final bool _ownsClient;
  final Uri baseUri;
  final Duration timeout;

  BackendApiService({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 5),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        baseUri = _parseBaseUrl(baseUrl ?? _configuredBaseUrl());

  static String _configuredBaseUrl() {
    try {
      return dotenv.env['API_BASE_URL']?.trim().isNotEmpty == true
          ? dotenv.env['API_BASE_URL']!.trim()
          : defaultBaseUrl;
    } catch (_) {
      return defaultBaseUrl;
    }
  }

  static Uri _parseBaseUrl(String value) {
    final normalized = value.trim().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ArgumentError.value(value, 'baseUrl', 'URL HTTP(S) no válida');
    }
    return uri;
  }

  Future<BackendHealth> checkHealth() async {
    final endpoint = baseUri.replace(path: '${baseUri.path}/health');
    try {
      final response = await _client
          .get(endpoint, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw BackendApiException(
          'El backend respondió con HTTP ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(utf8.decode(response.bodyBytes));
      if (payload is! Map<String, dynamic> || payload['status'] != 'ok') {
        throw const BackendApiException(
          'La respuesta de /health no tiene el formato esperado.',
        );
      }

      return BackendHealth(
        status: payload['status'] as String,
        environment: payload['environment']?.toString() ?? 'desconocido',
        endpoint: endpoint,
      );
    } on BackendApiException {
      rethrow;
    } catch (error) {
      throw BackendApiException('No se pudo conectar con $endpoint: $error');
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
