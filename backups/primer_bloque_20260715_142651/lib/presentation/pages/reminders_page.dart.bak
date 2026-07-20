// ============================================================
// WarmiBot — RemindersPage
// Lista de recordatorios y alarmas guardados en SQLite
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/reminder.dart';
import '../../domain/services/alarm_service.dart';
import '../../infrastructure/repositories/reminders_repository.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _repo = RemindersRepository.instance;
  List<Reminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await _repo.getAll();
    setState(() { _reminders = all; _loading = false; });
  }

  Future<void> _delete(Reminder r) async {
    if (r.id == null) return;
    await AlarmService.instance.cancel(r.id!);
    await _repo.delete(r.id!);
    await _load();
  }

  Future<void> _complete(Reminder r) async {
    if (r.id == null) return;
    await _repo.markCompleted(r.id!);
    await _load();
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
            icon:      const Icon(Icons.delete_sweep_rounded),
            tooltip:   'Eliminar completados',
            onPressed: () async {
              await _repo.deleteCompleted();
              await _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen))
          : _reminders.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding:    const EdgeInsets.all(16),
                  itemCount:  _reminders.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _ReminderCard(
                        reminder:   _reminders[i],
                        onComplete: () => _complete(_reminders[i]),
                        onDelete:   () => _delete(_reminders[i]),
                      ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('📌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Sin recordatorios todavía',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Di "WarmiBot, recuérdame..."',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
        ]),
      );
}

class _ReminderCard extends StatelessWidget {
  final Reminder   reminder;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt  = DateFormat('EEE d MMM · h:mm a', 'es');
    final past = reminder.scheduledAt.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: reminder.isCompleted
              ? AppColors.textMuted.withValues(alpha: 0.2)
              : past
                  ? AppColors.accentCoral.withValues(alpha: 0.4)
                  : AppColors.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color:  _typeColor(reminder.type).withValues(alpha: 0.15),
            shape:  BoxShape.circle,
          ),
          child: Center(
            child: Text(_typeIcon(reminder.type),
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          reminder.text,
          style: TextStyle(
            color:     reminder.isCompleted
                ? AppColors.textMuted
                : AppColors.textPrimary,
            fontSize:  14,
            fontWeight: FontWeight.w500,
            decoration: reminder.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(Icons.schedule_rounded,
                size: 12, color: past && !reminder.isCompleted
                    ? AppColors.accentCoral
                    : AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              fmt.format(reminder.scheduledAt),
              style: TextStyle(
                fontSize: 11,
                color:    past && !reminder.isCompleted
                    ? AppColors.accentCoral
                    : AppColors.textMuted,
              ),
            ),
          ]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!reminder.isCompleted)
              IconButton(
                icon:     const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.accentGreen, size: 22),
                onPressed: onComplete,
                tooltip:  'Completar',
              ),
            IconButton(
              icon:     const Icon(Icons.delete_outline_rounded,
                  color: AppColors.accentCoral, size: 22),
              onPressed: onDelete,
              tooltip:  'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(ReminderType t) {
    switch (t) {
      case ReminderType.alarm:    return AppColors.accentCoral;
      case ReminderType.timer:    return AppColors.accentTeal;
      case ReminderType.reminder: return AppColors.accentGreen;
    }
  }

  String _typeIcon(ReminderType t) {
    switch (t) {
      case ReminderType.alarm:    return '⏰';
      case ReminderType.timer:    return '⏱';
      case ReminderType.reminder: return '📌';
    }
  }
}
