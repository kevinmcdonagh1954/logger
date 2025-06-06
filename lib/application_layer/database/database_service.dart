import 'package:sqflite/sqflite.dart';

Future<void> _createPointsTable(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS points (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      comment TEXT NOT NULL,
      y REAL NOT NULL,
      x REAL NOT NULL,
      z REAL NOT NULL,
      descriptor TEXT,
      isDeleted INTEGER DEFAULT 0,
      isFixed INTEGER DEFAULT 0
    )
  ''');
}
