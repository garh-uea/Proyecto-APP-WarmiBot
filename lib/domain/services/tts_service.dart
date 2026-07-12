// ============================================================
// WarmiBot — Servicio Text-to-Speech
// Equivalente a: hablar() + init pyttsx3 en Python
// ============================================================

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _speaking = false;

  bool get isSpeaking => _speaking;

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final rate   = prefs.getDouble(AppConstants.prefTtsRate)   ?? 0.5;
    final volume = prefs.getDouble(AppConstants.prefTtsVolume) ?? 1.0;

    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(volume);
    await _tts.setPitch(1.0);

    // Callbacks de estado
    _tts.setStartHandler(() => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((_) => _speaking = false);

    _initialized = true;
  }

  /// Habla el texto dado. Equivalente a hablar() en Python.
  Future<void> speak(String text) async {
    await init();
    if (_speaking) await stop();
    // Limpiar caracteres problemáticos
    final clean = text.replaceAll('*', '').replaceAll('#', '').trim();
    if (clean.isEmpty) return;
    await _tts.speak(clean);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }

  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefTtsRate, rate);
  }

  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.prefTtsVolume, volume);
  }

  /// Retorna voces disponibles en español
  Future<List<Map>> getSpanishVoices() async {
    final voices = await _tts.getVoices as List<dynamic>;
    return voices
        .cast<Map>()
        .where((v) => (v['locale'] as String? ?? '').startsWith('es'))
        .toList();
  }

  void dispose() {
    _tts.stop();
  }
}
