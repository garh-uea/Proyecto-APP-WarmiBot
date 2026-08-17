// ============================================================
// WarmiBot — ConversationsPage (historial de chat)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/assistant_bloc.dart';
import '../bloc/assistant_event.dart';
import '../bloc/assistant_state.dart';
import '../widgets/chat_bubble.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantBloc, AssistantState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Conversaciones'),
            backgroundColor: Colors.transparent,
            actions: [
              if (state.messages.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Limpiar historial',
                  onPressed: () => _confirmClear(context),
                ),
            ],
          ),
          body: state.messages.isEmpty
              ? _emptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: state.messages.length,
                  itemBuilder: (_, i) => ChatBubble(message: state.messages[i]),
                ),
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

  Widget _emptyState(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('💬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text('Sin conversaciones todavía',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Ve a Inicio y comienza a hablar con WarmiBot',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center),
        ]),
      );
}

// ============================================================
// WarmiBot — ProfilePage (ajustes básicos)
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(height: 12),
              Text('WarmiBot v1.0',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700)),
              Text('Asistente Virtual Amazónico',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textMuted)),
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
