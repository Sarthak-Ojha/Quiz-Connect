import '../models/user_streak.dart';
import '../models/daily_challenge.dart';
import '../models/question.dart';
import '../models/user_challenge_progress.dart';
import '../services/database_service.dart';
import 'notification_service.dart';

class StreakService {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  // Streak Management
  Future<UserStreak> updateUserStreak(String userId) async {
    final updatedStreak = await _dbService.updateStreakOnActivity(userId);
    
    // Streak notifications disabled - no notifications for streak achievements
    
    return updatedStreak;
  }

  Future<UserStreak?> getUserStreak(String userId) async {
    return await _dbService.getUserStreak(userId);
  }

  Future<int> calculateStreakReward(int streakCount) async {
    const streakMilestones = [7, 14, 30, 60, 100];
    const rewards = [50, 150, 400, 1000, 2500];
    
    if (streakMilestones.contains(streakCount)) {
      final rewardIndex = streakMilestones.indexOf(streakCount);
      return rewards[rewardIndex];
    }
    return 0;
  }

  Future<bool> isStreakMilestone(int streakCount) async {
    const streakMilestones = [7, 14, 30, 60, 100];
    return streakMilestones.contains(streakCount);
  }

  // Daily Challenge Management
  Future<DailyChallenge> getTodaysChallenge() async {
    final existing = await _dbService.getTodaysDailyChallenge();
    if (existing != null) return existing;
    
    return await _dbService.generateDailyChallenge();
  }

  Future<List<Question>> getChallengeQuestions(DailyChallenge challenge) async {
    final allQuestions = await _dbService.getAllQuestions();
    final challengeQuestions = <Question>[];
    
    for (final questionId in challenge.questionIds) {
      final question = allQuestions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => throw Exception('Question not found: $questionId'),
      );
      challengeQuestions.add(question);
    }
    
