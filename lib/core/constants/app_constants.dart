// ============================================================
// WarmiBot — Constantes globales
// ============================================================

class AppConstants {
  AppConstants._();

  static const String appName = 'WarmiBot';
  static const String assistantName = 'warmibot';
  static const String version = '1.0.0';

  // Ciudad por defecto (Tena, Napo, Ecuador)
  static const String defaultCity = 'Tena';
  static const String defaultCountry = 'EC';

  // Idiomas soportados (equivalente al dict IDIOMAS de Python)
  static const Map<String, String> languages = {
    'ingles': 'en',
    'inglés': 'en',
    'frances': 'fr',
    'francés': 'fr',
    'italiano': 'it',
    'aleman': 'de',
    'alemán': 'de',
    'portugues': 'pt',
    'portugués': 'pt',
    'chino': 'zh-cn',
    'japones': 'ja',
    'japonés': 'ja',
    'español': 'es',
    'espanol': 'es',
  };

  // Meses en español (equivalente a MESES_NUM de Python)
  static const Map<String, int> months = {
    'enero': 1,
    'febrero': 2,
    'marzo': 3,
    'abril': 4,
    'mayo': 5,
    'junio': 6,
    'julio': 7,
    'agosto': 8,
    'septiembre': 9,
    'octubre': 10,
    'noviembre': 11,
    'diciembre': 12,
  };

  // Contactos WhatsApp (reemplazar con los reales o usar agenda del dispositivo)
  static const Map<String, String> contacts = {
    'vicente': '+593982793812',
    'maria': '+593988888888',
    'pedro': '+593977777777',
  };

  // Umbral mínimo de similitud para detección de comandos
  static const double similarityThreshold = 0.55;

  // Canal de notificaciones Android
  static const String notifChannelId = 'warmibot_channel';
  static const String notifChannelName = 'WarmiBot Alertas';

  // Claves SharedPreferences
  static const String prefTtsRate = 'tts_rate';
  static const String prefTtsVolume = 'tts_volume';
  static const String prefDefaultCity = 'default_city';
  static const String prefThemeMode = 'theme_mode';
}
