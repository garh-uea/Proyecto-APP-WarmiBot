// ============================================================
// WarmiBot — Servicio Speech-to-Text
// Equivalente a: escuchar() + SpeechRecognizer en Python
// ============================================================

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String? _localeId;
  void Function(String message)? _onError;
  void Function()? _onListeningEnd;
  bool _endReported = false;

  bool get isListening => _listening;
  bool get isAvailable => _available;

  Future<bool> init() async {
    if (_available) return true;
    try {
      _available = await _stt.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      if (_available) {
        final locales = await _stt.locales();
        for (final locale in locales) {
          final id = locale.localeId.toLowerCase().replaceAll('-', '_');
          if (id == 'es_ec') {
            _localeId = locale.localeId;
            break;
          }
          if (_localeId == null && id.startsWith('es')) {
            _localeId = locale.localeId;
          }
        }
      }
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  /// Inicia escucha y llama [onResult] con el texto reconocido.
  /// Equivalente a escuchar() en Python.
  Future<bool> listen({
    required void Function(String text) onResult,
    void Function()? onListeningStart,
    void Function()? onListeningEnd,
    void Function(String message)? onError,
    Duration timeout = const Duration(seconds: 8),
    Duration pauseFor = const Duration(seconds: 2),
  }) async {
    if (!_available) await init();
    if (!_available) {
      onError?.call(
        'El reconocimiento de voz no está disponible. '
        'Revisa el permiso del micrófono y los servicios de voz del teléfono.',
      );
      return false;
    }
    if (_listening) await stop();

    _onError = onError;
    _onListeningEnd = onListeningEnd;
    _endReported = false;
    _listening = true;
    onListeningStart?.call();

    try {
      await _stt.listen(
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: timeout,
          pauseFor: pauseFor,
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.confirmation,
        ),
        onResult: (SpeechRecognitionResult result) {
          if (!result.finalResult) return;
          final text = result.recognizedWords.trim();
          if (text.isNotEmpty) {
            onResult(text);
          } else {
            _onError?.call(
              'No pude reconocer palabras. Intenta hablar un poco más cerca '
              'del micrófono.',
            );
          }
        },
      );
      return true;
    } catch (_) {
      _listening = false;
      _onError?.call(
        'No fue posible iniciar el micrófono. Revisa el permiso de audio.',
      );
      _notifyListeningEnd();
      return false;
    }
  }

  Future<void> stop() async {
    await _stt.stop();
    _listening = false;
    _notifyListeningEnd();
  }

  Future<void> cancel() async {
    await _stt.cancel();
    _listening = false;
    _notifyListeningEnd();
  }

  /// Nivel de ruido 0.0–1.0 para animar la onda de audio
  double get soundLevel => _stt.lastSoundLevel.clamp(0.0, 1.0);

  Future<void> dispose() => _stt.cancel();

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _listening = false;
      _notifyListeningEnd();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _listening = false;
    final message = switch (error.errorMsg) {
      'error_permission' ||
      'error_permission_denied' =>
        'WarmiBot necesita permiso para usar el micrófono.',
      'error_no_match' =>
        'No pude reconocer lo que dijiste. Intenta nuevamente.',
      'error_network' ||
      'error_network_timeout' =>
        'El reconocimiento de voz necesita conexión a internet.',
      _ => 'No fue posible reconocer la voz. Intenta nuevamente.',
    };
    _onError?.call(message);
    _notifyListeningEnd();
  }

  void _notifyListeningEnd() {
    if (_endReported) return;
    _endReported = true;
    _onListeningEnd?.call();
  }
}
