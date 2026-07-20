// ============================================================
// WarmiBot — Parser de comandos
// Equivalente a: normalizar(), similitud(), detectar_comando()
// ============================================================

import 'package:string_similarity/string_similarity.dart';
import '../constants/commands.dart';
import '../constants/app_constants.dart';

class CommandParser {
  CommandParser._();

  /// Normaliza texto: minúsculas, sin tildes, sin puntuación
  /// Equivalente a normalizar() en Python
  static String normalize(String text) {
    String result = text.toLowerCase().trim();

    // Quitar tildes
    const Map<String, String> accentMap = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'à': 'a',
      'è': 'e',
      'ì': 'i',
      'ò': 'o',
      'ù': 'u',
      'ä': 'a',
      'ë': 'e',
      'ï': 'i',
      'ö': 'o',
      'ü': 'u',
      'â': 'a',
      'ê': 'e',
      'î': 'i',
      'ô': 'o',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    accentMap.forEach((k, v) => result = result.replaceAll(k, v));

    // Quitar puntuación
    result = result.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Normalizar espacios múltiples
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  /// Detecta el comando principal del texto normalizado
  /// Equivalente a detectar_comando() en Python con fuzzy matching
  static CommandType detect(String rawText) {
    final text = normalize(rawText);

    // 1. Eliminar el nombre del asistente al inicio
    final cleanText = text.replaceFirst(
        RegExp(r'^(warmibot|warmi)\s*', caseSensitive: false), '');

    // 2. Búsqueda exacta por subcadena (más rápida)
    for (final entry in Commands.variants.entries) {
      for (final variant in entry.value) {
        if (cleanText.contains(variant)) {
          return entry.key;
        }
      }
    }

    // 3. Fuzzy matching con string_similarity
    // Equivalente a difflib.SequenceMatcher en Python
    CommandType bestCmd = CommandType.desconocido;
    double bestScore = 0.0;

    for (final entry in Commands.variants.entries) {
      for (final variant in entry.value) {
        final score = StringSimilarity.compareTwoStrings(cleanText, variant);
        if (score > bestScore) {
          bestScore = score;
          bestCmd = entry.key;
        }
      }
    }

    return bestScore >= AppConstants.similarityThreshold
        ? bestCmd
        : CommandType.desconocido;
  }

  /// Extrae números del texto
  static List<int> extractNumbers(String text) {
    final matches = RegExp(r'\d+').allMatches(text);
    return matches.map((m) => int.parse(m.group(0)!)).toList();
  }

  /// Extrae ciudad: busca `en ciudad` al final del texto.
  static String extractCity(String text, {String fallback = 'Tena'}) {
    final match = RegExp(r'\ben\s+(\w+(?:\s+\w+)?)\s*$').firstMatch(text);
    if (match != null) return match.group(1)!.trim();
    final words = text.split(' ');
    return words.isNotEmpty ? words.last : fallback;
  }

  /// Extrae idioma destino del texto de traducción
  static MapEntry<String, String>? extractLanguage(String text) {
    for (final entry in AppConstants.languages.entries) {
      if (text.contains(entry.key)) {
        return entry;
      }
    }
    return null;
  }

  /// Limpia frase para traducción (quita verbos de comando e idioma)
  static String extractPhraseToTranslate(String text) {
    String phrase = text;
    for (final p in ['traduce', 'traducir', 'como se dice']) {
      phrase = phrase.replaceAll(p, '');
    }
    for (final lang in AppConstants.languages.keys) {
      phrase = phrase
          .replaceAll('al $lang', '')
          .replaceAll('en $lang', '')
          .replaceAll(lang, '');
    }
    return phrase.trim();
  }

  /// Extrae fecha de nacimiento del texto para cálculo de edad
  /// Ej: "mi edad el 15 de marzo año 1990"
  static DateTime? extractBirthDate(String text) {
    // Extraer día
    final dayMatch = RegExp(r'\b(\d{1,2})\b').firstMatch(text);
    if (dayMatch == null) return null;
    final day = int.parse(dayMatch.group(1)!);

    // Extraer mes por nombre
    int? month;
    for (final entry in AppConstants.months.entries) {
      if (text.contains(entry.key)) {
        month = entry.value;
        break;
      }
    }
    if (month == null) return null;

    // Extraer año (4 dígitos, 1900–2099)
    final yearMatch = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(text);
    if (yearMatch == null) return null;
    final year = int.parse(yearMatch.group(1)!);

    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  /// Extrae expresión matemática y la evalúa de forma segura
  /// Equivalente al ast.parse + eval de Python
  static double? evalMath(String text) {
    String expr = text
        .replaceAll('mas', '+')
        .replaceAll('más', '+')
        .replaceAll('menos', '-')
        .replaceAll('por', '*')
        .replaceAll('x', '*')
        .replaceAll('entre', '/')
        .replaceAll('dividido', '/')
        .replaceAll(RegExp(r'[^\d\+\-\*\/\.\(\)\s]'), '')
        .trim();
    if (expr.isEmpty) return null;
    try {
      return _evalExpr(expr);
    } catch (_) {
      return null;
    }
  }

  // Mini evaluador de expresiones aritméticas (sin dependencias externas)
  static double _evalExpr(String expr) {
    expr = expr.replaceAll(' ', '');
    final pos = _Pos(0);
    final result = _parseAddSub(expr, pos);
    if (pos.i != expr.length || !result.isFinite) {
      throw const FormatException('Expresión matemática inválida');
    }
    return result;
  }

  static double _parseAddSub(String expr, _Pos pos) {
    double result = _parseMulDiv(expr, pos);
    while (pos.i < expr.length) {
      final op = expr[pos.i];
      if (op != '+' && op != '-') break;
      pos.i++;
      final right = _parseMulDiv(expr, pos);
      result = op == '+' ? result + right : result - right;
    }
    return result;
  }

  static double _parseMulDiv(String expr, _Pos pos) {
    double result = _parseUnary(expr, pos);
    while (pos.i < expr.length) {
      final op = expr[pos.i];
      if (op != '*' && op != '/') break;
      pos.i++;
      final right = _parseUnary(expr, pos);
      result = op == '*' ? result * right : result / right;
    }
    return result;
  }

  static double _parseUnary(String expr, _Pos pos) {
    if (pos.i < expr.length && expr[pos.i] == '-') {
      pos.i++;
      return -_parseAtom(expr, pos);
    }
    return _parseAtom(expr, pos);
  }

  static double _parseAtom(String expr, _Pos pos) {
    if (pos.i < expr.length && expr[pos.i] == '(') {
      pos.i++; // '('
      final result = _parseAddSub(expr, pos);
      if (pos.i >= expr.length || expr[pos.i] != ')') {
        throw const FormatException('Falta cerrar un paréntesis');
      }
      pos.i++; // ')'
      return result;
    }
    final start = pos.i;
    while (pos.i < expr.length && (expr[pos.i].contains(RegExp(r'[\d\.]')))) {
      pos.i++;
    }
    if (start == pos.i) {
      throw const FormatException('Se esperaba un número');
    }
    return double.parse(expr.substring(start, pos.i));
  }
}

class _Pos {
  int i;
  _Pos(this.i);
}
