import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/routine.dart';
import '../models/workout_record.dart';

class AppDatabase {
  static const _dbName = 'workout_coach.db';
  Database? _db;

  Future<Database> get _database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE routines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            days_per_week INTEGER NOT NULL,
            weekly_plan_json TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE workout_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            routine_id INTEGER NOT NULL,
            date TEXT NOT NULL,
            day_name TEXT NOT NULL,
            focus TEXT NOT NULL,
            exercises_json TEXT NOT NULL,
            completed_json TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<Routine?> getActiveRoutine() async {
    final db = await _database;
    final maps =
        await db.query('routines', orderBy: 'created_at DESC', limit: 1);
    if (maps.isEmpty) return null;
    return Routine.fromMap(maps.first);
  }

  Future<Routine> saveRoutine(Routine routine) async {
    final db = await _database;
    await db.delete('workout_records');
    await db.delete('routines');
    final id = await db.insert('routines', routine.toMap());
    return routine.copyWith(id: id);
  }

  Future<Routine> updateRoutine(Routine routine) async {
    final db = await _database;
    if (routine.id != null) {
      final map = routine.toMap()..remove('id');
      await db.update('routines', map, where: 'id = ?', whereArgs: [routine.id]);
      return routine;
    }
    final id = await db.insert('routines', routine.toMap());
    return routine.copyWith(id: id);
  }

  Future<List<WorkoutRecord>> getAllRecords() async {
    final db = await _database;
    final maps =
        await db.query('workout_records', orderBy: 'date DESC');
    return maps.map(WorkoutRecord.fromMap).toList();
  }

  Future<WorkoutRecord?> getRecordForDate(DateTime date) async {
    final db = await _database;
    final start =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59)
        .toIso8601String();
    final maps = await db.query(
      'workout_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return WorkoutRecord.fromMap(maps.first);
  }

  Future<int> insertRecord(WorkoutRecord record) async {
    final db = await _database;
    final start = DateTime(record.date.year, record.date.month, record.date.day)
        .toIso8601String();
    final end = DateTime(
            record.date.year, record.date.month, record.date.day, 23, 59, 59)
        .toIso8601String();
    await db.delete(
      'workout_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
    );
    return db.insert('workout_records', record.toMap());
  }

  Future<List<WorkoutRecord>> getRecordsForWeek(DateTime weekStart) async {
    final db = await _database;
    final start =
        DateTime(weekStart.year, weekStart.month, weekStart.day).toIso8601String();
    final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 6,
            23, 59, 59)
        .toIso8601String();
    final maps = await db.query(
      'workout_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'date ASC',
    );
    return maps.map(WorkoutRecord.fromMap).toList();
  }

  Future<void> clearAll() async {
    final db = await _database;
    await db.delete('workout_records');
    await db.delete('routines');
  }
}
