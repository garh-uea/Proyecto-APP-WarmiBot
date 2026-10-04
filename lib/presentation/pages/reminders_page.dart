import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models/reminder.dart';
import '../../domain/services/alarm_service.dart';
import '../../domain/services/device_capability_service.dart';
import '../../infrastructure/repositories/reminders_repository.dart';
import '../bloc/auth_cubit.dart';
import '../widgets/capability_permission_prompt.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _repo = RemindersRepository.instance;
  List<Reminder> _reminders = [];
  ReminderSyncSnapshot? _sync;
  bool _loading = true;
  bool _refreshing = false;
  Timer? _timer;
  StreamSubscription<ReminderSyncSnapshot>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _syncSubscription = _repo.syncChanges.listen((snapshot) {
      if (!mounted) return;
      setState(() => _sync = snapshot);
      _loadLocal(showLoading: false);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAndSync());
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshAndSync(showLoading: false),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLocal({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    final all = await _repo.getAll();
    final sync = await _repo.snapshot();
    if (!mounted) return;
    setState(() {
      _reminders = all;
      _sync = sync;
      _loading = false;
    });
  }

  Future<void> _refreshAndSync({bool showLoading = true}) async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _loadLocal(showLoading: showLoading);
      if (!mounted) return;
      final auth = context.read<AuthCubit>();
      final token = auth.state.session?.accessToken;
      if (token != null) {
        final result = await _repo.synchronize(token);
        if (result.authenticationRequired) {
          final renewed = await auth.renewSession();
          if (renewed != null) {
            await _repo.synchronize(renewed.accessToken);
          }
        }
      }
      await _loadLocal(showLoading: false);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _createReminder() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo recordatorio'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                maxLength: 120,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '¿Qué deseas recordar?',
                  hintText: 'Ejemplo: presentar WarmiBot',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe el contenido del recordatorio.'
                    : null,
                onFieldSubmitted: (_) {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(dialogContext, controller.text.trim());
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text('Se programará automáticamente dentro de una hora.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
    // Espera a que termine la animación inversa del diálogo antes de iniciar
    // cualquier solicitud nativa de permisos.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
    if (text == null || !mounted) return;

    final reminder = await _repo.insert(
      Reminder(
        text: text,
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    if (!mounted) return;
    final notificationAllowed = await CapabilityPermissionPrompt.ensure(
      context,
      DeviceCapability.notifications,
    );
    var notificationScheduled = false;
    if (notificationAllowed) {
      try {
        await AlarmService.instance.scheduleReminder(reminder);
        notificationScheduled = true;
      } catch (_) {
        // El registro y su operación de salida ya están en SQLite.
      }
    }
    await _loadLocal(showLoading: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notificationScheduled
              ? 'Guardado en el dispositivo. Se enviará cuando exista conexión.'
              : 'Guardado localmente. Activa notificaciones para recibir la alerta.',
        ),
      ),
    );
    await _refreshAndSync(showLoading: false);
  }

  Future<void> _delete(Reminder reminder) async {
    if (reminder.id == null) return;
    await AlarmService.instance.cancel(reminder.id!);
    await _repo.delete(reminder.id!);
    await _refreshAndSync(showLoading: false);
  }

  Future<void> _complete(Reminder reminder) async {
    if (reminder.id == null) return;
    await AlarmService.instance.cancel(reminder.id!);
    await _repo.markCompleted(reminder.id!);
    await _refreshAndSync(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Recordatorios'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sincronizar ahora',
            onPressed: () => _refreshAndSync(showLoading: false),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Eliminar completados',
            onPressed: () async {
              await _repo.deleteCompleted();
              await _refreshAndSync(showLoading: false);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createReminder,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo'),
      ),
      body: Column(
        children: [
          _SyncBanner(snapshot: _sync),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentGreen,
                    ),
                  )
                : _reminders.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    onRefresh: () => _refreshAndSync(showLoading: false),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                      itemCount: _reminders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _ReminderCard(
                        reminder: _reminders[index],
                        onComplete: () => _complete(_reminders[index]),
                        onDelete: () => _delete(_reminders[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📌', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          'Sin recordatorios todavía',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Text(
          'Puedes crear uno incluso sin conexión.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

class _SyncBanner extends StatelessWidget {
  final ReminderSyncSnapshot? snapshot;

  const _SyncBanner({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final value = snapshot;
    final online = value?.online ?? true;
    final syncing = value?.syncing ?? true;
    final color = online ? AppColors.accentGreen : AppColors.accentCoral;
    final age = _formatAge(value?.lastSuccessfulSync);
    final pending = value?.pending ?? 0;
    final failed = value?.failed ?? 0;
    final title = syncing
        ? 'Comprobando conexión'
        : online
        ? 'En línea · datos sincronizados'
        : 'Sin conexión · datos locales desactualizados';
    final detail = [
      'Última sincronización: $age',
      if (pending > 0) '$pending pendiente(s)',
      if (failed > 0) '$failed sin enviar tras 5 intentos',
    ].join(' · ');

    return Semantics(
      liveRegion: true,
      label: '$title. $detail',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            if (syncing)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(
                online ? Icons.cloud_done_outlined : Icons.cloud_off,
                color: color,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatAge(DateTime? value) {
    if (value == null) return 'nunca';
    final difference = DateTime.now().toUtc().difference(value.toUtc());
    if (difference.inMinutes < 1) return 'hace menos de un minuto';
    if (difference.inHours < 1) return 'hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'hace ${difference.inHours} h';
    return 'hace ${difference.inDays} día(s)';
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM · h:mm a', 'es');
    final past = reminder.scheduledAt.isBefore(DateTime.now());
    final syncText = switch (reminder.syncStatus) {
      ReminderSyncStatus.pending => 'Pendiente de envío',
      ReminderSyncStatus.synced => 'Sincronizado',
      ReminderSyncStatus.failed => 'No enviado',
    };
    final syncColor = switch (reminder.syncStatus) {
      ReminderSyncStatus.pending => AppColors.accentCoral,
      ReminderSyncStatus.synced => AppColors.accentGreen,
      ReminderSyncStatus.failed => Colors.redAccent,
    };

    return Material(
      color: AppColors.bgCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: syncColor.withValues(alpha: 0.45)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _typeColor(reminder.type).withValues(alpha: 0.15),
          child: Text(_typeIcon(reminder.type)),
        ),
        title: Text(
          reminder.text,
          style: TextStyle(
            color: reminder.isCompleted
                ? AppColors.textMuted
                : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            decoration: reminder.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fmt.format(reminder.scheduledAt),
                style: TextStyle(
                  color: past && !reminder.isCompleted
                      ? AppColors.accentCoral
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: syncColor),
                  const SizedBox(width: 5),
                  Text(
                    syncText,
                    style: TextStyle(color: syncColor, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reminder.isCompleted)
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.accentGreen,
                ),
                onPressed: onComplete,
                tooltip: 'Completar',
              ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.accentCoral,
              ),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(ReminderType type) => switch (type) {
    ReminderType.alarm => AppColors.accentCoral,
    ReminderType.timer => AppColors.accentTeal,
    ReminderType.reminder => AppColors.accentGreen,
  };

  String _typeIcon(ReminderType type) => switch (type) {
    ReminderType.alarm => '⏰',
    ReminderType.timer => '⏱',
    ReminderType.reminder => '📌',
  };
}
