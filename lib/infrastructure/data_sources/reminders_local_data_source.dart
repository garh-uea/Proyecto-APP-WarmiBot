import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/reminder.dart';

class RemindersLocalDataSource {
  static const databaseVersion = 2;
  Database? _db;

  Future<String> get databasePath async =>
      p.join(await getDatabasesPath(), 'warmibot.db');

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      await databasePath,
      version: databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) => _createSchema(db),
      onUpgrade: _migrate,
    );
    return _db!;
  }

  Future<List<Reminder>> getAll() async {
    final db = await database;
    final rows = await db.query(
      'reminders',
      where: 'is_deleted = 0',
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  Future<List<Reminder>> getPending() async {
    final db = await database;
    final rows = await db.query(
      'reminders',
      where: 'is_completed = 0 AND is_deleted = 0 AND scheduled_at > ?',
      whereArgs: [DateTime.now().toIso8601String()],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  Future<Reminder?> findById(int id) async {
    final db = await database;
    final rows = await db.query('reminders', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Reminder.fromMap(rows.first);
  }

  Future<void> clearAll() async {
    final active = _db;
    _db = null;
    if (active != null && active.isOpen) await active.close();
    await deleteDatabase(await databasePath);
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
      final reminder = Reminder.fromMap(row);
      final now = DateTime.now().toUtc().toIso8601String();
      await db.insert(
        'pending_operations',
        {
          'client_id': reminder.clientId,
          'entity_type': 'reminder',
          'operation_type': 'upsert',
          'payload_json': jsonEncode({
            'client_id': reminder.clientId,
            'operation': 'upsert',
            'text': reminder.text,
            'scheduled_at': reminder.scheduledAt.toUtc().toIso8601String(),
            'reminder_type': reminder.type.name,
            'is_completed': reminder.isCompleted,
            'base_version': reminder.serverVersion,
            'client_updated_at':
                reminder.effectiveUpdatedAt.toUtc().toIso8601String(),
          }),
          'attempts': 0,
          'next_retry_at': now,
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
