import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/core/constants/commands.dart';
import 'package:warmibot/core/utils/command_parser.dart';

void main() {
  group('CommandParser', () {
    test('reconoce solicitudes de clima escritas de distintas formas', () {
      expect(
        CommandParser.detect('¿Cuál es el clima en Quito?'),
        CommandType.clima,
      );
      expect(CommandParser.detect('temperatura de Cuenca'), CommandType.clima);
      expect(CommandParser.detect('cómo está el tiempo'), CommandType.clima);
    });

    test('extrae ciudades de una o varias palabras', () {
      expect(CommandParser.extractCity('clima en Quito'), 'quito');
      expect(
        CommandParser.extractCity('clima en Nueva York por favor'),
        'nueva york',
      );
      expect(
        CommandParser.extractCity('temperatura de Santo Domingo'),
        'santo domingo',
      );
      expect(
        CommandParser.extractCity('qué clima hace en San Francisco hoy'),
        'san francisco',
      );
    });

    test('usa la ciudad predeterminada si no se indicó una', () {
      expect(
        CommandParser.extractCity('dime el clima', fallback: 'Tena'),
        'Tena',
      );
      expect(
        CommandParser.extractCity('cómo está el tiempo', fallback: 'Tena'),
        'Tena',
      );
    });

    test('reconoce búsquedas naturales escritas o dictadas', () {
      expect(
        CommandParser.detect('WarmiBot, búscame información sobre Tena'),
        CommandType.buscar,
      );
      expect(
        CommandParser.detect('Háblame de la Amazonía ecuatoriana'),
        CommandType.buscar,
      );
      expect(
        CommandParser.extractSearchQuery(
          'WarmiBot, búscame información sobre Tena por favor',
        ),
        'información sobre Tena',
      );
      expect(
        CommandParser.extractSearchQuery('¿Quién es Laura Pausini?'),
        'Laura Pausini',
      );
    });

    test('extrae la traducción sin perder tildes ni palabras', () {
      expect(
        CommandParser.detect('Tradúceme ¿Cómo estás? al inglés'),
        CommandType.traducir,
      );
      expect(
        CommandParser.extractPhraseToTranslate(
          'Tradúceme ¿Cómo estás? al inglés',
        ),
        '¿Cómo estás?',
      );
      expect(
        CommandParser.extractPhraseToTranslate(
          'Traduce al francés buenos días, familia',
        ),
        'buenos días, familia',
      );
      expect(
        CommandParser.extractLanguage('Pasa esta frase al alemán')?.value,
        'de',
      );
    });
  });
}
