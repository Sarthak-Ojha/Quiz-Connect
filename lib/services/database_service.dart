import 'dart:io';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/question.dart';
import '../models/quiz_result.dart';
import '../models/user_streak.dart';
import '../models/daily_challenge.dart';
import '../models/user_challenge_progress.dart';

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

  /// Save a set of AI-generated questions into Firestore under the user's saved_questions subcollection.
  /// Each doc contains all questions for a topic to keep categories separated.
  Future<void> saveAIQuestionSet(String topic, List<Question> questions) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userSavedRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('saved_questions')
        .doc(); // auto-id per generated set

    final payload = {
      'topic': topic,
      'category': 'AI - $topic',
      'source': 'ai',
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions
          .map((q) => {
                'question': q.question,
                'options': q.options,
                'correctIndex': q.correctIndex,
              })
          .toList(),
    };

    await userSavedRef.set(payload);
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

  // Sync Firebase user with local database
  Future<void> syncFirebaseUser(String uid, String email, String? displayName, String? photoURL, bool emailVerified) async {
    // Check if user already exists
    final existingUser = await getUserByUid(uid);
    
    final userData = {
      'uid': uid,
      'email': email,
      'displayName': displayName ?? 'Quiz Master',
      'photoURL': photoURL,
      'emailVerified': emailVerified ? 1 : 0,
      'lastSignIn': DateTime.now().toIso8601String(),
    };
    
    if (existingUser == null) {
      // Insert new user
      userData['createdAt'] = DateTime.now().toIso8601String();
      await insertUser(userData);
      debugPrint('✅ New user synced to database: $uid');
    } else {
      // Update existing user
      await updateUser(uid, userData);
      debugPrint('🔄 Existing user updated in database: $uid');
    }
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

  Future<int> deleteDailyChallenge(String challengeId) async {
    final db = await database;
    return await db.delete(
      _dailyChallengesTable,
      where: 'challengeId = ?',
      whereArgs: [challengeId],
    );
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

  // Leaderboard Methods
  Future<List<Map<String, dynamic>>> getLeaderboardData({
    String orderBy = 'totalScore',
    int limit = 50,
  }) async {
    final db = await database;
    
    // Get aggregated user stats with user info
    final List<Map<String, Object?>> maps = await db.rawQuery(
      '''
      SELECT 
        u.uid as userId,
        u.displayName,
        u.photoUrl,
        COALESCE(SUM(qr.totalScore), 0) as totalScore,
        COUNT(qr.id) as totalQuizzes,
        COALESCE(AVG(qr.totalScore), 0.0) as averageScore,
        COALESCE(us.streakCount, 0) as currentStreak,
        COALESCE(us.maxStreak, 0) as maxStreak,
        COALESCE(MAX(qr.completedAt), u.createdAt) as lastActivity
      FROM $_usersTable u
      LEFT JOIN $_quizResultsTable qr ON u.uid = qr.userId
      LEFT JOIN $_userStreaksTable us ON u.uid = us.userId
      WHERE u.uid IS NOT NULL
      GROUP BY u.uid, u.displayName, u.photoUrl, us.streakCount, us.maxStreak
      HAVING totalQuizzes > 0
      ORDER BY $orderBy DESC
      LIMIT ?
      ''',
      [limit],
    );
    
    // Add rank to each entry
    final List<Map<String, dynamic>> rankedResults = [];
    for (int i = 0; i < maps.length; i++) {
      final map = Map<String, dynamic>.from(maps[i]);
      map['rank'] = i + 1;
      rankedResults.add(map);
    }
    
    return rankedResults;
  }

  Future<Map<String, dynamic>?> getUserLeaderboardPosition(
    String userId, {
    String orderBy = 'totalScore',
  }) async {
    final db = await database;
    
    // Get user's stats
    final userStats = await db.rawQuery(
      '''
      SELECT 
        u.uid as userId,
        u.displayName,
        u.photoUrl,
        COALESCE(SUM(qr.totalScore), 0) as totalScore,
        COUNT(qr.id) as totalQuizzes,
        COALESCE(AVG(qr.totalScore), 0.0) as averageScore,
        COALESCE(us.streakCount, 0) as currentStreak,
        COALESCE(us.maxStreak, 0) as maxStreak,
        COALESCE(MAX(qr.completedAt), u.createdAt) as lastActivity
      FROM $_usersTable u
      LEFT JOIN $_quizResultsTable qr ON u.uid = qr.userId
      LEFT JOIN $_userStreaksTable us ON u.uid = us.userId
      WHERE u.uid = ?
      GROUP BY u.uid, u.displayName, u.photoUrl, us.streakCount, us.maxStreak
      ''',
      [userId],
    );
    
    if (userStats.isEmpty) return null;
    
    final userScore = userStats.first[orderBy] ?? 0;
    
    // Get user's rank
    final rankResult = await db.rawQuery(
      '''
      SELECT COUNT(*) + 1 as rank
      FROM (
        SELECT 
          u.uid,
          COALESCE(SUM(qr.totalScore), 0) as totalScore,
          COUNT(qr.id) as totalQuizzes,
          COALESCE(AVG(qr.totalScore), 0.0) as averageScore,
          COALESCE(us.streakCount, 0) as currentStreak,
          COALESCE(us.maxStreak, 0) as maxStreak
        FROM $_usersTable u
        LEFT JOIN $_quizResultsTable qr ON u.uid = qr.userId
        LEFT JOIN $_userStreaksTable us ON u.uid = us.userId
        WHERE u.uid != ?
        GROUP BY u.uid, us.streakCount, us.maxStreak
        HAVING totalQuizzes > 0 AND $orderBy > ?
      )
      ''',
      [userId, userScore],
    );
    
    final result = Map<String, dynamic>.from(userStats.first);
    result['rank'] = rankResult.first['rank'];
    return result;
  }

  Future<List<Map<String, dynamic>>> getTopPerformers({
    int limit = 10,
    int minQuizzes = 5,
  }) async {
    final db = await database;
    
    return await db.rawQuery(
      '''
      SELECT 
        u.uid as userId,
        u.displayName,
        u.photoUrl,
        COALESCE(SUM(qr.totalScore), 0) as totalScore,
        COUNT(qr.id) as totalQuizzes,
        COALESCE(AVG(qr.percentage), 0.0) as averagePercentage,
        COALESCE(us.streakCount, 0) as currentStreak,
        COALESCE(us.maxStreak, 0) as maxStreak
      FROM $_usersTable u
      LEFT JOIN $_quizResultsTable qr ON u.uid = qr.userId
      LEFT JOIN $_userStreaksTable us ON u.uid = us.userId
      WHERE u.uid IS NOT NULL
      GROUP BY u.uid, u.displayName, u.photoUrl, us.streakCount, us.maxStreak
      HAVING totalQuizzes >= ?
      ORDER BY averagePercentage DESC, totalScore DESC
      LIMIT ?
      ''',
      [minQuizzes, limit],
    );
  }

  // Debug: Export database to Downloads folder for DB Browser inspection
  Future<String?> exportDatabaseForInspection() async {
    try {
      final dbPath = join(await getDatabasesPath(), _databaseName);
      
      // For Android - copy to Downloads folder
      if (defaultTargetPlatform == TargetPlatform.android) {
        const externalDir = '/storage/emulated/0/Download';
        const exportPath = '$externalDir/quiz_app_database_export.db';
        
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          await dbFile.copy(exportPath);
          debugPrint('✅ Database exported to: $exportPath');
          debugPrint('📱 You can now access it from Downloads folder');
          return exportPath;
        }
      }
      
      debugPrint('📍 Database location: $dbPath');
      return dbPath;
    } catch (e) {
      debugPrint('❌ Error exporting database: $e');
      return null;
    }
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

  // Friend Requests Management
  
  /// Get stream of pending friend requests for current user
  Stream<QuerySnapshot> getFriendRequests() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Accept a friend request
  Future<bool> acceptFriendRequest(String requestId, String friendId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      final batch = FirebaseFirestore.instance.batch();

      // Update request status
      final requestRef = FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId);
      
      batch.update(requestRef, {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add each other as friends
      final userFriendsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendId);
      
      final friendFriendsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(currentUser.uid);

      batch.set(userFriendsRef, {
        'since': FieldValue.serverTimestamp(),
      });

      batch.set(friendFriendsRef, {
        'since': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      return false;
    }
  }

  /// Reject a friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc(requestId)
          .update({
            'status': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      return false;
    }
  }

  /// Send a friend request
  Future<bool> sendFriendRequest(String toUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ Send friend request failed: No current user');
        return false;
      }

      // Prevent sending a request to yourself
      if (toUserId == currentUser.uid) {
        debugPrint('❌ Send friend request failed: Cannot send request to yourself');
        return false;
      }

      debugPrint('📤 Attempting to send friend request from ${currentUser.uid} to $toUserId');

      // Check if already friends
      final friendDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(toUserId)
          .get();

      if (friendDoc.exists) {
        debugPrint('❌ Send friend request failed: Already friends');
        return false; // Already friends
      }

      // If the other user already sent a pending request, auto-accept it instead of creating a duplicate
      final reverseRequestRef = FirebaseFirestore.instance
          .collection('friend_requests')
          .doc('${toUserId}_${currentUser.uid}');
      final reverseRequestDoc = await reverseRequestRef.get();
      if (reverseRequestDoc.exists) {
        final reverseStatus = reverseRequestDoc.data()?['status'];
        if (reverseStatus == 'pending') {
          debugPrint('🤝 Reverse pending request found. Auto-accepting instead of sending a new one.');
          return await acceptFriendRequest(reverseRequestRef.id, toUserId);
        } else if (reverseStatus == 'accepted') {
          debugPrint('❌ Send friend request failed: Already accepted via reverse request');
          return false;
        }
      }

      // Check if request already exists
      final requestDoc = await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc('${currentUser.uid}_$toUserId')
          .get();

      if (requestDoc.exists) {
        final status = requestDoc.data()?['status'];
        if (status == 'pending') {
          debugPrint('❌ Send friend request failed: Pending request already exists');
          return false; // Request already sent and pending
        }
        // If status is 'rejected' or 'accepted', we can overwrite it
        debugPrint('📝 Overwriting previous request with status: $status');
      }

      // Create or update friend request
      await FirebaseFirestore.instance
          .collection('friend_requests')
          .doc('${currentUser.uid}_$toUserId')
          .set({
        'from': currentUser.uid,
        'to': toUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Friend request sent successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending friend request: $e');
      return false;
    }
  }

  /// Get user's friends
  Stream<QuerySnapshot> getUserFriends(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('friends')
        .orderBy('since', descending: true)
        .snapshots();
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId1, String userId2) async {
    final friendDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId1)
        .collection('friends')
        .doc(userId2)
        .get();
    
    return friendDoc.exists;
  }

  /// Update user online status with automatic offline on disconnect
  Future<void> setUserOnline(String userId) async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userSnapshot = await userRef.get();

      final data = <String, dynamic>{
        'displayName': authUser.displayName,
        'email': authUser.email,
        'photoURL': authUser.photoURL,
        'emailVerified': authUser.emailVerified,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only set createdAt the first time the document is written
      if (!userSnapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await userRef.set(data, SetOptions(merge: true));
      
      // Set up automatic offline status when user disconnects
      // This uses Firestore's onDisconnect feature via a Cloud Function trigger
      // For now, we'll rely on the app lifecycle to set offline
      debugPrint('✅ User status set to online');
    } catch (e) {
      debugPrint('❌ Error setting user online: $e');
    }
  }

  /// Update user offline status
  Future<void> setUserOffline(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ User status set to offline');
    } catch (e) {
      debugPrint('❌ Error setting user offline: $e');
    }
  }

  /// Get questions by their IDs (for multiplayer games)
  Future<List<Question>> getQuestionsByIds(List<String> questionIds) async {
    try {
      final db = await database;
      final List<Question> questions = [];
      
      for (final id in questionIds) {
        final result = await db.query(
          _questionsTable,
          where: 'id = ?',
          whereArgs: [int.parse(id)],
        );
        
        if (result.isNotEmpty) {
          questions.add(Question.fromMap(result.first));
        }
      }
      
      return questions;
    } catch (e) {
      debugPrint('❌ Error getting questions by IDs: $e');
      return [];
    }
  }

  /// Get all available categories from database
  Future<List<String>> getAvailableCategories() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT DISTINCT category FROM $_questionsTable ORDER BY category'
      );
      
      final categories = result
          .map((row) => row['category'] as String)
          .where((cat) => cat.isNotEmpty)
          .toList();
      
      debugPrint('📚 Available categories: $categories');
      return categories;
    } catch (e) {
      debugPrint('❌ Error getting categories: $e');
      return [];
    }
  }

  /// Load questions from JSON file into database
  Future<void> loadQuestionsFromJson() async {
    try {
      final db = await database;
      
      // Check if questions already loaded
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_questionsTable')
      );
      
      if (count != null && count > 0) {
        debugPrint('✅ Questions already loaded ($count questions)');
        return;
      }
      
      debugPrint('📥 Loading questions from JSON...');
      
      // Load JSON file
      final String jsonString = await rootBundle.loadString('assets/questions.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Insert questions into database
      final batch = db.batch();
      for (var questionData in jsonData) {
        batch.insert(_questionsTable, {
          'category': questionData['category'],
          'question': questionData['question'],
          'options': json.encode(questionData['options']),
          'correctIndex': questionData['correctIndex'],
        });
      }
      
      await batch.commit(noResult: true);
      debugPrint('✅ Loaded ${jsonData.length} questions from JSON');
    } catch (e) {
      debugPrint('❌ Error loading questions from JSON: $e');
    }
  }

  /// Create a multiplayer game
  Future<String?> createMultiplayerGame({
    required String hostId,
    required String category,
    required int questionCount,
  }) async {
    try {
      debugPrint('🎮 Creating multiplayer game with random questions from ALL categories');
      
      // Get random questions from ALL categories (ignore category parameter)
      final db = await database;
      
      // First check total questions available
      final totalQuestions = await db.query(_questionsTable);
      
      debugPrint('📊 Total questions available: ${totalQuestions.length}');
      
      if (totalQuestions.isEmpty) {
        debugPrint('❌ No questions found in database');
        return null;
      }
      
      // Get random questions from ALL categories
      final questions = await db.query(
        _questionsTable,
        orderBy: 'RANDOM()',
        limit: questionCount,
      );

      debugPrint('✅ Selected ${questions.length} random questions from all categories');
      
      final questionIds = questions.map((q) => q['id'].toString()).toList();
      debugPrint('📝 Question IDs: $questionIds');

      // Create game in Firestore
      debugPrint('🔥 Creating game in Firestore...');
      final gameRef = await FirebaseFirestore.instance
          .collection('multiplayer_games')
          .add({
        'hostId': hostId,
        'guestId': null,
        'category': category,
        'questionCount': questionCount,
        'status': 'waiting',
        'scores': {
          hostId: {
            'correctAnswers': 0,
            'totalAnswered': 0,
            'answers': [],
          },
        },
        'questionIds': questionIds,
        'currentQuestionIndex': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': null,
        'completedAt': null,
      });

      debugPrint('✅ Multiplayer game created successfully: ${gameRef.id}');
      return gameRef.id;
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating multiplayer game: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Join a multiplayer game
  Future<bool> joinMultiplayerGame(String gameId, String userId) async {
    try {
      final gameDoc = await FirebaseFirestore.instance
          .collection('multiplayer_games')
          .doc(gameId)
          .get();

      if (!gameDoc.exists) {
        debugPrint('❌ Game not found: $gameId');
        return false;
      }

      final gameData = gameDoc.data()!;
      if (gameData['guestId'] != null) {
        debugPrint('❌ Game already has a guest');
        return false;
      }

      await FirebaseFirestore.instance
          .collection('multiplayer_games')
          .doc(gameId)
          .update({
        'guestId': userId,
        'status': 'ready',
        'scores.$userId': {
          'correctAnswers': 0,
          'totalAnswered': 0,
          'answers': [],
        },
      });

      debugPrint('✅ Joined multiplayer game: $gameId');
      return true;
    } catch (e) {
      debugPrint('❌ Error joining multiplayer game: $e');
      return false;
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}