    return challengeQuestions;
  }

  Future<UserChallengeProgress> startChallenge(String userId, DailyChallenge challenge) async {
    return await _dbService.startDailyChallenge(
      userId, 
      challenge.challengeId, 
      challenge.questionIds.length,
    );
  }

  Future<UserChallengeProgress> updateChallengeProgress(
    String userId,
    String challengeId,
    int questionsCompleted,
    int correctAnswers,
  ) async {
    // Calculate points based on performance
    final challenge = await _dbService.getDailyChallengeByDate(DateTime.now());
    if (challenge == null) throw Exception('Challenge not found');
    
    int pointsEarned = 0;
    if (questionsCompleted >= challenge.questionIds.length) {
      // Challenge completed
      final percentage = (correctAnswers / challenge.questionIds.length) * 100;
      pointsEarned = challenge.rewardPoints;
      
      // Bonus for perfect score
      if (percentage == 100) {
        pointsEarned = (pointsEarned * 1.5).round();
      } else if (percentage >= 80) {
        pointsEarned = (pointsEarned * 1.2).round();
      }
      
      // Show challenge completion notification
      await _notificationService.showChallengeCompletion(
        pointsEarned: pointsEarned,
        difficulty: challenge.difficulty,
      );
    }

    return await _dbService.updateChallengeProgress(
      userId,
      challengeId,
      questionsCompleted,
      pointsEarned: pointsEarned,
    );
  }

  Future<UserChallengeProgress?> getUserChallengeProgress(String userId, String challengeId) async {
    return await _dbService.getUserChallengeProgress(userId, challengeId);
  }

  Future<List<UserChallengeProgress>> getUserCompletedChallenges(String userId) async {
    return await _dbService.getUserCompletedChallenges(userId);
  }

  // Gamification Features
  Future<Map<String, dynamic>> getUserEngagementStats(String userId) async {
    final streak = await getUserStreak(userId);
    final completedChallenges = await getUserCompletedChallenges(userId);
    final quizStats = await _dbService.getUserStats(userId);
    
    final totalChallengesCompleted = completedChallenges.length;
    final totalChallengePoints = completedChallenges.fold<int>(
      0, 
      (sum, challenge) => sum + challenge.pointsEarned,
    );
    
    final currentWeek = DateTime.now().subtract(const Duration(days: 7));
    final weeklyCompletedChallenges = completedChallenges.where(
      (challenge) => challenge.completedAt != null && 
                    challenge.completedAt!.isAfter(currentWeek),
    ).length;

    return {
      'currentStreak': streak?.streakCount ?? 0,
      'maxStreak': streak?.maxStreak ?? 0,
      'totalDaysActive': streak?.totalDaysActive ?? 0,
      'streakPoints': streak?.totalPoints ?? 0,
      'totalChallengesCompleted': totalChallengesCompleted,
      'totalChallengePoints': totalChallengePoints,
      'weeklyCompletedChallenges': weeklyCompletedChallenges,
      'totalQuizzes': quizStats['totalQuizzes'] ?? 0,
      'totalQuizPoints': (quizStats['totalScore'] as int?) ?? 0,
      'averagePercentage': (quizStats['averagePercentage'] as double?) ?? 0.0,
      'totalPoints': (streak?.totalPoints ?? 0) + 
                     totalChallengePoints + 
                     ((quizStats['totalScore'] as int?) ?? 0),
      'rank': _calculateUserRank(
        (streak?.totalPoints ?? 0) + totalChallengePoints + ((quizStats['totalScore'] as int?) ?? 0),
      ),
    };
  }

  Future<Map<int, bool>> getStreakCalendarData(String userId, DateTime month) async {
    final db = await _dbService.database;
    
    // Get all quiz results and challenge completions for the month
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    final quizResults = await db.query(
      'quiz_results',
      where: 'userId = ? AND completedAt >= ? AND completedAt <= ?',
      whereArgs: [
        userId,
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ],
    );
    
    final challengeResults = await db.query(
      'user_challenge_progress',
      where: 'userId = ? AND completedAt >= ? AND completedAt <= ? AND isCompleted = 1',
      whereArgs: [
        userId,
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ],
    );
    
    Map<int, bool> streakDays = {};
    
    // Mark days with quiz activity
    for (final result in quizResults) {
      final completedAt = DateTime.parse(result['completedAt'] as String);
      streakDays[completedAt.day] = true;
    }
    
    // Mark days with challenge activity
    for (final result in challengeResults) {
      final completedAt = DateTime.parse(result['completedAt'] as String);
      streakDays[completedAt.day] = true;
    }
    
    return streakDays;
  }

  int _calculateUserRank(int totalPoints) {
    if (totalPoints >= 10000) return 1; // Diamond
    if (totalPoints >= 5000) return 2;  // Platinum
    if (totalPoints >= 2500) return 3;  // Gold
    if (totalPoints >= 1000) return 4;  // Silver
    if (totalPoints >= 500) return 5;   // Bronze
    return 6; // Beginner
  }

  String getRankName(int rank) {
    switch (rank) {
      case 1: return 'Diamond';
      case 2: return 'Platinum';
      case 3: return 'Gold';
      case 4: return 'Silver';
      case 5: return 'Bronze';
      default: return 'Beginner';
    }
  }

  String getRankEmoji(int rank) {
    switch (rank) {
      case 1: return '💎';
      case 2: return '🏆';
      case 3: return '🥇';
      case 4: return '🥈';
      case 5: return '🥉';
      default: return '🌱';
    }
  }

  // Notification and Reminder Logic
  Future<bool> shouldShowStreakReminder(String userId) async {
    final streak = await getUserStreak(userId);
    if (streak == null) return true; // First time user
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = streak.lastActive;
    
    if (lastActive == null) return true;
    
    final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    final daysSinceActive = today.difference(lastActiveDay).inDays;
    
    return daysSinceActive >= 1; // Show reminder if not active today
  }

  Future<String> getMotivationalMessage(String userId) async {
    final streak = await getUserStreak(userId);
    final streakCount = streak?.streakCount ?? 0;
    
    if (streakCount == 0) {
      return "Ready to start your learning journey? 🚀";
    } else if (streakCount == 1) {
      return "Great start! Keep the momentum going! 💪";
    } else if (streakCount < 7) {
      return "You're building an amazing habit! 🔥";
    } else if (streakCount < 14) {
      return "Incredible dedication! You're on fire! 🔥🔥";
    } else if (streakCount < 30) {
      return "Wow! You're a true quiz champion! 🏆";
    } else {
      return "Legendary streak! You're an inspiration! 🌟";
    }
  }

  // Analytics and Performance Tracking
  Future<Map<String, dynamic>> getEngagementAnalytics(String userId) async {
    final streak = await getUserStreak(userId);
    final completedChallenges = await getUserCompletedChallenges(userId);
    
    // Calculate retention metrics
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final last30Days = now.subtract(const Duration(days: 30));
    
    final recentChallenges = completedChallenges.where(
      (c) => c.completedAt != null && c.completedAt!.isAfter(last7Days),
    ).length;
    
    final monthlyChallenges = completedChallenges.where(
      (c) => c.completedAt != null && c.completedAt!.isAfter(last30Days),
    ).length;
    
    return {
      'streakRetention': streak?.streakCount ?? 0,
      'weeklyEngagement': recentChallenges,
      'monthlyEngagement': monthlyChallenges,
      'totalEngagement': completedChallenges.length,
      'averageSessionsPerWeek': recentChallenges / 1.0, // Simplified calculation
      'lastActiveDate': streak?.lastActive?.toIso8601String(),
      'engagementTrend': _calculateEngagementTrend(completedChallenges),
    };
  }

  String _calculateEngagementTrend(List<UserChallengeProgress> challenges) {
    if (challenges.length < 2) return 'stable';
    
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    final previousWeek = now.subtract(const Duration(days: 14));
    
    final lastWeekCount = challenges.where(
      (c) => c.completedAt != null && 
             c.completedAt!.isAfter(lastWeek),
    ).length;
    
    final previousWeekCount = challenges.where(
      (c) => c.completedAt != null && 
             c.completedAt!.isAfter(previousWeek) && 
             c.completedAt!.isBefore(lastWeek),
    ).length;
    
    if (lastWeekCount > previousWeekCount) return 'increasing';
    if (lastWeekCount < previousWeekCount) return 'decreasing';
    return 'stable';
  }
}
