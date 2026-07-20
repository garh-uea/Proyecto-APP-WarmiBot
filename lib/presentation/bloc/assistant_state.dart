// ============================================================
// WarmiBot — BLoC States
// ============================================================

import 'package:equatable/equatable.dart';
import '../../domain/models/chat_message.dart';

enum AvatarState { idle, listening, thinking, speaking, error }

class AssistantState extends Equatable {
  final List<ChatMessage> messages;
  final AvatarState       avatarState;
  final bool              isProcessing;
  final String?           errorMessage;
  final double            soundLevel;   // 0.0–1.0 para animar onda

  const AssistantState({
    this.messages     = const [],
    this.avatarState  = AvatarState.idle,
    this.isProcessing = false,
    this.errorMessage,
    this.soundLevel   = 0.0,
  });

  AssistantState copyWith({
    List<ChatMessage>? messages,
    AvatarState?       avatarState,
    bool?              isProcessing,
    String?            errorMessage,
    double?            soundLevel,
  }) =>
      AssistantState(
        messages:     messages     ?? this.messages,
        avatarState:  avatarState  ?? this.avatarState,
        isProcessing: isProcessing ?? this.isProcessing,
        errorMessage: errorMessage,
        soundLevel:   soundLevel   ?? this.soundLevel,
      );

  @override
  List<Object?> get props =>
      [messages, avatarState, isProcessing, errorMessage, soundLevel];
}
