// ============================================================
// WarmiBot — Repositorio de Recordatorios (SQLite)
// Equivalente a: lista RECORDATORIOS en RAM de Python, pero
// con persistencia real entre sesiones
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/reminder.dart';

class RemindersRepository {
  RemindersRepository._();
  static final RemindersRepository instance = RemindersRepository._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = p.join(await getDatabasesPath(), 'warmibot.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            text        TEXT    NOT NULL,
            scheduled_at TEXT   NOT NULL,
            type        INTEGER NOT NULL DEFAULT 0,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<List<Reminder>> getAll() async {
    final db   = await _database;
    final maps = await db.query(
      'reminders',
      orderBy: 'scheduled_at ASC',
    );
    return maps.map(Reminder.fromMap).toList();
  }

  Future<List<Reminder>> getPending() async {
    final db   = await _database;
    final now  = DateTime.now().toIso8601String();
    final maps = await db.query(
      'reminders',
      where:     'is_completed = 0 AND scheduled_at > ?',
      whereArgs: [now],
      orderBy:   'scheduled_at ASC',
    );
    return maps.map(Reminder.fromMap).toList();
  }

  Future<Reminder> insert(Reminder reminder) async {
    final db = await _database;
    final id = await db.insert('reminders', reminder.toMap());
    return reminder.copyWith(id: id);
  }

  Future<void> markCompleted(int id) async {
    final db = await _database;
    await db.update(
      'reminders',
      {'is_completed': 1},
      where:     'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCompleted() async {
    final db = await _database;
    await db.delete('reminders', where: 'is_completed = 1');
  }
}
