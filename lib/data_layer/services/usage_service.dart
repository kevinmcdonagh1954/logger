import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/usage_session.dart';

class UsageService {
  static Database? _database;
  static const String tableName = 'usage_sessions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'usage_sessions.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            jobName TEXT,
            startTime TEXT NOT NULL,
            endTime TEXT,
            duration INTEGER NOT NULL,
            latitude REAL,
            longitude REAL
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE $tableName
            ADD COLUMN latitude REAL
          ''');
          await db.execute('''
            ALTER TABLE $tableName
            ADD COLUMN longitude REAL
          ''');
        }
      },
    );
  }

  Future<int> insertSession(UsageSession session) async {
    final db = await database;
    return await db.insert(tableName, session.toMap());
  }

  Future<List<UsageSession>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) => UsageSession.fromMap(maps[i]));
  }

  Future<UsageSession?> getLastSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UsageSession.fromMap(maps.first);
  }

  Future<int> updateSession(UsageSession session) async {
    final db = await database;
    return await db.update(
      tableName,
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<UsageSession>> getSessionsByJob(String jobName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'jobName = ?',
      whereArgs: [jobName],
    );
    return List.generate(maps.length, (i) => UsageSession.fromMap(maps[i]));
  }

  Future<Duration> getTotalDurationByJob(String jobName) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(duration) as total FROM $tableName WHERE jobName = ?',
      [jobName],
    );
    final total = result.first['total'] as int?;
    return Duration(seconds: total ?? 0);
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
