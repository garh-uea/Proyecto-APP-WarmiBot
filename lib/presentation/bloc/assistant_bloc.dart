// ============================================================
// WarmiBot — AssistantBloc (cerebro principal)
// Orquesta todos los servicios y comandos
// ============================================================

import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/commands.dart';
import '../../core/utils/command_parser.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/reminder.dart';
import '../../domain/services/tts_service.dart';
import '../../domain/services/stt_service.dart';
import '../../domain/services/weather_service.dart';
import '../../domain/services/search_service.dart';
import '../../domain/services/translation_service.dart';
import '../../domain/services/alarm_service.dart';
import '../../domain/services/news_service.dart';
import '../../infrastructure/repositories/reminders_repository.dart';
import 'assistant_event.dart';
import 'assistant_state.dart';

class AssistantBloc extends Bloc<AssistantEvent, AssistantState> {
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();
  final WeatherService _weather = WeatherService.instance;
  final SearchService _search = SearchService.instance;
  final TranslationService _translation = TranslationService.instance;
  final AlarmService _alarm = AlarmService.instance;
  final NewsService _news = NewsService.instance;
  final RemindersRepository _reminders = RemindersRepository.instance;

  int _notifId = 100;

  // Saludos aleatorios de bienvenida con identidad amazónica
  static const List<String> _greetings = [
    '¡Hola! Soy WarmiBot, tu asistente amazónica. ¿En qué puedo ayudarte hoy?',
    '¡Aló! Estoy aquí para ayudarte. ¿Qué necesitas?',
    '¡Rimani! — te escucho. ¿Cómo te puedo asistir?',
    '¡Buenos días desde la selva! Soy WarmiBot. ¿Qué necesitas?',
    '¡Aquí estoy! ¿En qué te puedo ayudar hoy?',
  ];

  static const List<String> _jokes = [
    '¿Por qué el libro de matemáticas está triste? Porque tiene demasiados problemas.',
    '¿Qué le dijo el cero al ocho? ¡Lindo cinturón!',
    '¿Cómo se llama el campeón de buceo japonés? Tokofondo.',
    '¿Qué hace una abeja en el gimnasio? ¡Zum-ba!',
    '¿Por qué los pájaros vuelan hacia el sur? Porque es demasiado lejos para caminar.',
    '¿Cuál es el colmo de un electricista? Que su hijo sea una luz pero no rinda en la escuela.',
  ];

  AssistantBloc() : super(const AssistantState()) {
    on<InitAssistant>(_onInit);
    on<ProcessTextCommand>(_onProcessText);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<SpeechReceived>(_onSpeechReceived);
    on<SpeechRecognitionFailed>(_onSpeechRecognitionFailed);
    on<SpeechListeningEnded>(_onSpeechListeningEnded);
    on<ClearChat>(_onClearChat);
    on<ShowHomeMenu>(_onShowHomeMenu);
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> _onInit(
    InitAssistant event,
    Emitter<AssistantState> emit,
  ) async {
    final unavailable = <String>[];
    try {
      await _tts.init();
    } catch (_) {
      unavailable.add('lectura en voz alta');
    }
    // SpeechToText.initialize puede abrir el permiso del micrófono en Android.
    // Se inicializa únicamente tras la explicación y aceptación en HomePage.
    try {
      await _alarm.init();
    } catch (_) {
      unavailable.add('alarmas');
    }

    var welcome =
        '¡Hola! Soy WarmiBot, tu asistente inteligente. '
        'Puedes escribirme o tocar el micrófono para hablarme. ¿En qué te ayudo?';
    if (unavailable.isNotEmpty) {
      welcome +=
          '\n\nAlgunas funciones necesitan revisión en este '
          'dispositivo: ${unavailable.join(', ')}. El chat por teclado sigue disponible.';
    }

    emit(
      state.copyWith(
        messages: [ChatMessage.bot(welcome)],
        avatarState: AvatarState.idle,
        showHomeMenu: true,
      ),
    );
    try {
      await _tts.speak(welcome);
    } catch (_) {
      // La interfaz debe seguir funcionando aunque TTS no esté disponible.
    }
  }

  // ── Texto enviado ─────────────────────────────────────────────────────────

  Future<void> _onProcessText(
    ProcessTextCommand event,
    Emitter<AssistantState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) return;

    final previousMessages = state.messages;
    final userMsg = ChatMessage.user(text);
    final loading = ChatMessage.loading();

    emit(
      state.copyWith(
        messages: [...state.messages, userMsg, loading],
        avatarState: AvatarState.thinking,
        isProcessing: true,
        showHomeMenu: false,
      ),
    );

    final response = await _resolveCommand(text);

    final msgs = [...previousMessages, userMsg, ChatMessage.bot(response)];
    emit(
      state.copyWith(
        messages: msgs,
        avatarState: AvatarState.speaking,
        isProcessing: false,
      ),
    );
    try {
      await _tts.speak(response);
    } catch (_) {
      // La respuesta escrita sigue siendo válida si el motor TTS falla.
    }
    emit(state.copyWith(avatarState: AvatarState.idle));
  }

