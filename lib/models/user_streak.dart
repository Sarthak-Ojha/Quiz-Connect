class UserStreak {
  final int? id;
  final String userId;
  final int streakCount;
  final DateTime? lastActive;
  final int maxStreak;
  final DateTime? currentStreakStartDate;
  final int totalDaysActive;
  final int totalPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStreak({
    this.id,
    required this.userId,
    required this.streakCount,
    this.lastActive,
    required this.maxStreak,
    this.currentStreakStartDate,
    required this.totalDaysActive,
    required this.totalPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserStreak.fromMap(Map<String, dynamic> map) {
    return UserStreak(
      id: map['id'],
      userId: map['userId'],
      streakCount: map['streakCount'] ?? 0,
      lastActive: map['lastActive'] != null 
          ? DateTime.parse(map['lastActive']) 
          : null,
      maxStreak: map['maxStreak'] ?? 0,
      currentStreakStartDate: map['currentStreakStartDate'] != null
          ? DateTime.parse(map['currentStreakStartDate'])
          : null,
      totalDaysActive: map['totalDaysActive'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'streakCount': streakCount,
      'lastActive': lastActive?.toIso8601String(),
      'maxStreak': maxStreak,
      'currentStreakStartDate': currentStreakStartDate?.toIso8601String(),
      'totalDaysActive': totalDaysActive,
      'totalPoints': totalPoints,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserStreak copyWith({
    int? id,
    String? userId,
    int? streakCount,
    DateTime? lastActive,
    int? maxStreak,
    DateTime? currentStreakStartDate,
    int? totalDaysActive,
    int? totalPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStreak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      streakCount: streakCount ?? this.streakCount,
      lastActive: lastActive ?? this.lastActive,
      maxStreak: maxStreak ?? this.maxStreak,
      currentStreakStartDate: currentStreakStartDate ?? this.currentStreakStartDate,
      totalDaysActive: totalDaysActive ?? this.totalDaysActive,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get hasActiveStreak => streakCount > 0;
  
  int get daysUntilNextMilestone {
    const milestones = [7, 14, 30, 60, 100];
    for (int milestone in milestones) {
      if (streakCount < milestone) {
        return milestone - streakCount;
      }
    }
    return 0; // Already at max milestone
  }

  int get nextMilestone {
    const milestones = [7, 14, 30, 60, 100];
    for (int milestone in milestones) {
      if (streakCount < milestone) {
        return milestone;
      }
    }
    return 100; // Max milestone
  }

  String get streakMessage {
    if (streakCount == 0) return "Start your streak today! 🚀";
    if (streakCount == 1) return "Great start! Keep it going! 💪";
    if (streakCount < 7) return "Building momentum! 🔥";
    if (streakCount < 14) return "You're on fire! 🔥🔥";
    if (streakCount < 30) return "Incredible dedication! 🏆";
    if (streakCount < 60) return "Streak master! 👑";
    return "Legendary streak! 🌟";
  }
}
