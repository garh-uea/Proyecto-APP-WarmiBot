// ============================================================
// WarmiBot — Servicio de Traducción (Google Translate vía HTTP)
// Equivalente a: traducir() en Python con deep_translator
// ============================================================

import 'dart:convert';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class TranslationService {
  final Dio _client;

  TranslationService._({Dio? client})
      : _client = client ?? ApiClient.instance.dio;
  static final TranslationService instance = TranslationService._();

  /// Constructor visible para pruebas con un adaptador HTTP controlado.
  TranslationService.forTesting(Dio client) : _client = client;

  Future<String> translate(String text, String targetLang,
      {String sourceLang = 'auto'}) async {
    if (text.trim().isEmpty) return '';

    // Usar la API pública de Google Translate (sin key)
    final uri = Uri.parse('https://translate.googleapis.com/translate_a/single')
        .replace(
      queryParameters: {
        'client': 'gtx',
        'sl': sourceLang,
        'tl': targetLang,
        'dt': 't',
        'q': text,
      },
    );

    try {
      final response = await _client.getUri<dynamic>(
        uri,
        options: Options(extra: const {
          skipAuthKey: true,
          skipRefreshKey: true,
        }),
      );
      if (response.statusCode == 200) {
        final decoded = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        if (decoded is! List || decoded.isEmpty || decoded[0] is! List) {
          throw const FormatException('Respuesta de traducción no válida');
        }
        final translations = decoded[0] as List;
        final result = StringBuffer();
        for (final part in translations) {
          if (part is List && part.isNotEmpty && part[0] is String) {
            result.write(part[0] as String);
          }
        }
        final translated = result.toString().trim();
        if (translated.isNotEmpty) return translated;
      }
    } catch (e) {
      throw Exception(
          'No pude conectarme al servicio de traducción. Verifica tu conexión.');
    }

    throw Exception('Error en el servicio de traducción.');
  }
}
