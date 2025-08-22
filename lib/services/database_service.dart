import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/user_streak.dart';
import '../models/daily_challenge.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'app_database.db';
  static const int _databaseVersion = 4;

  static const String _usersTable = 'users';
  static const String _settingsTable = 'settings';
  static const String _questionsTable = 'questions';
  static const String _quizResultsTable = 'quiz_results';
  static const String _userStreaksTable = 'user_streaks';
  static const String _dailyChallengesTable = 'daily_challenges';
  static const String _userChallengeProgressTable = 'user_challenge_progress';

  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
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
      );
    ''');

    await db.execute('''
      CREATE TABLE $_settingsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE $_questionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        correctIndex INTEGER NOT NULL
      );
    ''');

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
      );
    ''');

    await db.execute('''
      CREATE TABLE $_userStreaksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT UNIQUE NOT NULL,
        streakCount INTEGER DEFAULT 0,
        lastActive TEXT,
        maxStreak INTEGER DEFAULT 0,
        currentStreakStartDate TEXT,
        totalDaysActive INTEGER DEFAULT 0,
        totalPoints INTEGER DEFAULT 0,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE $_dailyChallengesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        challengeId TEXT UNIQUE NOT NULL,
        date TEXT NOT NULL,
        questionIds TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        rewardPoints INTEGER NOT NULL,
        isActive INTEGER DEFAULT 1,
        expiresAt TEXT NOT NULL,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE $_userChallengeProgressTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        challengeId TEXT NOT NULL,
        questionsCompleted INTEGER DEFAULT 0,
        totalQuestions INTEGER NOT NULL,
        isCompleted INTEGER DEFAULT 0,
        pointsEarned INTEGER DEFAULT 0,
        completedAt TEXT,
        createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
        updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(userId, challengeId)
      );
    ''');

    await db.insert(_settingsTable, {'key': 'theme', 'value': 'light'});
    await db.insert(_settingsTable, {'key': 'notifications', 'value': 'true'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final tablesResult1 = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_questionsTable'",
      );
      if (tablesResult1.isEmpty) {
        await db.execute('''
          CREATE TABLE $_questionsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            question TEXT NOT NULL,
            options TEXT NOT NULL,
            correctIndex INTEGER NOT NULL
          );
        ''');
      }
    }

    if (oldVersion < 3) {
      final tablesResult2 = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_quizResultsTable'",
      );
      if (tablesResult2.isEmpty) {
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
          );
        ''');
      }
    }

    if (oldVersion < 4) {
      // Add streak and challenge tables
      final streakTableResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_userStreaksTable'",
      );
      if (streakTableResult.isEmpty) {
        await db.execute('''
          CREATE TABLE $_userStreaksTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT UNIQUE NOT NULL,
            streakCount INTEGER DEFAULT 0,
            lastActive TEXT,
            maxStreak INTEGER DEFAULT 0,
            currentStreakStartDate TEXT,
            totalDaysActive INTEGER DEFAULT 0,
            totalPoints INTEGER DEFAULT 0,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT DEFAULT CURRENT_TIMESTAMP
          );
        ''');
      }

      final challengeTableResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_dailyChallengesTable'",
      );
      if (challengeTableResult.isEmpty) {
        await db.execute('''
          CREATE TABLE $_dailyChallengesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            challengeId TEXT UNIQUE NOT NULL,
            date TEXT NOT NULL,
            questionIds TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            rewardPoints INTEGER NOT NULL,
            isActive INTEGER DEFAULT 1,
            expiresAt TEXT NOT NULL,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP
          );
        ''');
      }

      final progressTableResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_userChallengeProgressTable'",
      );
      if (progressTableResult.isEmpty) {
        await db.execute('''
          CREATE TABLE $_userChallengeProgressTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            challengeId TEXT NOT NULL,
            questionsCompleted INTEGER DEFAULT 0,
            totalQuestions INTEGER NOT NULL,
            isCompleted INTEGER DEFAULT 0,
            pointsEarned INTEGER DEFAULT 0,
            completedAt TEXT,
            createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
            updatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(userId, challengeId)
          );
        ''');
      }
    }
  }

  Future<void> initializeDatabase() async {
    await database;
  }

  // Quiz Results
  Future<int> saveQuizResult(QuizResult result) async {
    final db = await database;
    return await db.insert(_quizResultsTable, result.toMap());
  }

  Future<List<QuizResult>> getUserQuizResults(String userId) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _quizResultsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  Future<List<QuizResult>> getUserQuizResultsByCategory(
    String userId,
    String categoryName,
  ) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _quizResultsTable,
      where: 'userId = ? AND categoryName = ?',
      whereArgs: [userId, categoryName],
      orderBy: 'completedAt DESC',
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  Future<Map<String, Object?>> getUserStats(String userId) async {
    final db = await database;

    final totalQuizzesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final totalQuizzes = (totalQuizzesResult.first['count'] as int?) ?? 0;

    final totalScoreResult = await db.rawQuery(
      'SELECT SUM(totalScore) as total FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final totalScore = (totalScoreResult.first['total'] as int?) ?? 0;

    final avgPercentageResult = await db.rawQuery(
      'SELECT AVG(percentage) as avg FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final avgPercentage = (avgPercentageResult.first['avg'] as double?) ?? 0.0;

    final bestScoreResult = await db.rawQuery(
      'SELECT MAX(totalScore) as best FROM $_quizResultsTable WHERE userId = ?',
      [userId],
    );
    final bestScore = (bestScoreResult.first['best'] as int?) ?? 0;

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
      'quizzesCompleted': totalQuizzes,
      'totalCoins': totalScore ~/ 2,
    };
  }

  Future<List<QuizResult>> getRecentQuizResults(
    String userId, {
    int limit = 10,
  }) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _quizResultsTable,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
      limit: limit,
    );
    return maps.map((map) => QuizResult.fromMap(map)).toList();
  }

  Future<int> deleteQuizResult(int id) async {
    final db = await database;
    return await db.delete(_quizResultsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearUserQuizResults(String userId) async {
    final db = await database;
    return await db.delete(
      _quizResultsTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Questions
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert(_questionsTable, question.toMap());
  }

  Future<List<Question>> getQuestionsByCategory(
    String category, {
    int limit = 10,
  }) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _questionsTable,
      where: 'category = ?',
      whereArgs: [category],
      limit: limit,
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<List<Question>> getRandomQuestionsByCategory(
    String category, {
    int limit = 10,
  }) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.rawQuery(
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

  Future<List<Question>> getAllQuestions() async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(_questionsTable);
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  // Users (optional helpers)
  Future<int> insertUser(Map<String, Object?> user) async {
    final db = await database;
    return await db.insert(
      _usersTable,
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> getUserByUid(String uid) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _usersTable,
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<List<Map<String, Object?>>> getAllUsers() async {
    final db = await database;
    return await db.query(_usersTable);
  }

  Future<int> updateUser(String uid, Map<String, Object?> user) async {
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

  // Settings
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
    final List<Map<String, Object?>> maps = await db.query(
      _settingsTable,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return maps.isNotEmpty ? (maps.first['value'] as String?) : null;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(_settingsTable);
    return {
      for (var map in maps)
        (map['key'] as String): (map['value'] as String? ?? ''),
    };
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

  // User Streaks
  Future<UserStreak?> getUserStreak(String userId) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _userStreaksTable,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.isNotEmpty ? UserStreak.fromMap(maps.first) : null;
  }

  Future<int> insertOrUpdateUserStreak(UserStreak streak) async {
    final db = await database;
    return await db.insert(
      _userStreaksTable,
      streak.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserStreak> updateStreakOnActivity(String userId) async {
    final db = await database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    UserStreak? existingStreak = await getUserStreak(userId);
    
    if (existingStreak == null) {
      // First time user - create new streak
      final newStreak = UserStreak(
        userId: userId,
        streakCount: 1,
        lastActive: today,
        maxStreak: 1,
        currentStreakStartDate: today,
        totalDaysActive: 1,
        totalPoints: 25,
        createdAt: now,
        updatedAt: now,
      );
      await insertOrUpdateUserStreak(newStreak);
      return newStreak;
    }

    final lastActiveDate = existingStreak.lastActive != null 
        ? DateTime(existingStreak.lastActive!.year, existingStreak.lastActive!.month, existingStreak.lastActive!.day)
        : null;
    
    if (lastActiveDate != null && lastActiveDate.isAtSameMomentAs(today)) {
      // Same day activity - no streak change
      return existingStreak;
    }

    int newStreakCount;
    DateTime? newStreakStartDate;
    int newTotalDaysActive = existingStreak.totalDaysActive + 1;
    int bonusPoints = 25; // Base daily points

    if (lastActiveDate != null && today.difference(lastActiveDate).inDays == 1) {
      // Consecutive day - increment streak
      newStreakCount = existingStreak.streakCount + 1;
      newStreakStartDate = existingStreak.currentStreakStartDate;
      
      // Streak multiplier bonus
      if (newStreakCount >= 7) {
        bonusPoints += (newStreakCount ~/ 7) * 25;
      }
    } else {
      // Missed days or first activity - reset streak
      newStreakCount = 1;
      newStreakStartDate = today;
    }

    final newMaxStreak = newStreakCount > existingStreak.maxStreak 
        ? newStreakCount 
        : existingStreak.maxStreak;

    final updatedStreak = existingStreak.copyWith(
      streakCount: newStreakCount,
      lastActive: today,
      maxStreak: newMaxStreak,
      currentStreakStartDate: newStreakStartDate,
      totalDaysActive: newTotalDaysActive,
      totalPoints: existingStreak.totalPoints + bonusPoints,
      updatedAt: now,
    );

    await insertOrUpdateUserStreak(updatedStreak);
    return updatedStreak;
  }

  // Daily Challenges
  Future<DailyChallenge?> getDailyChallengeByDate(DateTime date) async {
    final db = await database;
    final dateString = date.toIso8601String().split('T')[0];
    final List<Map<String, Object?>> maps = await db.query(
      _dailyChallengesTable,
      where: 'date = ? AND isActive = 1',
      whereArgs: [dateString],
    );
    return maps.isNotEmpty ? DailyChallenge.fromMap(maps.first) : null;
  }

  Future<DailyChallenge?> getTodaysDailyChallenge() async {
    return await getDailyChallengeByDate(DateTime.now());
  }

  Future<int> insertDailyChallenge(DailyChallenge challenge) async {
    final db = await database;
    return await db.insert(_dailyChallengesTable, challenge.toMap());
  }

  Future<DailyChallenge> generateDailyChallenge() async {
    final today = DateTime.now();
    final existing = await getDailyChallengeByDate(today);
    if (existing != null) return existing;

    // Get random questions from different categories
    final allQuestions = await getAllQuestions();
    if (allQuestions.isEmpty) {
      throw Exception('No questions available for daily challenge');
    }

    allQuestions.shuffle();
    final selectedQuestions = allQuestions.take(5).toList();
    
    // Determine difficulty based on day of week
    final dayOfWeek = today.weekday;
    String difficulty;
    int rewardPoints;
    
    if (dayOfWeek >= 1 && dayOfWeek <= 3) {
      difficulty = 'easy';
      rewardPoints = 100;
    } else if (dayOfWeek >= 4 && dayOfWeek <= 5) {
      difficulty = 'medium';
      rewardPoints = 150;
    } else {
      difficulty = 'hard';
      rewardPoints = 200;
    }

    final challenge = DailyChallenge(
      challengeId: 'daily_${today.toIso8601String().split('T')[0]}',
      date: today,
      questionIds: selectedQuestions.map((q) => q.id!).toList(),
      difficulty: difficulty,
      rewardPoints: rewardPoints,
      isActive: true,
      expiresAt: DateTime(today.year, today.month, today.day, 23, 59, 59),
      createdAt: today,
    );

    await insertDailyChallenge(challenge);
    return challenge;
  }

  // User Challenge Progress
  Future<UserChallengeProgress?> getUserChallengeProgress(String userId, String challengeId) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _userChallengeProgressTable,
      where: 'userId = ? AND challengeId = ?',
      whereArgs: [userId, challengeId],
    );
    return maps.isNotEmpty ? UserChallengeProgress.fromMap(maps.first) : null;
  }

  Future<int> insertOrUpdateChallengeProgress(UserChallengeProgress progress) async {
    final db = await database;
    return await db.insert(
      _userChallengeProgressTable,
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserChallengeProgress> startDailyChallenge(String userId, String challengeId, int totalQuestions) async {
    final existing = await getUserChallengeProgress(userId, challengeId);
    if (existing != null) return existing;

    final now = DateTime.now();
    final progress = UserChallengeProgress(
      userId: userId,
      challengeId: challengeId,
      questionsCompleted: 0,
      totalQuestions: totalQuestions,
      isCompleted: false,
      pointsEarned: 0,
      createdAt: now,
      updatedAt: now,
    );

    await insertOrUpdateChallengeProgress(progress);
    return progress;
  }

  Future<UserChallengeProgress> updateChallengeProgress(
    String userId, 
    String challengeId, 
    int questionsCompleted,
    {int? pointsEarned}
  ) async {
    final existing = await getUserChallengeProgress(userId, challengeId);
    if (existing == null) {
      throw Exception('Challenge progress not found');
    }

    final now = DateTime.now();
    final isCompleted = questionsCompleted >= existing.totalQuestions;
    
    final updatedProgress = UserChallengeProgress(
      id: existing.id,
      userId: userId,
      challengeId: challengeId,
      questionsCompleted: questionsCompleted,
      totalQuestions: existing.totalQuestions,
      isCompleted: isCompleted,
      pointsEarned: pointsEarned ?? existing.pointsEarned,
      completedAt: isCompleted ? now : existing.completedAt,
      createdAt: existing.createdAt,
      updatedAt: now,
    );

    await insertOrUpdateChallengeProgress(updatedProgress);
    return updatedProgress;
  }

  Future<List<UserChallengeProgress>> getUserCompletedChallenges(String userId) async {
    final db = await database;
    final List<Map<String, Object?>> maps = await db.query(
      _userChallengeProgressTable,
      where: 'userId = ? AND isCompleted = 1',
      whereArgs: [userId],
      orderBy: 'completedAt DESC',
    );
    return maps.map((map) => UserChallengeProgress.fromMap(map)).toList();
  }

  // Utilities
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_usersTable);
    await db.delete(_settingsTable);
    await db.delete(_questionsTable);
    await db.delete(_quizResultsTable);
    await db.delete(_userStreaksTable);
    await db.delete(_dailyChallengesTable);
    await db.delete(_userChallengeProgressTable);
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
