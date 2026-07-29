// ============================================================
// WarmiBot — Servicio de Alarmas y Notificaciones Push
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_constants.dart';
import '../models/reminder.dart';

class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ==========================================================
  // Inicialización
  // ==========================================================

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    try {
      tz.setLocalLocation(
        tz.getLocation('America/Guayaquil'),
      );
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      AppConstants.notifChannelId,
      AppConstants.notifChannelName,
      description: 'Alertas y recordatorios de WarmiBot',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  // ==========================================================
  // Evento al tocar una notificación
  // ==========================================================

  void _onNotificationTap(NotificationResponse response) {
    debugPrint(
      'Notificación presionada: ${response.payload}',
    );
  }

  // ==========================================================
  // Configuración visual de notificaciones
  // ==========================================================

  NotificationDetails get _details {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        channelDescription: 'Alertas de WarmiBot',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        color: Color(0xFF1B8A3C),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ==========================================================
  // Alarma por hora exacta
  // ==========================================================

  Future<void> scheduleAlarm({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('La hora debe estar entre 00:00 y 23:59.');
    }
    await init();

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    final scheduleMode = await _androidScheduleMode();

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _details,
      androidScheduleMode: scheduleMode,
    );
  }

  // ==========================================================
  // Temporizador
  // ==========================================================

  Future<void> scheduleTimer({
    required int id,
    required String title,
    required String body,
    required int seconds,
  }) async {
    if (seconds <= 0) {
      throw ArgumentError.value(seconds, 'seconds', 'Debe ser mayor que cero');
    }
    await init();

    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      Duration(seconds: seconds),
    );
    final scheduleMode = await _androidScheduleMode();

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _details,
      androidScheduleMode: scheduleMode,
    );
  }

  // ==========================================================
  // Recordatorio desde objeto Reminder
  // ==========================================================

  Future<void> scheduleReminder(
    Reminder reminder,
  ) async {
    await init();

    if (reminder.id == null) return;

    final scheduledDate = tz.TZDateTime.from(
      reminder.scheduledAt,
      tz.local,
    );

    if (scheduledDate.isBefore(
      tz.TZDateTime.now(tz.local),
    )) {
      return;
    }
    final scheduleMode = await _androidScheduleMode();

    await _plugin.zonedSchedule(
      id: reminder.id!,
      title: '🌿 WarmiBot',
      body: reminder.text,
      scheduledDate: scheduledDate,
      notificationDetails: _details,
      androidScheduleMode: scheduleMode,
    );
  }

  // ==========================================================
  // Notificación inmediata
  // ==========================================================

  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  // ==========================================================
  // Cancelar
  // ==========================================================

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(
      id: id,
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;

    final notificationsAllowed = await android.requestNotificationsPermission();
    if (notificationsAllowed == false) {
      throw Exception(
        'WarmiBot necesita permiso de notificaciones para crear alarmas.',
      );
    }

    var exactAllowed = await android.canScheduleExactNotifications();
    if (exactAllowed == false) {
      await android.requestExactAlarmsPermission();
      exactAllowed = await android.canScheduleExactNotifications();
    }
    return exactAllowed == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
  }
}