  // ── Voz ──────────────────────────────────────────────────────────────────

  Future<void> _onStartListening(
    StartListening event,
    Emitter<AssistantState> emit,
  ) async {
    try {
      await _tts.stop();
    } catch (_) {
      // El micrófono puede continuar aunque TTS no estuviera disponible.
    }
    emit(state.copyWith(avatarState: AvatarState.listening, soundLevel: 0.0));
    await _stt.listen(
      onResult: (text) => add(SpeechReceived(text)),
      onListeningEnd: () => add(const SpeechListeningEnded()),
      onError: (message) => add(SpeechRecognitionFailed(message)),
    );
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<AssistantState> emit,
  ) async {
    await _stt.stop();
    emit(state.copyWith(avatarState: AvatarState.idle));
  }

  Future<void> _onSpeechReceived(
    SpeechReceived event,
    Emitter<AssistantState> emit,
  ) async {
    add(ProcessTextCommand(event.text));
  }

  Future<void> _onSpeechRecognitionFailed(
    SpeechRecognitionFailed event,
    Emitter<AssistantState> emit,
  ) async {
    emit(
      state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage.bot(event.message, type: MessageType.error),
        ],
        avatarState: AvatarState.error,
        isProcessing: false,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onSpeechListeningEnded(
    SpeechListeningEnded event,
    Emitter<AssistantState> emit,
  ) async {
    if (state.avatarState == AvatarState.listening) {
      emit(state.copyWith(avatarState: AvatarState.idle, soundLevel: 0.0));
    }
  }

  Future<void> _onClearChat(
    ClearChat event,
    Emitter<AssistantState> emit,
  ) async {
    emit(
      state.copyWith(
        messages: const [],
        avatarState: AvatarState.idle,
        isProcessing: false,
        soundLevel: 0,
        showHomeMenu: true,
      ),
    );
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _onShowHomeMenu(
    ShowHomeMenu event,
    Emitter<AssistantState> emit,
  ) async {
    emit(
      state.copyWith(
        avatarState: AvatarState.idle,
        isProcessing: false,
        soundLevel: 0,
        showHomeMenu: true,
      ),
    );
    try {
      await _tts.stop();
      await _stt.stop();
    } catch (_) {}
  }

  // ── Motor de inferencia de comandos ──────────────────────────────────────

  Future<String> _resolveCommand(String rawText) async {
    final text = CommandParser.normalize(rawText);
    final cmd = CommandParser.detect(rawText);

    try {
      switch (cmd) {
        // ── Hora y fecha ───────────────────────────────────────────────────
        case CommandType.hora:
          final now = DateTime.now();
          return 'Son las ${DateFormat('h:mm a').format(now)}.';

        case CommandType.fecha:
          final now = DateTime.now();
          final fmt = DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es');
          return 'Hoy es ${fmt.format(now)}.';

        // ── Saludo ────────────────────────────────────────────────────────
        case CommandType.saludo:
          return _greetings[math.Random().nextInt(_greetings.length)];

        // ── Chiste ────────────────────────────────────────────────────────
        case CommandType.chiste:
          return _jokes[math.Random().nextInt(_jokes.length)];

        // ── Clima ─────────────────────────────────────────────────────────
        case CommandType.clima:
          final city = CommandParser.extractCity(
            text,
            fallback: AppConstants.defaultCity,
          );
          final result = await _weather.getWeather(city);
          return result.summary;

        // ── Buscar Wikipedia ──────────────────────────────────────────────
        case CommandType.buscar:
          final query = CommandParser.extractSearchQuery(rawText);
          if (query.isEmpty) {
            return 'Para buscar, escribe o di: “Busca” seguido del tema. '
                'Ejemplo: “Busca información sobre la Amazonía ecuatoriana”.';
          }
          final result = await _search.searchWikipedia(query);
          return 'Resultado para “$query”:\n$result';

        // ── Traducir ──────────────────────────────────────────────────────
        case CommandType.traducir:
          final langEntry = CommandParser.extractLanguage(rawText);
          if (langEntry == null) {
            return 'Para traducir, escribe o di: “Traduce [frase] al '
                '[idioma]”. Ejemplo: “Traduce buenos días al inglés”. '
                'Puedes usar inglés, francés, italiano, alemán, portugués, '
                'chino, japonés o español.';
          }
          final phrase = CommandParser.extractPhraseToTranslate(rawText);
          if (phrase.isEmpty) {
            return 'Falta la frase. Usa, por ejemplo: '
                '“Traduce buenos días al inglés”.';
          }
          final translated = await _translation.translate(
            phrase,
            langEntry.value,
          );
          return '"$phrase" en ${langEntry.key} es: "$translated".';

        // ── Noticias ──────────────────────────────────────────────────────
        case CommandType.noticias:
          final items = await _news.fetchNews();
          return _news.formatForSpeech(items);

        // ── Alarma ────────────────────────────────────────────────────────
        case CommandType.alarma:
          final nums = CommandParser.extractNumbers(text);
          if (nums.length < 2) {
            return 'Dime la hora de la alarma. Por ejemplo: "alarma a las 7 con 30".';
          }
          final hour = nums[0];
          final min = nums[1];
          if (hour > 23 || min > 59) {
            return 'La hora no es válida. Usa una hora entre 0:00 y 23:59.';
          }
          await _alarm.scheduleAlarm(
            id: _notifId++,
            title: '⏰ WarmiBot — Alarma',
            body:
                'Son las ${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
            hour: hour,
            minute: min,
          );
          return 'Alarma programada para las ${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}.';

        // ── Temporizador ──────────────────────────────────────────────────
        case CommandType.temporizador:
          final nums = CommandParser.extractNumbers(text);
          if (nums.isEmpty) {
            return 'Dime cuántos minutos o segundos para el temporizador.';
          }
          final seconds = text.contains('segundo')
              ? nums.first
              : nums.first * 60;
          if (seconds <= 0) {
            return 'El temporizador debe durar al menos un segundo.';
          }
          await _alarm.scheduleTimer(
            id: _notifId++,
            title: '⏱ WarmiBot — Temporizador',
            body:
                'Tu temporizador de ${nums.first} ${text.contains('segundo') ? 'segundos' : 'minutos'} terminó.',
            seconds: seconds,
          );
          return 'Temporizador de ${nums.first} ${text.contains('segundo') ? 'segundos' : 'minutos'} activado.';

        // ── Recordatorio ─────────────────────────────────────────────────
        case CommandType.recordatorio:
          // Extraer la frase después de "recuérdame"
          String what = text
              .replaceAll(RegExp(r'recuerdame|recordatorio|avisame'), '')
              .trim();
          if (what.isEmpty) what = 'Tarea pendiente';
          // Por defecto: en 1 hora
          final scheduledAt = DateTime.now().add(const Duration(hours: 1));
          final reminder = await _reminders.insert(
            Reminder(
              text: what,
              scheduledAt: scheduledAt,
              type: ReminderType.reminder,
            ),
          );
          try {
            await _alarm.scheduleReminder(reminder);
            return 'Recordatorio guardado: "$what".';
          } catch (_) {
            return 'Recordatorio guardado: "$what". No habrá alerta local '
                'hasta que habilites las notificaciones, pero el registro '
                'permanece en el dispositivo y se sincronizará.';
          }

        // ── WhatsApp ──────────────────────────────────────────────────────
        case CommandType.whatsapp:
          // Buscar contacto en el dict
          String? phone;
          String? name;
          for (final entry in AppConstants.contacts.entries) {
            if (text.contains(entry.key)) {
              phone = entry.value;
              name = entry.key;
              break;
            }
          }
          if (phone == null) {
            return 'No encontré ese contacto. Agrega el número en la configuración.';
          }
          final msg = text
              .replaceAll(
                RegExp(
                  r'envia mensaje|manda mensaje|mensaje a|whatsapp a|a $name',
                ),
                '',
              )
              .trim();
          final whatsappUrl =
              'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(msg.isEmpty ? 'Hola' : msg)}';
          if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
            await launchUrl(Uri.parse(whatsappUrl));
            return 'Abriendo WhatsApp para enviar mensaje a $name.';
          }
          return 'No pude abrir WhatsApp. ¿Está instalado?';

        // ── Calculadora ───────────────────────────────────────────────────
        case CommandType.calculadora:
          final result = CommandParser.evalMath(text);
          if (result == null) {
            return 'No entendí la operación. Dime por ejemplo: "cuánto es 5 por 8".';
          }
          final fmt = result == result.truncateToDouble()
              ? result.toInt().toString()
              : result.toStringAsFixed(2);
          return 'El resultado es $fmt.';

        // ── Edad ──────────────────────────────────────────────────────────
        case CommandType.edad:
          final birthDate = CommandParser.extractBirthDate(text);
          if (birthDate == null) {
            return 'Dime tu fecha de nacimiento. Por ejemplo: "mi edad el 15 de marzo año 1990".';
          }
          final now = DateTime.now();
          int years = now.year - birthDate.year;
          int months = now.month - birthDate.month;
          int days = now.day - birthDate.day;
          if (days < 0) {
            months--;
            days += 30;
          }
          if (months < 0) {
            years--;
            months += 12;
          }
          return 'Tienes $years años, $months meses y $days días.';

        // ── Música (abrir YouTube Music) ──────────────────────────────────
        case CommandType.musica:
          final query = text
              .replaceAll(
                RegExp(r'reproduce|pon musica|toca|quiero escuchar'),
                '',
              )
              .trim();
          final url = query.isNotEmpty
              ? 'https://music.youtube.com/search?q=${Uri.encodeComponent(query)}'
              : 'https://music.youtube.com';
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          return query.isNotEmpty
              ? 'Buscando "$query" en YouTube Music.'
              : 'Abriendo YouTube Music.';

        // ── Desconocido ───────────────────────────────────────────────────
        case CommandType.salir:
          return '¡Hasta luego! Que tengas un excelente día. ¡Rimaykullayki!';

        case CommandType.abrir:
          return 'Dime qué aplicación o sitio quieres abrir.';

        case CommandType.suscriptores:
          return 'Consultar suscriptores requiere la YouTube Data API. Puedo configurarla si me das tu clave.';

        case CommandType.desconocido:
          return _unknownResponse(rawText);
      }
    } catch (e) {
      return 'Lo siento, ocurrió un error: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  String _unknownResponse(String text) {
    const responses = [
      'No entendí bien ese comando. ¿Puedes repetirlo de otra forma?',
      'Hmm, no estoy segura de cómo ayudarte con eso. Intenta preguntarme sobre el clima, noticias, una alarma o una traducción.',
      '¿Podrías ser más específico? Puedo ayudarte con: hora, clima, noticias, alarmas, recordatorios, búsquedas y más.',
      'No reconocí ese comando. Di "WarmiBot, ¿qué puedes hacer?" para ver mis funciones.',
    ];
    return responses[math.Random().nextInt(responses.length)];
  }

  @override
  Future<void> close() async {
    await _tts.dispose();
    _stt.dispose();
    await super.close();
  }
}
