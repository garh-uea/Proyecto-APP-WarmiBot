import 'package:flutter/foundation.dart';

enum AppEnvironment { development, test, production }

class ApiEnvironment {
  ApiEnvironment._();

  static const _environmentValue =
      String.fromEnvironment('APP_ENV', defaultValue: 'development');
  static const _baseUrlValue = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const openWeatherApiKey =
      String.fromEnvironment('OPENWEATHER_API_KEY');
  static const newsRssUrl = String.fromEnvironment(
    'NEWS_RSS_URL',
    defaultValue: 'https://feeds.bbci.co.uk/mundo/rss.xml',
  );

  static const connectTimeout = Duration(seconds: 5);
  static const sendTimeout = Duration(seconds: 8);
  static const receiveTimeout = Duration(seconds: 8);

  static AppEnvironment get environment => switch (_environmentValue) {
        'production' => AppEnvironment.production,
        'test' => AppEnvironment.test,
        _ => AppEnvironment.development,
      };

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isReleaseBuild => kReleaseMode;
  static bool get diagnosticsEnabled => !isProduction && kDebugMode;

  static Uri get baseUri {
    final uri =
        Uri.tryParse(_baseUrlValue.trim().replaceFirst(RegExp(r'/$'), ''));
    if (uri == null ||
        !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme)) {
      throw StateError('API_BASE_URL debe ser una dirección HTTP(S) válida.');
    }
    if ((isProduction || isReleaseBuild) && uri.scheme != 'https') {
      throw StateError(
          'La configuración de producción exige API_BASE_URL con HTTPS.');
    }
    return uri;
  }
}
