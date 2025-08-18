class QuizResult {
  final int? id;
  final String userId;
  final String categoryName;
  final String? categoryColor; // Store as hex string
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalScore;
  final double percentage;
  final bool isTimerMode;
  final int timerSeconds;
  final DateTime completedAt;
  final List<String> userAnswers;
  final List<String> questions;

  QuizResult({
    this.id,
    required this.userId,
    required this.categoryName,
    this.categoryColor,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalScore,
    required this.percentage,
    required this.isTimerMode,
    this.timerSeconds = 0,
    required this.completedAt,
    required this.userAnswers,
    required this.questions,
  });

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'],
      userId: map['userId'],
      categoryName: map['categoryName'],
      categoryColor: map['categoryColor'],
      totalQuestions: map['totalQuestions'],
      correctAnswers: map['correctAnswers'],
      wrongAnswers: map['wrongAnswers'],
      totalScore: map['totalScore'],
      percentage: map['percentage'],
      isTimerMode: map['isTimerMode'] == 1,
      timerSeconds: map['timerSeconds'] ?? 0,
      completedAt: DateTime.parse(map['completedAt']),
      userAnswers: (map['userAnswers'] as String).split('|'),
      questions: (map['questions'] as String).split('|'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categoryName': categoryName,
      'categoryColor': categoryColor,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'totalScore': totalScore,
      'percentage': percentage,
      'isTimerMode': isTimerMode ? 1 : 0,
      'timerSeconds': timerSeconds,
      'completedAt': completedAt.toIso8601String(),
      'userAnswers': userAnswers.join('|'),
      'questions': questions.join('|'),
    };
  }

  // Helper getters
  String get grade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  String get performance {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 80) return 'Very Good';
    if (percentage >= 70) return 'Good';
    if (percentage >= 60) return 'Average';
    if (percentage >= 50) return 'Below Average';
    return 'Poor';
  }
}
