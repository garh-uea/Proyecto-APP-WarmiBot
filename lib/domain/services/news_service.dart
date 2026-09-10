// ============================================================
// WarmiBot — Servicio de Noticias RSS (BBC Mundo)
// Equivalente a: noticias_bbc() en Python con requests + regex
// ============================================================

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsItem {
  final String title;
  final String description;
  final String link;
  final String pubDate;

  const NewsItem({
    required this.title,
    required this.description,
    required this.link,
    required this.pubDate,
  });
}

class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  Future<List<NewsItem>> fetchNews({int maxItems = 5}) async {
    final url =
        dotenv.env['NEWS_RSS_URL'] ?? 'https://feeds.bbci.co.uk/mundo/rss.xml';

    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'No pude obtener las noticias (error ${response.statusCode})');
    }

    final document = XmlDocument.parse(response.body);
    final items = document.findAllElements('item').take(maxItems);

    return items.map((item) {
      String description =
          item.findElements('description').firstOrNull?.innerText ?? '';
      // Limpiar etiquetas HTML residuales
      description = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      // Truncar a 120 chars
      if (description.length > 120) {
        description = '${description.substring(0, 120)}...';
      }

      return NewsItem(
        title: item.findElements('title').firstOrNull?.innerText ?? '',
        description: description,
        link: item.findElements('link').firstOrNull?.innerText ?? '',
        pubDate: item.findElements('pubDate').firstOrNull?.innerText ?? '',
      );
    }).toList();
  }

  /// Formatea las noticias para leer en voz alta
  String formatForSpeech(List<NewsItem> items) {
    if (items.isEmpty) return 'No hay noticias disponibles ahora mismo.';
    final sb = StringBuffer('Aquí tienes las últimas noticias de BBC Mundo. ');
    for (int i = 0; i < items.length; i++) {
      sb.write('Noticia ${i + 1}: ${items[i].title}. ');
    }
    return sb.toString();
  }
}
