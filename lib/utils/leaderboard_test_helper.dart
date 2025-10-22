import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/quiz_result.dart';

/// Helper class for testing leaderboard functionality
/// This helps developers verify that the leaderboard is working correctly
class LeaderboardTestHelper {
  static final DatabaseService _db = DatabaseService();

  /// Add some sample quiz results for testing leaderboard
  static Future<void> addSampleQuizResults() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No user logged in. Please sign in first.');
      return;
    }

    try {
      // Ensure user is synced to database first
      await _db.syncFirebaseUser(
        user.uid,
        user.email ?? '',
        user.displayName,
        user.photoURL,
        user.emailVerified,
      );

      // Add some sample quiz results
      final sampleResults = [
        QuizResult(
          userId: user.uid,
          categoryName: 'Science',
          categoryColor: '#2196F3',
          totalQuestions: 10,
          correctAnswers: 8,
          wrongAnswers: 2,
          totalScore: 80,
          percentage: 80.0,
          isTimerMode: false,
          timerSeconds: 0,
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          userAnswers: List.generate(10, (i) => i < 8 ? '1' : '0'),
          questions: List.generate(10, (i) => 'Sample question ${i + 1}'),
        ),
        QuizResult(
          userId: user.uid,
          categoryName: 'History',
          categoryColor: '#FF9800',
          totalQuestions: 15,
          correctAnswers: 12,
          wrongAnswers: 3,
          totalScore: 120,
          percentage: 80.0,
          isTimerMode: true,
          timerSeconds: 15,
          completedAt: DateTime.now().subtract(const Duration(hours: 2)),
          userAnswers: List.generate(15, (i) => i < 12 ? '1' : '0'),
          questions: List.generate(15, (i) => 'Sample question ${i + 1}'),
        ),
        QuizResult(
          userId: user.uid,
          categoryName: 'Geography',
          categoryColor: '#009688',
          totalQuestions: 20,
          correctAnswers: 18,
          wrongAnswers: 2,
          totalScore: 180,
          percentage: 90.0,
          isTimerMode: false,
          timerSeconds: 0,
          completedAt: DateTime.now(),
          userAnswers: List.generate(20, (i) => i < 18 ? '1' : '0'),
          questions: List.generate(20, (i) => 'Sample question ${i + 1}'),
        ),
      ];

      for (final result in sampleResults) {
        await _db.saveQuizResult(result);
      }

      print('✅ Sample quiz results added successfully!');
      print('📊 Total Score: ${sampleResults.fold(0, (sum, r) => sum + r.totalScore)}');
      print('📚 Total Quizzes: ${sampleResults.length}');
      print('🎯 Average: ${sampleResults.fold(0.0, (sum, r) => sum + r.percentage) / sampleResults.length}%');
      
    } catch (e) {
      print('❌ Error adding sample data: $e');
    }
  }

  /// Check current user's leaderboard stats
  static Future<void> checkUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return;
    }

    try {
      final stats = await _db.getUserStats(user.uid);
      print('📊 User Stats for ${user.displayName ?? user.email}:');
      print('   Total Quizzes: ${stats['totalQuizzes']}');
      print('   Total Score: ${stats['totalScore']}');
      print('   Average %: ${(stats['averagePercentage'] as double).toStringAsFixed(1)}%');
      print('   Best Score: ${stats['bestScore']}');

      // Check leaderboard position
      final position = await _db.getUserLeaderboardPosition(user.uid);
      if (position != null) {
        print('🏆 Leaderboard Position: #${position['rank']}');
      } else {
        print('❌ Not found in leaderboard');
      }
      
    } catch (e) {
      print('❌ Error checking stats: $e');
    }
  }

  /// Get top leaderboard entries
  static Future<void> showLeaderboard() async {
    try {
      final leaderboard = await _db.getLeaderboardData(limit: 10);
      
      print('🏆 TOP 10 LEADERBOARD:');
      print('=' * 50);
      
      if (leaderboard.isEmpty) {
        print('No users found in leaderboard.');
        print('Make sure users have completed quizzes!');
        return;
      }

      for (final entry in leaderboard) {
        final rank = entry['rank'];
        final name = entry['displayName'] ?? 'Anonymous';
        final score = entry['totalScore'];
        final quizzes = entry['totalQuizzes'];
        
        String medal = '';
        if (rank == 1) medal = '🥇';
        else if (rank == 2) medal = '🥈';
        else if (rank == 3) medal = '🥉';
        
        print('$medal #$rank - $name');
        print('    Score: $score | Quizzes: $quizzes');
      }
      
    } catch (e) {
      print('❌ Error showing leaderboard: $e');
    }
  }
}
