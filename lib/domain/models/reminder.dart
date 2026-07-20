// ============================================================
// WarmiBot — Modelo de Recordatorio / Alarma
// ============================================================

import 'package:equatable/equatable.dart';

enum ReminderType { reminder, alarm, timer }

class Reminder extends Equatable {
  final int? id;
  final String text;
  final DateTime scheduledAt;
  final ReminderType type;
  final bool isCompleted;

  const Reminder({
    this.id,
    required this.text,
    required this.scheduledAt,
    this.type = ReminderType.reminder,
    this.isCompleted = false,
  });

  Reminder copyWith({
    int? id,
    String? text,
    DateTime? scheduledAt,
    ReminderType? type,
    bool? isCompleted,
  }) =>
      Reminder(
        id: id ?? this.id,
        text: text ?? this.text,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        type: type ?? this.type,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'scheduled_at': scheduledAt.toIso8601String(),
        'type': type.index,
        'is_completed': isCompleted ? 1 : 0,
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'] as int?,
        text: map['text'] as String,
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
        type: ReminderType.values[map['type'] as int],
        isCompleted: (map['is_completed'] as int) == 1,
      );

  String get typeLabel {
    switch (type) {
      case ReminderType.alarm:    return 'Alarma';
      case ReminderType.timer:    return 'Temporizador';
      case ReminderType.reminder: return 'Recordatorio';
    }
  }

  @override
  List<Object?> get props => [id, text, scheduledAt, type, isCompleted];
}
