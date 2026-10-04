// ============================================================
// WarmiBot — Servicio de búsqueda
// Equivalente a: buscar_wikipedia(), buscar_duckduckgo() en Python
// ============================================================

import 'dart:convert';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';

class SearchService {
  final Dio _client;

  SearchService._({Dio? client}) : _client = client ?? ApiClient.instance.dio;
  static final SearchService instance = SearchService._();

  /// Constructor visible para pruebas con un adaptador HTTP controlado.
  SearchService.forTesting(Dio client) : _client = client;

  // ── Wikipedia ────────────────────────────────────────────────────────────────

  Future<String> searchWikipedia(String query, {int sentences = 3}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return 'Escribe un tema para buscar.';

    // MediaWiki busca por relevancia, sigue redirecciones y devuelve el
    // extracto en una sola llamada. Es más tolerante que exigir un título exacto.
    final uri = Uri.parse('https://es.wikipedia.org/w/api.php').replace(
      queryParameters: {
        'action': 'query',
        'generator': 'search',
        'gsrsearch': cleanQuery,
        'gsrlimit': '1',
        'prop': 'extracts',
        'exintro': 'true',
        'explaintext': 'true',
        'exsentences': sentences.toString(),
        'redirects': '1',
        'format': 'json',
        'origin': '*',
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
        final data = response.data is String
            ? jsonDecode(response.data as String) as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);
        final queryData = data['query'];
        if (queryData is Map && queryData['pages'] is Map) {
          final pages = Map<dynamic, dynamic>.from(queryData['pages'] as Map);
          if (pages.isNotEmpty) {
            final page = Map<String, dynamic>.from(pages.values.first as Map);
            final title = (page['title'] as String? ?? '').trim();
            final extract = (page['extract'] as String? ?? '').trim();
            if (extract.isNotEmpty) {
              return title.isEmpty ? extract : '$title: $extract';
            }
          }
        }
      }
    } catch (_) {
      // DuckDuckGo conserva una segunda vía si Wikipedia no está disponible.
    }
    return _searchDuckDuckGo(cleanQuery);
  }

  // ── DuckDuckGo Instant Answer (fallback) ─────────────────────────────────────

  Future<String> _searchDuckDuckGo(String query) async {
    final uri = Uri.parse('https://api.duckduckgo.com/').replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'no_redirect': '1',
        'skip_disambig': '1',
        'kl': 'es-es',
      },
    );

    try {
      final resp = await _client.getUri<dynamic>(
        uri,
        options: Options(extra: const {
          skipAuthKey: true,
          skipRefreshKey: true,
        }),
      );
      if (resp.statusCode == 200) {
        final data = resp.data is String
            ? jsonDecode(resp.data as String) as Map<String, dynamic>
            : Map<String, dynamic>.from(resp.data as Map);
        final abstract_ = (data['AbstractText'] as String? ?? '').trim();
        if (abstract_.isNotEmpty) return abstract_;
        final answer = (data['Answer'] as String? ?? '').trim();
        if (answer.isNotEmpty) return answer;
      }
    } catch (_) {}

    return 'No encontré información sobre "$query". '
        'Intenta con palabras más específicas.';
  }
}
