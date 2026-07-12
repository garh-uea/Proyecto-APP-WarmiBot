// ============================================================
// WarmiBot — Servicio Speech-to-Text
// Equivalente a: escuchar() + SpeechRecognizer en Python
// ============================================================

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _listening = false;

  bool get isListening  => _listening;
  bool get isAvailable  => _available;

  Future<bool> init() async {
    _available = await _stt.initialize(
      onError: (e) => _listening = false,
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listening = false;
        }
      },
    );
    return _available;
  }

  /// Inicia escucha y llama [onResult] con el texto reconocido.
  /// Equivalente a escuchar() en Python.
  Future<void> listen({
    required void Function(String text) onResult,
    void Function()? onListeningStart,
    void Function()? onListeningEnd,
    Duration timeout = const Duration(seconds: 8),
    Duration pauseFor = const Duration(seconds: 2),
  }) async {
    if (!_available) await init();
    if (!_available) return;
    if (_listening) await stop();

    _listening = true;
    onListeningStart?.call();

    await _stt.listen(
      localeId: 'es_EC',  // Español Ecuador
      listenFor: timeout,
      pauseFor: pauseFor,
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          _listening = false;
          onListeningEnd?.call();
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) onResult(text);
        }
      },
    );
  }

  Future<void> stop() async {
    await _stt.stop();
    _listening = false;
  }

  Future<void> cancel() async {
    await _stt.cancel();
    _listening = false;
  }

  /// Nivel de ruido 0.0–1.0 para animar la onda de audio
  double get soundLevel => _stt.lastSoundLevel.clamp(0.0, 1.0);

  void dispose() {
    _stt.cancel();
  }
}
