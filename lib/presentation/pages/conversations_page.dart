// ============================================================
// WarmiBot — ConversationsPage (historial de chat)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/assistant_bloc.dart';
import '../bloc/assistant_event.dart';
import '../bloc/assistant_state.dart';
import '../bloc/auth_cubit.dart';
import '../components/warmi_async_content.dart';
import '../components/warmi_message_card.dart';
import '../components/warmi_page_scaffold.dart';
import '../../domain/models/chat_message.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantBloc, AssistantState>(
      builder: (context, state) {
        final contentState = state.messages.isNotEmpty
            ? WarmiContentState.content
            : state.errorMessage != null
                ? WarmiContentState.error
                : state.isProcessing
                    ? WarmiContentState.loading
                    : WarmiContentState.empty;

        return ConversationsView(
          messages: state.messages,
          contentState: contentState,
          errorMessage: state.errorMessage,
          onRetry: () =>
              context.read<AssistantBloc>().add(const InitAssistant()),
          onClear: state.messages.isEmpty ? null : () => _confirmClear(context),
        );
      },
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Limpiar historial',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('¿Eliminar todos los mensajes de esta sesión?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AssistantBloc>().add(const ClearChat());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCoral),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}

/// Vista pura: recibe datos y callbacks; no conoce BLoC, backend ni rutas.
class ConversationsView extends StatelessWidget {
  final List<ChatMessage> messages;
  final WarmiContentState contentState;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onClear;

  const ConversationsView({
    super.key,
    required this.messages,
    required this.contentState,
    this.errorMessage,
    this.onRetry,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return WarmiPageScaffold(
      title: 'Conversaciones',
      description: 'Historial de mensajes intercambiados con WarmiBot.',
      actions: [
        if (onClear != null)
          IconButton(
            tooltip: 'Limpiar historial',
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
      child: WarmiAsyncContent(
        state: contentState,
        loadingLabel: 'Cargando conversaciones',
        emptyTitle: 'Sin conversaciones todavía',
        emptyMessage: 'Ve a Inicio y comienza a hablar con WarmiBot.',
        errorTitle: 'No se pudo mostrar el historial',
        errorMessage: errorMessage ?? 'Ocurrió un problema inesperado.',
        retryLabel: 'Intentar nuevamente',
        onRetry: onRetry,
        contentBuilder: (context) => ListView.builder(
          itemCount: messages.length,
          itemBuilder: (_, index) => WarmiMessageCard(message: messages[index]),
        ),
      ),
    );
  }
}

// ============================================================
// WarmiBot — ProfilePage (ajustes básicos)
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthCubit>().state.session;
    final user = session?.user;
    final initial = (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim()[0].toUpperCase()
        : 'W';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Encabezado ──────────────────────────────────────────────
          Center(
            child: Column(children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      const LinearGradient(colors: AppColors.avatarGradient),
                  border: Border.all(color: AppColors.accentGreen, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.displayName ?? 'Usuario de WarmiBot',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700)),
              Text(user?.email ?? 'Sesión no disponible',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(
                user?.isAdmin == true ? 'Rol: administrador' : 'Rol: usuario',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Secciones ────────────────────────────────────────────────
          _sectionTitle('Configuración', context),
          _tile(Icons.volume_up_rounded, 'Velocidad de voz',
              'Ajustar velocidad TTS', context),
          _tile(Icons.location_city_rounded, 'Ciudad por defecto',
              'Tena, Napo, Ecuador', context),
          _tile(Icons.contact_phone_rounded, 'Contactos',
              'Gestionar contactos WhatsApp', context),
          _tile(Icons.key_rounded, 'API Keys', 'OpenWeatherMap y más', context),

          const SizedBox(height: 16),
          _sectionTitle('Información', context),
          _tile(Icons.info_outline_rounded, 'Acerca de WarmiBot',
              'Universidad Estatal Amazónica', context),
          _tile(Icons.code_rounded, 'Tecnologías', 'Flutter · Dart · BLoC',
              context),
          _tile(Icons.translate_rounded, 'Identidad Kichwa',
              '"Warmi" = mujer, sabia, protectora', context),

          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: session == null ? null : () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
          ),

          const SizedBox(height: 24),
          // Versión
          Center(
            child: Text('WarmiBot © 2025 · UEA · Tena, Napo',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Deseas salir de WarmiBot? Para volver a las funciones protegidas tendrás que autenticarte nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthCubit>().signOut(
          message: 'Sesión cerrada. Credenciales y datos locales eliminados.',
        );
    if (context.mounted) context.go('/login');
  }

  Widget _sectionTitle(String title, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600)),
      );

  Widget _tile(
      IconData icon, String title, String subtitle, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.bgCard,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, color: AppColors.accentGreen, size: 22),
          title: Text(title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          subtitle: Text(subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
          onTap: () {},
        ),
      ),
    );
  }
}
