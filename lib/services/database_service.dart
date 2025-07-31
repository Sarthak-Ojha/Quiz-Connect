// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'app_database.db';
  static const int _databaseVersion = 1;

  // Tables
  static const String _usersTable = 'users';
  static const String _settingsTable = 'settings';

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE $_usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT UNIQUE NOT NULL,
        email TEXT NOT NULL,
        displayName TEXT,
        photoURL TEXT,
        emailVerified INTEGER DEFAULT 0,
        lastSignIn TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE $_settingsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
  CREATE TABLE questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL,
    question TEXT NOT NULL,
    options TEXT NOT NULL,   -- store options as JSON string
    correctIndex INTEGER NOT NULL
  );
''');
    Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correctIndex INTEGER NOT NULL
      );
    ''');
      }
    } // Insert a question

    Future<int> insertQuestion(Question question) async {
      final db = await database;
      return await db.insert('questions', question.toMap());
    }

    // Retrieve questions by category with optional limit
    Future<List<Question>> getQuestionsByCategory(
      String category, {
      int limit = 10,
    }) async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'questions',
        where: 'category = ?',
        whereArgs: [category],
        limit: limit,
      );
      return maps.map((map) => Question.fromMap(map)).toList();
    }

    // Insert default settings
    await db.insert(_settingsTable, {'key': 'theme', 'value': 'light'});

    await db.insert(_settingsTable, {'key': 'notifications', 'value': 'true'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  // Initialize database (call this in main.dart)
  Future<void> initializeDatabase() async {
    await database;
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      _usersTable,
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _usersTable,
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query(_usersTable);
  }

  Future<int> updateUser(String uid, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update(
      _usersTable,
      user,
      where: 'uid = ?',
      whereArgs: [uid],
    );
  }

  Future<int> deleteUser(String uid) async {
    final db = await database;
    return await db.delete(_usersTable, where: 'uid = ?', whereArgs: [uid]);
  }

  // Settings operations
  Future<int> insertSetting(String key, String value) async {
    final db = await database;
    return await db.insert(_settingsTable, {
      'key': key,
      'value': value,
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _settingsTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return maps.isNotEmpty ? maps.first['value'] : null;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_settingsTable);
    return {for (var map in maps) map['key']: map['value']};
  }

  Future<int> updateSetting(String key, String value) async {
    final db = await database;
    return await db.update(
      _settingsTable,
      {'value': value, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<int> deleteSetting(String key) async {
    final db = await database;
    return await db.delete(_settingsTable, where: 'key = ?', whereArgs: [key]);
  }

  // Database utility methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_usersTable);
    await db.delete(_settingsTable);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
