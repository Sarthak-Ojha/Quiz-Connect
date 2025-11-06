class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int totalScore;
  final int totalQuizzes;
  final double averageScore;
  final int currentStreak;
  final int maxStreak;
  final DateTime lastActivity;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.totalScore,
    required this.totalQuizzes,
    required this.averageScore,
    required this.currentStreak,
    required this.maxStreak,
    required this.lastActivity,
    this.rank = 0,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    DateTime lastActivityDate;
    
    if (map['lastActivity'] != null) {
      // Handle both Timestamp and String formats
      if (map['lastActivity'] is String) {
        lastActivityDate = DateTime.parse(map['lastActivity']);
      } else {
        // Assume it's a Firestore Timestamp
        lastActivityDate = (map['lastActivity'] as dynamic).toDate();
      }
    } else {
      lastActivityDate = DateTime.now();
    }
    
    return LeaderboardEntry(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Anonymous',
      photoUrl: map['photoUrl'],
      totalScore: map['totalScore'] ?? 0,
      totalQuizzes: map['totalQuizzes'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      currentStreak: map['currentStreak'] ?? 0,
      maxStreak: map['maxStreak'] ?? 0,
      lastActivity: lastActivityDate,
      rank: map['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'totalScore': totalScore,
      'totalQuizzes': totalQuizzes,
      'averageScore': averageScore,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'lastActivity': lastActivity.toIso8601String(),
      'rank': rank,
    };
  }

  // Helper getters
  String get scoreDisplay => totalScore.toString();
  
  String get averageDisplay => averageScore.toStringAsFixed(1);
  
  String get activityDisplay {
    final now = DateTime.now();
    final difference = now.difference(lastActivity);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get rankDisplay {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '#$rank';
  }

  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    int? totalScore,
    int? totalQuizzes,
    double? averageScore,
    int? currentStreak,
    int? maxStreak,
    DateTime? lastActivity,
    int? rank,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      totalScore: totalScore ?? this.totalScore,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      averageScore: averageScore ?? this.averageScore,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      lastActivity: lastActivity ?? this.lastActivity,
      rank: rank ?? this.rank,
    );
  }
}

enum LeaderboardType {
  totalScore,
  totalQuizzes,
}

extension LeaderboardTypeExtension on LeaderboardType {
  String get displayName {
    switch (this) {
      case LeaderboardType.totalScore:
        return 'Total Points';
      case LeaderboardType.totalQuizzes:
        return 'Total Quizzes';
    }
  }

  String get icon {
    switch (this) {
      case LeaderboardType.totalScore:
        return '🏆';
      case LeaderboardType.totalQuizzes:
        return '📚';
    }
  }
}
