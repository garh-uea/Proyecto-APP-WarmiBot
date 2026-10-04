import 'package:flutter_test/flutter_test.dart';
import 'package:warmibot/domain/models/reminder.dart';
import 'package:warmibot/infrastructure/repositories/reminders_repository.dart';

void main() {
  group('Sincronización sin conexión', () {
    test('usa espera creciente y respeta el máximo configurado', () {
      expect(RemindersRepository.retryDelayForAttempt(1).inSeconds, 2);
      expect(RemindersRepository.retryDelayForAttempt(2).inSeconds, 4);
      expect(RemindersRepository.retryDelayForAttempt(3).inSeconds, 8);
      expect(RemindersRepository.retryDelayForAttempt(4).inSeconds, 16);
      expect(RemindersRepository.retryDelayForAttempt(5).inSeconds, 32);
      expect(RemindersRepository.retryDelayForAttempt(8).inSeconds, 32);
      expect(RemindersRepository.maxSyncAttempts, 5);
    });

    test('restaura los metadatos de sincronización desde SQLite', () {
      final reminder = Reminder.fromMap(const {
        'id': 7,
        'client_id': 'warmibot-client-test',
        'server_id': 12,
        'server_version': 3,
        'text': 'Exponer el proyecto',
        'scheduled_at': '2026-09-06T15:00:00.000',
        'type': 0,
        'is_completed': 0,
        'updated_at': '2026-09-05T18:00:00.000Z',
        'last_synced_at': '2026-09-05T18:01:00.000Z',
        'sync_status': 'synced',
        'is_deleted': 0,
      });

      expect(reminder.clientId, 'warmibot-client-test');
      expect(reminder.serverVersion, 3);
      expect(reminder.syncStatus, ReminderSyncStatus.synced);
      expect(reminder.lastSyncedAt, isNotNull);
    });
  });
}
