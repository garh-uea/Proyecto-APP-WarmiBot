import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/domain/services/search_service.dart';
import 'package:warmibot/domain/services/translation_service.dart';

import 'support/callback_http_adapter.dart';

void main() {
  test('búsqueda usa resultados por relevancia de Wikipedia', () async {
    final client = testDio((request) async {
      expect(request.uri.host, 'es.wikipedia.org');
      expect(request.uri.queryParameters['generator'], 'search');
      expect(request.uri.queryParameters['gsrsearch'], 'Amazonía ecuatoriana');
      return const TestHttpResponse(200, {
        'query': {
          'pages': {
            '1': {
              'title': 'Región Amazónica del Ecuador',
              'extract': 'Es una de las cuatro regiones naturales del Ecuador.',
            },
          },
        },
      });
    });

    final result = await SearchService.forTesting(
      client,
    ).searchWikipedia('Amazonía ecuatoriana');

    expect(result, contains('Región Amazónica del Ecuador'));
    expect(result, contains('cuatro regiones'));
  });

  test('traducción concatena todos los fragmentos recibidos', () async {
    final client = testDio((request) async {
      expect(request.uri.host, 'translate.googleapis.com');
      expect(request.uri.queryParameters['q'], '¿Cómo estás?');
      expect(request.uri.queryParameters['tl'], 'en');
      return const TestHttpResponse(200, [
        [
          ['How are ', '¿Cómo ', null, null],
          ['you?', 'estás?', null, null],
        ],
      ]);
    });

    final result = await TranslationService.forTesting(
      client,
    ).translate('¿Cómo estás?', 'en');

    expect(result, 'How are you?');
  });
}
