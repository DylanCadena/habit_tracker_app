import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // SUBIMOS VERSIÓN A 5
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE habits (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      isCompleted INTEGER NOT NULL,
      orderIndex INTEGER NOT NULL DEFAULT 0,
      colorValue INTEGER NOT NULL DEFAULT 4289552163,
      iconCode INTEGER NOT NULL DEFAULT 58876,
      groupId TEXT NOT NULL DEFAULT ''
    )
    ''');

    await db.execute('''
    CREATE TABLE habit_groups (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      orderIndex INTEGER NOT NULL DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE stats (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      streak INTEGER NOT NULL,
      lastDate TEXT NOT NULL,
      lastStreakDate TEXT NOT NULL DEFAULT ''
    )
    ''');

    await db.insert('stats', {
      'id': 1,
      'streak': 0,
      'lastDate': '',
      'lastStreakDate': '',
    });
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE habits ADD COLUMN orderIndex INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE stats ADD COLUMN lastStreakDate TEXT NOT NULL DEFAULT ""',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE habits ADD COLUMN colorValue INTEGER NOT NULL DEFAULT 4289552163',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE habits ADD COLUMN iconCode INTEGER NOT NULL DEFAULT 58876',
      );
    }
    if (oldVersion < 5) {
      // MIGRACIÓN VERSIÓN 5: Añadimos tabla de grupos y la referencia en los hábitos
      await db.execute(
        'ALTER TABLE habits ADD COLUMN groupId TEXT NOT NULL DEFAULT ""',
      );
      await db.execute('''
      CREATE TABLE habit_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        orderIndex INTEGER NOT NULL DEFAULT 0
      )
      ''');
    }
  }

  Future<List<HabitGroup>> readAllGroups() async {
    final db = await instance.database;
    final result = await db.query(
      'habit_groups',
      orderBy: 'orderIndex ASC, id ASC',
    );
    return result.map((json) => HabitGroup.fromMap(json)).toList();
  }

  Future<void> insertGroup(HabitGroup group) async {
    final db = await instance.database;
    await db.insert(
      'habit_groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateGroup(HabitGroup group) async {
    final db = await instance.database;
    await db.update(
      'habit_groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<void> deleteGroup(String id) async {
    final db = await instance.database;
    await db.delete('habit_groups', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habit>> readAllHabits() async {
    final db = await instance.database;
    final result = await db.query('habits', orderBy: 'orderIndex ASC, id ASC');
    return result.map((json) => Habit.fromMap(json)).toList();
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await instance.database;
    await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await instance.database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> deleteHabit(String id) async {
    final db = await instance.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAllHabitsStatus(bool isCompleted) async {
    final db = await instance.database;
    await db.update('habits', {'isCompleted': isCompleted ? 1 : 0});
  }

  Future<void> updateHabitOrder(List<Habit> habits) async {
    final db = await instance.database;
    await db.transaction((transaction) async {
      for (var index = 0; index < habits.length; index++) {
        await transaction.update(
          'habits',
          {'orderIndex': index},
          where: 'id = ?',
          whereArgs: [habits[index].id],
        );
      }
    });
  }

  Future<void> updateGroupOrder(List<HabitGroup> groups) async {
    final db = await instance.database;
    await db.transaction((transaction) async {
      for (var index = 0; index < groups.length; index++) {
        await transaction.update(
          'habit_groups',
          {'orderIndex': index},
          where: 'id = ?',
          whereArgs: [groups[index].id],
        );
      }
    });
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await instance.database;
    final result = await db.query('stats', where: 'id = 1');
    if (result.isNotEmpty) return result.first;

    final defaultStats = {
      'id': 1,
      'streak': 0,
      'lastDate': '',
      'lastStreakDate': '',
    };
    await db.insert('stats', defaultStats);
    return defaultStats;
  }

  Future<void> updateStats(
    int streak,
    String lastDate,
    String lastStreakDate,
  ) async {
    final db = await instance.database;
    await db.update('stats', {
      'streak': streak,
      'lastDate': lastDate,
      'lastStreakDate': lastStreakDate,
    }, where: 'id = 1');
  }
}
