// ============================================================
// WarmiBot — BLoC Events
// ============================================================

import 'package:equatable/equatable.dart';

abstract class AssistantEvent extends Equatable {
  const AssistantEvent();
  @override List<Object?> get props => [];
}

class ProcessTextCommand extends AssistantEvent {
  final String text;
  const ProcessTextCommand(this.text);
  @override List<Object?> get props => [text];
}

class StartListening  extends AssistantEvent { const StartListening(); }
class StopListening   extends AssistantEvent { const StopListening(); }
class SpeechReceived  extends AssistantEvent {
  final String text;
  const SpeechReceived(this.text);
  @override List<Object?> get props => [text];
}

class ClearChat       extends AssistantEvent { const ClearChat(); }
class InitAssistant   extends AssistantEvent { const InitAssistant(); }
