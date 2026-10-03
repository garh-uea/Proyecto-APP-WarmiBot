// ============================================================
// WarmiBot — HomePage (pantalla principal)
// Fiel al diseño: avatar arriba, burbuja de saludo, acciones
// rápidas, input inferior con micrófono
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/commands.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/command_parser.dart';
import '../bloc/assistant_bloc.dart';
import '../bloc/assistant_event.dart';
import '../bloc/assistant_state.dart';
import '../widgets/warmi_avatar.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/input_bar.dart';
import '../widgets/backend_status_indicator.dart';
import '../../domain/services/device_capability_service.dart';
import '../widgets/capability_permission_prompt.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitCommand(String text) async {
    final type = CommandParser.detect(text);
    if (type == CommandType.alarma ||
        type == CommandType.temporizador ||
        type == CommandType.recordatorio) {
      final allowed = await CapabilityPermissionPrompt.ensure(
        context,
        DeviceCapability.notifications,
      );
      if (!mounted) return;
      // Un recordatorio se conserva en SQLite aunque no haya alerta local.
      // Alarmas y temporizadores no tienen una alternativa persistida.
      if (!allowed && type != CommandType.recordatorio) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se programó la alerta. Activa las notificaciones.',
            ),
          ),
        );
        return;
      }
    }
    context.read<AssistantBloc>().add(ProcessTextCommand(text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssistantBloc, AssistantState>(
      listener: (context, state) {
        if (state.messages.isNotEmpty) _scrollToBottom();
      },
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppColors.bgGradient,
            ),
          ),
          child: Column(
            children: [
              // ── AppBar ──────────────────────────────────────────────────
              _WarmiAppBar(state: state),

              // ── Cuerpo scrollable ────────────────────────────────────────
              Expanded(
                child: state.messages.isEmpty
                    ? _buildIdleBody(context, state)
                    : _buildChatBody(context, state),
              ),

              // ── Acciones rápidas (visibles siempre) ───────────────────
              if (state.messages.length <= 2)
                QuickActionsGrid(onAction: (cmd) => _submitCommand(cmd)),

              // ── Barra de input ──────────────────────────────────────────
              InputBar(
                avatarState: state.avatarState,
                onSubmit: (text) => _submitCommand(text),
                onVoiceTap: () async {
                  final bloc = context.read<AssistantBloc>();
                  if (state.avatarState == AvatarState.listening) {
                    bloc.add(const StopListening());
                  } else {
                    final allowed = await CapabilityPermissionPrompt.ensure(
                      context,
                      DeviceCapability.microphone,
                    );
                    if (allowed && context.mounted) {
                      bloc.add(const StartListening());
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Vista inicial (sin mensajes) ──────────────────────────────────────────
  Widget _buildIdleBody(BuildContext context, AssistantState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Avatar central grande
          WarmiAvatar(
            avatarState: state.avatarState,
            soundLevel: state.soundLevel,
            size: 200,
          ),
          const SizedBox(height: 20),
          // Burbuja de saludo (fiel al diseño)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '👋 ¡Hola!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Soy WarmiBot,\n¿En qué puedo ayudarte hoy?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Vista de chat (con mensajes) ──────────────────────────────────────────
  Widget _buildChatBody(BuildContext context, AssistantState state) {
    return Column(
      children: [
        // Avatar pequeño en la parte superior durante conversación
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: WarmiAvatar(
            avatarState: state.avatarState,
            soundLevel: state.soundLevel,
            size: 90,
          ),
        ),
        // Lista de mensajes
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            itemCount: state.messages.length,
            itemBuilder: (_, i) => ChatBubble(message: state.messages[i]),
          ),
        ),
      ],
    );
  }
}

// ── AppBar personalizado ──────────────────────────────────────────────────────

class _WarmiAppBar extends StatelessWidget {
  final AssistantState state;
  const _WarmiAppBar({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Menú
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              color: AppColors.textSecondary,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

            // Logo + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'WarmiBot',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Tu asistente inteligente',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const BackendStatusIndicator(),
                ],
              ),
            ),

            // Notificaciones
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  color: AppColors.textSecondary,
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            // Avatar de perfil
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.avatarGradient,
                  ),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
