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

  // ── Wikipedia ────────────────────────────────────────────────────────────────

  Future<String> searchWikipedia(String query, {int sentences = 3}) async {
    // 1. Buscar título exacto
    final searchUri = Uri.parse('https://es.wikipedia.org/w/api.php')
        .replace(queryParameters: {
      'action': 'opensearch',
      'search': query,
      'limit': '1',
      'format': 'json',
    });

    final searchResp = await _client.getUri<dynamic>(
      searchUri,
      options: Options(extra: const {
        skipAuthKey: true,
        skipRefreshKey: true,
      }),
    );
    if (searchResp.statusCode != 200) {
      return await _searchDuckDuckGo(query);
    }

    final searchData = searchResp.data is String
        ? jsonDecode(searchResp.data as String) as List
        : searchResp.data as List;
    final titles = searchData[1] as List;
    if (titles.isEmpty) {
      return await _searchDuckDuckGo(query);
    }

    final title = titles.first as String;

    // 2. Obtener extracto del artículo
    final extractUri = Uri.parse('https://es.wikipedia.org/w/api.php')
        .replace(queryParameters: {
      'action': 'query',
      'titles': title,
      'prop': 'extracts',
      'exintro': 'true',
      'explaintext': 'true',
      'exsentences': sentences.toString(),
      'format': 'json',
    });

    final extractResp = await _client.getUri<dynamic>(
      extractUri,
      options: Options(extra: const {
        skipAuthKey: true,
        skipRefreshKey: true,
      }),
    );
    if (extractResp.statusCode != 200) {
      return await _searchDuckDuckGo(query);
    }

    final data = extractResp.data is String
        ? jsonDecode(extractResp.data as String) as Map<String, dynamic>
        : Map<String, dynamic>.from(extractResp.data as Map);
    final pages = (data['query']['pages'] as Map<String, dynamic>);
    final page = pages.values.first as Map<String, dynamic>;
    final extract = (page['extract'] as String? ?? '').trim();

    if (extract.isEmpty) return await _searchDuckDuckGo(query);

    // Truncar a ~3 oraciones
    final parts = extract.split('. ');
    return '${parts.take(sentences).join('. ')}.';
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
