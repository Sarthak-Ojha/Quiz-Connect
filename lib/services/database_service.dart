import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'app_database.db';
  static const int _databaseVersion = 3; // Increment for quiz_results table

  // Tables
  static const String _usersTable = 'users';
  static const String _settingsTable = 'settings';
  static const String _questionsTable = 'questions';
  static const String _quizResultsTable = 'quiz_results';

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

    // Create questions table
    await db.execute('''
      CREATE TABLE $_questionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correctIndex INTEGER NOT NULL
      )
    ''');

    // Create quiz results table
    await db.execute('''
      CREATE TABLE $_quizResultsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        categoryName TEXT NOT NULL,
        categoryColor TEXT,
        totalQuestions INTEGER NOT NULL,
        correctAnswers INTEGER NOT NULL,
        wrongAnswers INTEGER NOT NULL,
        totalScore INTEGER NOT NULL,
        percentage REAL NOT NULL,
        isTimerMode INTEGER NOT NULL,
        timerSeconds INTEGER DEFAULT 0,
        completedAt TEXT NOT NULL,
        userAnswers TEXT NOT NULL,
        questions TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert(_settingsTable, {'key': 'theme', 'value': 'light'});
    await db.insert(_settingsTable, {'key': 'notifications', 'value': 'true'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add questions table for version 2
      await db.execute('''
        CREATE TABLE $_questionsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          question TEXT NOT NULL,
          options TEXT NOT NULL,
          correctIndex INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add quiz results table for version 3
      await db.execute('''
        CREATE TABLE $_quizResultsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          categoryName TEXT NOT NULL,
          categoryColor TEXT,
          totalQuestions INTEGER NOT NULL,
          correctAnswers INTEGER NOT NULL,
          wrongAnswers INTEGER NOT NULL,
          totalScore INTEGER NOT NULL,
          percentage REAL NOT NULL,
          isTimerMode INTEGER NOT NULL,
          timerSeconds INTEGER DEFAULT 0,
          completedAt TEXT NOT NULL,
          userAnswers TEXT NOT NULL,
          questions TEXT NOT NULL
        )
      ''');
    }
  }

  // Initialize database
  Future<void> initializeDatabase() async {
    await database;
  }

  // ===============================================================================
  // QUIZ RESULTS METHODS
  // ===============================================================================

  // Save quiz result
  Future<int> saveQuizResult(QuizResult result) async {
    final db = await database;
    return await db.insert(_quizResultsTable, result.toMap());
  }

  // Get all quiz results for a user
  Future<List<QuizResult>> getUserQuizResults(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _quizResultsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  // Get quiz results by category
  Future<List<QuizResult>> getUserQuizResultsByCategory(
    String userId,
    String categoryName,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _quizResultsTable,
      where: 'userId = ? AND categoryName = ?',
      whereArgs: [userId, categoryName],
      orderBy: 'completedAt DESC',
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final db = await database;

    // Total quizzes completed
    final totalQuizzesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final totalQuizzes = totalQuizzesResult.first['count'] as int;

    // Total score
    final totalScoreResult = await db.rawQuery(
      'SELECT SUM(totalScore) as total FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final totalScore = (totalScoreResult.first['total'] as int?) ?? 0;

    // Average percentage
    final avgPercentageResult = await db.rawQuery(
      'SELECT AVG(percentage) as avg FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final avgPercentage = (avgPercentageResult.first['avg'] as double?) ?? 0.0;

    // Best score
    final bestScoreResult = await db.rawQuery(
      'SELECT MAX(totalScore) as best FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final bestScore = (bestScoreResult.first['best'] as int?) ?? 0;

    // Category stats
    final categoryStatsResult = await db.rawQuery(
      '''
      SELECT 
        categoryName,
        COUNT(*) as playCount,
        AVG(percentage) as avgPercentage,
        MAX(totalScore) as bestScore
      FROM $_quizResultsTable 
      WHERE userId = ? 
      GROUP BY categoryName
      ORDER BY playCount DESC
    ''',
      [userId],
    );

    return {
      'totalQuizzes': totalQuizzes,
      'totalScore': totalScore,
      'averagePercentage': avgPercentage,
      'bestScore': bestScore,
      'categoryStats': categoryStatsResult,
      // For backward compatibility with your UserData model
      'quizzesCompleted': totalQuizzes,
      'totalCoins': totalScore ~/ 2, // Derive coins from score
    };
  }

  // Get recent quiz results (last 10)
  Future<List<QuizResult>> getRecentQuizResults(
    String userId, {
    int limit = 10,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _quizResultsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
      limit: limit,
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  // Delete quiz result
  Future<int> deleteQuizResult(int id) async {
    final db = await database;
    return await db.delete(_quizResultsTable, where: 'id = ?', whereArgs: [id]);
  }

  // Clear all quiz results for a user
  Future<int> clearUserQuizResults(String userId) async {
    final db = await database;
    return await db.delete(
      _quizResultsTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ===============================================================================
  // QUESTION METHODS
  // ===============================================================================

  // Insert a question
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert(_questionsTable, question.toMap());
  }

  // Get questions by category
  Future<List<Question>> getQuestionsByCategory(
    String category, {
    int limit = 10,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _questionsTable,
      where: 'category = ?',
      whereArgs: [category],
      limit: limit,
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  // Get random questions by category
  Future<List<Question>> getRandomQuestionsByCategory(
    String category, {
    int limit = 10,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT * FROM $_questionsTable
      WHERE category = ?
      ORDER BY RANDOM()
      LIMIT ?
      ''',
      [category, limit],
    );
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  // Get all questions
  Future<List<Question>> getAllQuestions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_questionsTable);
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  // ===============================================================================
  // USER METHODS
  // ===============================================================================

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

  // ===============================================================================
  // SETTINGS METHODS
  // ===============================================================================

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

  // ===============================================================================
  // UTILITY METHODS
  // ===============================================================================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_usersTable);
    await db.delete(_settingsTable);
    await db.delete(_questionsTable);
    await db.delete(_quizResultsTable);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
