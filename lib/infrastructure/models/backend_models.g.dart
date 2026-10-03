// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackendUser _$BackendUserFromJson(Map<String, dynamic> json) => BackendUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$BackendUserToJson(BackendUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'role': instance.role,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };

AuthTokenPair _$AuthTokenPairFromJson(Map<String, dynamic> json) =>
    AuthTokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: json['user'] == null
          ? null
          : BackendUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthTokenPairToJson(AuthTokenPair instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
      'token_type': instance.tokenType,
      'user': instance.user?.toJson(),
    };

BackendReminder _$BackendReminderFromJson(Map<String, dynamic> json) =>
    BackendReminder(
      id: (json['id'] as num).toInt(),
      clientId: json['client_id'] as String,
      text: json['text'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      reminderType: json['reminder_type'] as String,
      isCompleted: json['is_completed'] as bool,
      deleted: json['deleted'] as bool,
      version: (json['version'] as num).toInt(),
      clientUpdatedAt: DateTime.parse(json['client_updated_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$BackendReminderToJson(BackendReminder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'client_id': instance.clientId,
      'text': instance.text,
      'scheduled_at': instance.scheduledAt.toIso8601String(),
      'reminder_type': instance.reminderType,
      'is_completed': instance.isCompleted,
      'deleted': instance.deleted,
      'version': instance.version,
      'client_updated_at': instance.clientUpdatedAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
