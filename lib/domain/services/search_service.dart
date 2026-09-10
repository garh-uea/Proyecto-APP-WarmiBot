// ============================================================
// WarmiBot — Servicio de búsqueda
// Equivalente a: buscar_wikipedia(), buscar_duckduckgo() en Python
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  SearchService._();
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

    final searchResp =
        await http.get(searchUri).timeout(const Duration(seconds: 8));
    if (searchResp.statusCode != 200) {
      return await _searchDuckDuckGo(query);
    }

    final searchData = jsonDecode(searchResp.body) as List;
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

    final extractResp =
        await http.get(extractUri).timeout(const Duration(seconds: 8));
    if (extractResp.statusCode != 200) {
      return await _searchDuckDuckGo(query);
    }

    final data = jsonDecode(extractResp.body) as Map<String, dynamic>;
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
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
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
