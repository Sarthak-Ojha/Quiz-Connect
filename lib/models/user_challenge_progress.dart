class UserChallengeProgress {
  final int? id;
  final String userId;
  final String challengeId;
  final int questionsCompleted;
  final int totalQuestions;
  final bool isCompleted;
  final int pointsEarned;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserChallengeProgress({
    this.id,
    required this.userId,
    required this.challengeId,
    required this.questionsCompleted,
    required this.totalQuestions,
    required this.isCompleted,
    required this.pointsEarned,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserChallengeProgress.fromMap(Map<String, dynamic> map) {
    return UserChallengeProgress(
      id: map['id'],
      userId: map['userId'],
      challengeId: map['challengeId'],
      questionsCompleted: map['questionsCompleted'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      isCompleted: map['isCompleted'] == 1,
      pointsEarned: map['pointsEarned'] ?? 0,
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'questionsCompleted': questionsCompleted,
      'totalQuestions': totalQuestions,
      'isCompleted': isCompleted ? 1 : 0,
      'pointsEarned': pointsEarned,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  double get progressPercentage {
    if (totalQuestions == 0) return 0.0;
    return (questionsCompleted / totalQuestions) * 100;
  }

  int get questionsRemaining => totalQuestions - questionsCompleted;

  bool get canAttempt => !isCompleted && questionsRemaining > 0;
}
