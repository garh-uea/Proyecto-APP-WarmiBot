import 'package:json_annotation/json_annotation.dart';

part 'backend_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BackendUser {
  final int id;
  final String email;
  final String displayName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;

  const BackendUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory BackendUser.fromJson(Map<String, dynamic> json) =>
      _$BackendUserFromJson(json);
  Map<String, dynamic> toJson() => _$BackendUserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AuthTokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  final BackendUser? user;

  const AuthTokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'bearer',
    this.user,
  });

  factory AuthTokenPair.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenPairFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokenPairToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class BackendReminder {
  final int id;
  final String clientId;
  final String text;
  final DateTime scheduledAt;
  final String reminderType;
  final bool isCompleted;
  final bool deleted;
  final int version;
  final DateTime clientUpdatedAt;
  final DateTime updatedAt;

  const BackendReminder({
    required this.id,
    required this.clientId,
    required this.text,
    required this.scheduledAt,
    required this.reminderType,
    required this.isCompleted,
    required this.deleted,
    required this.version,
    required this.clientUpdatedAt,
    required this.updatedAt,
  });

  factory BackendReminder.fromJson(Map<String, dynamic> json) =>
      _$BackendReminderFromJson(json);
  Map<String, dynamic> toJson() => _$BackendReminderToJson(this);
}
