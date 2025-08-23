class DailyChallenge {
  final int? id;
  final String challengeId;
  final DateTime date;
  final List<int> questionIds;
  final String difficulty;
  final int rewardPoints;
  final bool isActive;
  final DateTime expiresAt;
  final DateTime createdAt;

  DailyChallenge({
    this.id,
    required this.challengeId,
    required this.date,
    required this.questionIds,
    required this.difficulty,
    required this.rewardPoints,
    required this.isActive,
    required this.expiresAt,
    required this.createdAt,
  });

  factory DailyChallenge.fromMap(Map<String, dynamic> map) {
    return DailyChallenge(
      id: map['id'],
      challengeId: map['challengeId'],
      date: DateTime.parse(map['date']),
      questionIds: (map['questionIds'] as String)
          .split(',')
          .map((id) => int.parse(id))
          .toList(),
      difficulty: map['difficulty'],
      rewardPoints: map['rewardPoints'],
      isActive: map['isActive'] == 1,
      expiresAt: DateTime.parse(map['expiresAt']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'date': date.toIso8601String().split('T')[0], // Store as YYYY-MM-DD
      'questionIds': questionIds.join(','),
      'difficulty': difficulty,
      'rewardPoints': rewardPoints,
      'isActive': isActive ? 1 : 0,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }

  String get timeRemainingText {
    final remaining = timeRemaining;
    if (remaining == Duration.zero) return "Expired";
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return "${hours}h ${minutes}m left";
    } else {
      return "${minutes}m left";
    }
  }

  String get difficultyEmoji {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '🟢';
      case 'medium':
        return '🟡';
      case 'hard':
        return '🔴';
      default:
        return '⚪';
    }
  }

  String get difficultyText {
    return difficulty.toUpperCase();
  }
}

