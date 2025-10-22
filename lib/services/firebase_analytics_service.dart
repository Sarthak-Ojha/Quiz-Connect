import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics Service for monitoring user patterns and behavior
/// This helps developers understand how users interact with the quiz app
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer = FirebaseAnalyticsObserver(analytics: _analytics);
  
  /// Get the analytics observer for navigation tracking
  static FirebaseAnalyticsObserver get observer => _observer;

  // ============================================================================
  // USER AUTHENTICATION EVENTS
  // ============================================================================

  /// Track user sign up
  static Future<void> trackUserSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    debugPrint('📊 Analytics: User signed up via $method');
  }

  /// Track user sign in
  static Future<void> trackUserSignIn(String method) async {
    await _analytics.logLogin(loginMethod: method);
    debugPrint('📊 Analytics: User signed in via $method');
  }

  /// Track user sign out
  static Future<void> trackUserSignOut() async {
    await _analytics.logEvent(name: 'user_sign_out');
    debugPrint('📊 Analytics: User signed out');
  }

  // ============================================================================
  // QUIZ ENGAGEMENT EVENTS
  // ============================================================================

  /// Track quiz started
  static Future<void> trackQuizStarted({
    required String category,
    required int questionCount,
    required bool isTimerMode,
    int? timerSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_started',
      parameters: {
        'category': category,
        'question_count': questionCount,
        'timer_mode': isTimerMode,
        'timer_seconds': timerSeconds ?? 0,
      },
    );
    debugPrint('📊 Analytics: Quiz started - $category ($questionCount questions)');
  }

  /// Track quiz completed
  static Future<void> trackQuizCompleted({
    required String category,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required double percentage,
    required bool isTimerMode,
    int? timerSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_completed',
      parameters: {
        'category': category,
        'score': score,
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'percentage': percentage,
        'timer_mode': isTimerMode,
        'timer_seconds': timerSeconds ?? 0,
        'performance_level': _getPerformanceLevel(percentage),
      },
    );
    debugPrint('📊 Analytics: Quiz completed - $category: $score points (${percentage.toStringAsFixed(1)}%)');
  }

  /// Track quiz abandoned (user quit mid-quiz)
  static Future<void> trackQuizAbandoned({
    required String category,
    required int questionsAnswered,
    required int totalQuestions,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_abandoned',
      parameters: {
        'category': category,
        'questions_answered': questionsAnswered,
        'total_questions': totalQuestions,
        'completion_rate': (questionsAnswered / totalQuestions) * 100,
      },
    );
    debugPrint('📊 Analytics: Quiz abandoned - $category ($questionsAnswered/$totalQuestions)');
  }

  // ============================================================================
  // USER ENGAGEMENT EVENTS
  // ============================================================================

  /// Track leaderboard viewed
  static Future<void> trackLeaderboardViewed({String? filterType}) async {
    await _analytics.logEvent(
      name: 'leaderboard_viewed',
      parameters: {
        'filter_type': filterType ?? 'total_score',
      },
    );
    debugPrint('📊 Analytics: Leaderboard viewed (filter: ${filterType ?? 'total_score'})');
  }

  /// Track streak screen viewed
  static Future<void> trackStreakViewed({int? currentStreak}) async {
    await _analytics.logEvent(
      name: 'streak_viewed',
      parameters: {
        'current_streak': currentStreak ?? 0,
      },
    );
    debugPrint('📊 Analytics: Streak screen viewed (streak: ${currentStreak ?? 0})');
  }

  /// Track daily challenge started
  static Future<void> trackDailyChallengeStarted({
    required String difficulty,
    required int rewardPoints,
  }) async {
    await _analytics.logEvent(
      name: 'daily_challenge_started',
      parameters: {
        'difficulty': difficulty,
        'reward_points': rewardPoints,
      },
    );
    debugPrint('📊 Analytics: Daily challenge started - $difficulty');
  }

  /// Track daily challenge completed
  static Future<void> trackDailyChallengeCompleted({
    required String difficulty,
    required int pointsEarned,
    required bool completed,
  }) async {
    await _analytics.logEvent(
      name: 'daily_challenge_completed',
      parameters: {
        'difficulty': difficulty,
        'points_earned': pointsEarned,
        'completed': completed,
      },
    );
    debugPrint('📊 Analytics: Daily challenge ${completed ? 'completed' : 'failed'} - $pointsEarned points');
  }

  // ============================================================================
  // APP USAGE EVENTS
  // ============================================================================

  /// Track app session start
  static Future<void> trackSessionStart() async {
    await _analytics.logAppOpen();
    debugPrint('📊 Analytics: App session started');
  }

  /// Track settings viewed
  static Future<void> trackSettingsViewed() async {
    await _analytics.logEvent(name: 'settings_viewed');
    debugPrint('📊 Analytics: Settings viewed');
  }

  /// Track theme changed
  static Future<void> trackThemeChanged(String theme) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {'theme': theme},
    );
    debugPrint('📊 Analytics: Theme changed to $theme');
  }

  /// Track AI mode used
  static Future<void> trackAIModeUsed() async {
    await _analytics.logEvent(name: 'ai_mode_used');
    debugPrint('📊 Analytics: AI mode used');
  }

  // ============================================================================
  // USER PROPERTIES (for segmentation)
  // ============================================================================

  /// Set user properties for better analytics segmentation
  static Future<void> setUserProperties({
    required String userId,
    String? displayName,
    String? email,
    bool? emailVerified,
  }) async {
    await _analytics.setUserId(id: userId);
    
    if (displayName != null) {
      await _analytics.setUserProperty(name: 'display_name', value: displayName);
    }
    
    if (emailVerified != null) {
      await _analytics.setUserProperty(name: 'email_verified', value: emailVerified.toString());
    }
    
    debugPrint('📊 Analytics: User properties set for $userId');
  }

  /// Update user level based on total quizzes completed
  static Future<void> updateUserLevel(int totalQuizzes) async {
    String level = 'beginner';
    if (totalQuizzes >= 50) level = 'expert';
    else if (totalQuizzes >= 20) level = 'advanced';
    else if (totalQuizzes >= 5) level = 'intermediate';
    
    await _analytics.setUserProperty(name: 'user_level', value: level);
    debugPrint('📊 Analytics: User level updated to $level ($totalQuizzes quizzes)');
  }

  // ============================================================================
  // CUSTOM EVENTS FOR SPECIFIC INSIGHTS
  // ============================================================================

  /// Track user achievement
  static Future<void> trackAchievement({
    required String achievementType,
    required String achievementName,
    int? value,
  }) async {
    await _analytics.logEvent(
      name: 'achievement_unlocked',
      parameters: {
        'achievement_type': achievementType,
        'achievement_name': achievementName,
        'value': value ?? 0,
      },
    );
    debugPrint('📊 Analytics: Achievement unlocked - $achievementName');
  }

  /// Track user retention milestone
  static Future<void> trackRetentionMilestone(int daysActive) async {
    await _analytics.logEvent(
      name: 'retention_milestone',
      parameters: {'days_active': daysActive},
    );
    debugPrint('📊 Analytics: Retention milestone - $daysActive days active');
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get performance level based on percentage
  static String _getPerformanceLevel(double percentage) {
    if (percentage >= 90) {
      return 'excellent';
    }
    if (percentage >= 80) {
      return 'good';
    }
    if (percentage >= 70) {
      return 'average';
    }
    if (percentage >= 60) {
      return 'below_average';
    }
    return 'poor';
  }

  /// Enable debug mode for analytics (development only)
  static Future<void> enableDebugMode() async {
    if (kDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('📊 Analytics: Debug mode enabled');
    }
  }

  /// Disable analytics collection (for privacy)
  static Future<void> disableAnalytics() async {
    await _analytics.setAnalyticsCollectionEnabled(false);
    debugPrint('📊 Analytics: Collection disabled');
  }
}
