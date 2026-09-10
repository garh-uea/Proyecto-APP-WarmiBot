// ============================================================
// WarmiBot — Modelo de mensaje de chat
// ============================================================

import 'package:equatable/equatable.dart';

enum MessageSender { user, bot }

enum MessageType { text, audio, error, loading }

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final MessageSender sender;
  final MessageType type;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    this.type = MessageType.text,
    required this.timestamp,
  });

  factory ChatMessage.user(String text) => ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.bot(String text, {MessageType type = MessageType.text}) =>
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: text,
        sender: MessageSender.bot,
        type: type,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.loading() => ChatMessage(
        id: 'loading',
        text: '...',
        sender: MessageSender.bot,
        type: MessageType.loading,
        timestamp: DateTime.now(),
      );

  @override
  List<Object?> get props => [id, text, sender, type, timestamp];
}
