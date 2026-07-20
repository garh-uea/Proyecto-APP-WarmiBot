// ============================================================
// WarmiBot — Servicio de Traducción (Google Translate vía HTTP)
// Equivalente a: traducir() en Python con deep_translator
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  Future<String> translate(String text, String targetLang, {String sourceLang = 'auto'}) async {
    if (text.trim().isEmpty) return '';

    // Usar la API pública de Google Translate (sin key)
    final uri = Uri.parse('https://translate.googleapis.com/translate_a/single').replace(
      queryParameters: {
        'client': 'gtx',
        'sl':     sourceLang,
        'tl':     targetLang,
        'dt':     't',
        'q':      text,
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final translations = data[0] as List;
        final result = StringBuffer();
        for (final part in translations) {
          if (part != null && (part as List).isNotEmpty && part[0] != null) {
            result.write(part[0] as String);
          }
        }
        return result.toString().trim();
      }
    } catch (e) {
      throw Exception('No pude conectarme al servicio de traducción. Verifica tu conexión.');
    }

    throw Exception('Error en el servicio de traducción.');
  }
}
