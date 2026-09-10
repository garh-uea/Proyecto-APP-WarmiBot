import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/reminder.dart';
import '../../domain/services/backend_api_service.dart';

class ReminderSyncSnapshot {
  final bool online;
  final bool syncing;
  final int pending;
  final int failed;
  final bool authenticationRequired;
  final DateTime? lastSuccessfulSync;
  final String? message;

  const ReminderSyncSnapshot({
    required this.online,
    required this.syncing,
    required this.pending,
    required this.failed,
    this.authenticationRequired = false,
    this.lastSuccessfulSync,
    this.message,
  });
}

class RemindersRepository {
  RemindersRepository._({BackendApiService? api})
      : _api = api ?? BackendApiService();

  static final RemindersRepository instance = RemindersRepository._();
  static const databaseVersion = 2;
  static const maxSyncAttempts = 5;

  final BackendApiService _api;
  final Random _random = Random.secure();
  final StreamController<ReminderSyncSnapshot> _syncController =
      StreamController<ReminderSyncSnapshot>.broadcast();

  Database? _db;
  bool _online = true;
  bool _syncing = false;
  String? _lastMessage;
  bool _authenticationRequired = false;

  Stream<ReminderSyncSnapshot> get syncChanges => _syncController.stream;

  Future<String> get _databasePath async =>
      p.join(await getDatabasesPath(), 'warmibot.db');

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      await _databasePath,
      version: databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => _createSchema(db),
      onUpgrade: _migrate,
    );
    return _db!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL UNIQUE,
        server_id INTEGER,
        server_version INTEGER NOT NULL DEFAULT 0,
        text TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        type INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        last_synced_at TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await _createAuxiliaryTables(db);
  }

  Future<void> _createAuxiliaryTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL UNIQUE,
        entity_type TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        next_retry_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        last_error TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_metadata (
        metadata_key TEXT PRIMARY KEY,
        metadata_value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_pending_retry
      ON pending_operations(attempts, next_retry_at)
    ''');
  }

  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= 2) return;
    await db.execute(
      "ALTER TABLE reminders ADD COLUMN client_id TEXT NOT NULL DEFAULT ''",
    );
    await db.execute('ALTER TABLE reminders ADD COLUMN server_id INTEGER');
    await db.execute(
      'ALTER TABLE reminders ADD COLUMN server_version INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      "ALTER TABLE reminders ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
    );
    await db.execute('ALTER TABLE reminders ADD COLUMN last_synced_at TEXT');
    await db.execute(
      "ALTER TABLE reminders ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'pending'",
    );
    await db.execute(
      'ALTER TABLE reminders ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
    );

    final rows = await db.query('reminders', columns: ['id', 'scheduled_at']);
    for (final row in rows) {
      final id = row['id'] as int;
      await db.update(
        'reminders',
        {
          'client_id': 'legacy-$id-${DateTime.now().microsecondsSinceEpoch}',
          'updated_at': row['scheduled_at'] as String,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_reminders_client_id
      ON reminders(client_id)
    ''');
    await _createAuxiliaryTables(db);

    final migrated = await db.query('reminders');
    for (final row in migrated) {
      await _enqueue(db, Reminder.fromMap(row), 'upsert');
    }
  }

  String _newClientId() {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    final entropy = _random.nextInt(0x7fffffff).toRadixString(16);
    return 'warmibot-$now-$entropy';
  }

  Future<List<Reminder>> getAll() async {
    final db = await _database;
    final maps = await db.query(
      'reminders',
      where: 'is_deleted = 0',
      orderBy: 'scheduled_at ASC',
    );
    return maps.map(Reminder.fromMap).toList();
  }

  Future<List<Reminder>> getPending() async {
    final db = await _database;
    final maps = await db.query(
      'reminders',
      where: 'is_completed = 0 AND is_deleted = 0 AND scheduled_at > ?',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'scheduled_at ASC',
    );
    return maps.map(Reminder.fromMap).toList();
  }

  Future<Reminder> insert(Reminder reminder) async {
    final db = await _database;
    final local = reminder.copyWith(
      clientId: reminder.clientId.isEmpty ? _newClientId() : reminder.clientId,
      updatedAt: DateTime.now().toUtc(),
      syncStatus: ReminderSyncStatus.pending,
    );
    late int id;
    await db.transaction((txn) async {
      id = await txn.insert('reminders', local.toMap());
      await _enqueue(txn, local.copyWith(id: id), 'upsert');
    });
    await _publishSnapshot();
    return local.copyWith(id: id);
  }

  Future<void> markCompleted(int id) async {
    final reminder = await _findById(id);
    if (reminder == null) return;
    await _savePending(
      reminder.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now().toUtc(),
        syncStatus: ReminderSyncStatus.pending,
      ),
      operation: 'upsert',
    );
  }

  Future<void> delete(int id) async {
    final reminder = await _findById(id);
    if (reminder == null) return;
    await _savePending(
      reminder.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now().toUtc(),
        syncStatus: ReminderSyncStatus.pending,
      ),
      operation: 'delete',
    );
  }

  Future<void> deleteCompleted() async {
    final db = await _database;
    final rows = await db.query(
      'reminders',
      where: 'is_completed = 1 AND is_deleted = 0',
    );
    for (final row in rows) {
      await delete(Reminder.fromMap(row).id!);
    }
  }

  Future<Reminder?> _findById(int id) async {
    final db = await _database;
    final rows = await db.query('reminders', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Reminder.fromMap(rows.first);
  }

  Future<void> _savePending(
    Reminder reminder, {
    required String operation,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.update(
        'reminders',
        reminder.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [reminder.id],
      );
      await _enqueue(txn, reminder, operation);
    });
    await _publishSnapshot();
  }

  Future<void> _enqueue(
    DatabaseExecutor db,
    Reminder reminder,
    String operation,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      'pending_operations',
      {
        'client_id': reminder.clientId,
        'entity_type': 'reminder',
        'operation_type': operation,
        'payload_json': jsonEncode(_syncPayload(reminder, operation)),
        'attempts': 0,
        'next_retry_at': now,
        'created_at': now,
        'last_error': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> _syncPayload(Reminder reminder, String operation) => {
        'client_id': reminder.clientId,
        'operation': operation,
        'text': reminder.text,
        'scheduled_at': reminder.scheduledAt.toUtc().toIso8601String(),
        'reminder_type': reminder.type.name,
        'is_completed': reminder.isCompleted,
        'base_version': reminder.serverVersion,
        'client_updated_at':
            reminder.effectiveUpdatedAt.toUtc().toIso8601String(),
      };

  static Duration retryDelayForAttempt(int attempt) {
    final exponent = attempt.clamp(1, maxSyncAttempts);
    return Duration(seconds: min(32, 1 << exponent));
  }

  Future<ReminderSyncSnapshot> synchronize(String accessToken) async {
    if (_syncing) return snapshot();
    _syncing = true;
    await _publishSnapshot();
    final db = await _database;
    var sent = 0;
    var conflicts = 0;
    try {
      final connectivityMetadata = await db.query(
        'local_metadata',
        columns: ['metadata_value'],
        where: 'metadata_key = ?',
        whereArgs: ['last_connectivity'],
        limit: 1,
      );
      final wasOffline = connectivityMetadata.isNotEmpty &&
          connectivityMetadata.first['metadata_value'] == 'offline';
      // Si la cola agotó sus intentos mientras no había red, una consulta
      // liviana detecta la recuperación y habilita un nuevo ciclo completo.
      if (!_online || _authenticationRequired || wasOffline) {
        await _api.listReminders(accessToken);
        final now = DateTime.now().toUtc().toIso8601String();
        await db.update(
          'pending_operations',
          {
            'attempts': 0,
            'next_retry_at': now,
            'last_error': null,
          },
          where: 'attempts >= ?',
          whereArgs: [maxSyncAttempts],
        );
        await db.update(
          'reminders',
          {'sync_status': 'pending'},
          where: 'sync_status = ?',
          whereArgs: ['failed'],
        );
      }

      final queue = await db.query(
        'pending_operations',
        where: 'attempts < ? AND next_retry_at <= ?',
        whereArgs: [
          maxSyncAttempts,
          DateTime.now().toUtc().toIso8601String(),
        ],
        orderBy: 'created_at ASC',
      );

      for (final operation in queue) {
        final payload = jsonDecode(operation['payload_json'] as String)
            as Map<String, dynamic>;
        try {
          final remote = await _api.syncReminder(
            accessToken: accessToken,
            payload: payload,
          );
          await db.transaction((txn) async {
            await _applyRemote(txn, remote);
            await txn.delete(
              'pending_operations',
              where: 'id = ?',
              whereArgs: [operation['id']],
            );
          });
          sent++;
        } on BackendApiException catch (error) {
          final server = _serverCopyFromConflict(error);
          if (error.statusCode == 409 && server != null) {
            await db.transaction((txn) async {
              await _applyRemote(txn, server);
              await txn.delete(
                'pending_operations',
                where: 'id = ?',
                whereArgs: [operation['id']],
              );
            });
            conflicts++;
            continue;
          }
          await _registerFailure(db, operation, error.message);
          if (error.statusCode == null) rethrow;
        }
      }

      final remoteItems = await _api.listReminders(accessToken);
      await db.transaction((txn) async {
        for (final remote in remoteItems) {
          final local = await txn.query(
            'reminders',
            columns: ['sync_status'],
            where: 'client_id = ?',
            whereArgs: [remote.clientId],
          );
          if (local.isEmpty || local.first['sync_status'] == 'synced') {
            await _applyRemote(txn, remote);
          }
        }
        await _setMetadata(
          txn,
          'last_successful_sync',
          DateTime.now().toUtc().toIso8601String(),
        );
        await _setMetadata(txn, 'last_connectivity', 'online');
      });
      _online = true;
      _authenticationRequired = false;
      _lastMessage = conflicts > 0
          ? '$conflicts conflicto(s) resuelto(s) con la copia del servidor.'
          : sent > 0
              ? '$sent operación(es) sincronizada(s).'
              : 'Datos sincronizados.';
    } on BackendApiException catch (error) {
      _online = error.statusCode != null;
      _authenticationRequired = error.isUnauthorized;
      await _setMetadata(
        db,
        'last_connectivity',
        _online ? 'online' : 'offline',
      );
      _lastMessage = _online
          ? error.message
          : 'Sin conexión. Se muestran y guardan datos locales.';
    } catch (_) {
      _online = false;
      _authenticationRequired = false;
      await _setMetadata(db, 'last_connectivity', 'offline');
      _lastMessage = 'Sin conexión. Se muestran y guardan datos locales.';
    } finally {
      _syncing = false;
      await _publishSnapshot();
    }
    return snapshot();
  }

  BackendReminder? _serverCopyFromConflict(BackendApiException error) {
    final detail = error.payload?['detail'];
    if (detail is! Map<String, dynamic>) return null;
    final server = detail['server'];
    return server is Map<String, dynamic>
        ? BackendReminder.fromJson(server)
        : null;
  }

  Future<void> _registerFailure(
    Database db,
    Map<String, Object?> operation,
    String message,
  ) async {
    final nextAttempt = (operation['attempts'] as int) + 1;
    await db.update(
      'pending_operations',
      {
        'attempts': nextAttempt,
        'next_retry_at': DateTime.now()
            .toUtc()
            .add(retryDelayForAttempt(nextAttempt))
            .toIso8601String(),
        'last_error': message,
      },
      where: 'id = ?',
      whereArgs: [operation['id']],
    );
    await db.update(
      'reminders',
      {'sync_status': nextAttempt >= maxSyncAttempts ? 'failed' : 'pending'},
      where: 'client_id = ?',
      whereArgs: [operation['client_id']],
    );
  }

  Future<void> _applyRemote(
    DatabaseExecutor db,
    BackendReminder remote,
  ) async {
    final typeIndex = ReminderType.values.indexWhere(
      (type) => type.name == remote.reminderType,
    );
    final values = {
      'client_id': remote.clientId,
      'server_id': remote.id,
      'server_version': remote.version,
      'text': remote.text,
      'scheduled_at': remote.scheduledAt.toLocal().toIso8601String(),
      'type': typeIndex < 0 ? ReminderType.reminder.index : typeIndex,
      'is_completed': remote.isCompleted ? 1 : 0,
      'updated_at': remote.clientUpdatedAt.toUtc().toIso8601String(),
      'last_synced_at': DateTime.now().toUtc().toIso8601String(),
      'sync_status': 'synced',
      'is_deleted': remote.deleted ? 1 : 0,
    };
    await db.insert(
      'reminders',
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.update(
      'reminders',
      values,
      where: 'client_id = ?',
      whereArgs: [remote.clientId],
    );
  }

  Future<void> _setMetadata(
    DatabaseExecutor db,
    String key,
    String value,
  ) async {
    await db.insert(
      'local_metadata',
      {'metadata_key': key, 'metadata_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReminderSyncSnapshot> snapshot() async {
    final db = await _database;
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM pending_operations WHERE attempts < ?',
      [maxSyncAttempts],
    );
    final failedResult = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM pending_operations WHERE attempts >= ?',
      [maxSyncAttempts],
    );
    final metadata = await db.query(
      'local_metadata',
      where: 'metadata_key = ?',
      whereArgs: ['last_successful_sync'],
      limit: 1,
    );
    final lastSync = metadata.isEmpty
        ? null
        : DateTime.tryParse(metadata.first['metadata_value'] as String);
    return ReminderSyncSnapshot(
      online: _online,
      syncing: _syncing,
      pending: pendingResult.first['total'] as int? ?? 0,
      failed: failedResult.first['total'] as int? ?? 0,
      authenticationRequired: _authenticationRequired,
      lastSuccessfulSync: lastSync,
      message: _lastMessage,
    );
  }

  Future<void> _publishSnapshot() async {
    if (!_syncController.isClosed) _syncController.add(await snapshot());
  }

  Future<void> clearAllLocalData() async {
    final database = _db;
    _db = null;
    if (database != null && database.isOpen) await database.close();
    await deleteDatabase(await _databasePath);
    _online = true;
    _syncing = false;
    _lastMessage = null;
    _authenticationRequired = false;
  }
}
