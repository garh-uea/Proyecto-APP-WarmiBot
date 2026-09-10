import 'package:flutter/material.dart';

import '../../domain/models/chat_message.dart';
import '../components/warmi_message_card.dart';

/// Nombre conservado para no romper los consumidores existentes de Inicio.
/// La presentación real pertenece al componente del catálogo.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) => WarmiMessageCard(message: message);
}
