// ============================================================
// WarmiBot — Modelo de Recordatorio / Alarma
// ============================================================

import 'package:equatable/equatable.dart';

enum ReminderType { reminder, alarm, timer }

enum ReminderSyncStatus { pending, synced, failed }

class Reminder extends Equatable {
  final int? id;
  final String text;
  final DateTime scheduledAt;
  final ReminderType type;
  final bool isCompleted;
  final String clientId;
  final int? serverId;
  final int serverVersion;
  final DateTime? updatedAt;
  final DateTime? lastSyncedAt;
  final ReminderSyncStatus syncStatus;
  final bool isDeleted;

  const Reminder({
    this.id,
    required this.text,
    required this.scheduledAt,
    this.type = ReminderType.reminder,
    this.isCompleted = false,
    this.clientId = '',
    this.serverId,
    this.serverVersion = 0,
    this.updatedAt,
    this.lastSyncedAt,
    this.syncStatus = ReminderSyncStatus.pending,
    this.isDeleted = false,
  });

  Reminder copyWith({
    int? id,
    String? text,
    DateTime? scheduledAt,
    ReminderType? type,
    bool? isCompleted,
    String? clientId,
    int? serverId,
    int? serverVersion,
    DateTime? updatedAt,
    DateTime? lastSyncedAt,
    ReminderSyncStatus? syncStatus,
    bool? isDeleted,
  }) =>
      Reminder(
        id: id ?? this.id,
        text: text ?? this.text,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        type: type ?? this.type,
        isCompleted: isCompleted ?? this.isCompleted,
        clientId: clientId ?? this.clientId,
        serverId: serverId ?? this.serverId,
        serverVersion: serverVersion ?? this.serverVersion,
        updatedAt: updatedAt ?? this.updatedAt,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        isDeleted: isDeleted ?? this.isDeleted,
      );

  DateTime get effectiveUpdatedAt => updatedAt ?? scheduledAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'scheduled_at': scheduledAt.toIso8601String(),
        'type': type.index,
        'is_completed': isCompleted ? 1 : 0,
        'client_id': clientId,
        'server_id': serverId,
        'server_version': serverVersion,
        'updated_at': effectiveUpdatedAt.toIso8601String(),
        'last_synced_at': lastSyncedAt?.toIso8601String(),
        'sync_status': syncStatus.name,
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'] as int?,
        text: map['text'] as String,
        scheduledAt: DateTime.parse(map['scheduled_at'] as String),
        type: ReminderType.values[map['type'] as int],
        isCompleted: (map['is_completed'] as int) == 1,
        clientId: map['client_id']?.toString() ?? '',
        serverId: map['server_id'] as int?,
        serverVersion: (map['server_version'] as int?) ?? 0,
        updatedAt: map['updated_at'] == null
            ? null
            : DateTime.parse(map['updated_at'] as String),
        lastSyncedAt: map['last_synced_at'] == null
            ? null
            : DateTime.parse(map['last_synced_at'] as String),
        syncStatus: ReminderSyncStatus.values.firstWhere(
          (status) => status.name == map['sync_status'],
          orElse: () => ReminderSyncStatus.pending,
        ),
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      );

  String get typeLabel {
    switch (type) {
      case ReminderType.alarm:
        return 'Alarma';
      case ReminderType.timer:
        return 'Temporizador';
      case ReminderType.reminder:
        return 'Recordatorio';
    }
  }

  @override
  List<Object?> get props => [
        id,
        text,
        scheduledAt,
        type,
        isCompleted,
        clientId,
        serverId,
        serverVersion,
        updatedAt,
        lastSyncedAt,
        syncStatus,
        isDeleted,
      ];
}
