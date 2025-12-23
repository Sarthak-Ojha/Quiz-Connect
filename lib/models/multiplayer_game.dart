// lib/models/multiplayer_game.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MultiplayerGame {
  final String gameId;
  final String hostId;
  final String? guestId;
  final String category;
  final int questionCount;
  final GameStatus status;
  final Map<String, PlayerScore> scores;
  final List<String> questionIds;
  final int currentQuestionIndex;
  final DateTime? questionStartTime;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  MultiplayerGame({
    required this.gameId,
    required this.hostId,
    this.guestId,
    required this.category,
    required this.questionCount,
    required this.status,
    required this.scores,
    required this.questionIds,
    this.currentQuestionIndex = 0,
    this.questionStartTime,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory MultiplayerGame.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MultiplayerGame(
      gameId: doc.id,
      hostId: data['hostId'] ?? '',
      guestId: data['guestId'],
      category: data['category'] ?? '',
      questionCount: data['questionCount'] ?? 10,
      status: GameStatus.values.firstWhere(
        (e) => e.toString() == 'GameStatus.${data['status']}',
        orElse: () => GameStatus.waiting,
      ),
      scores: (data['scores'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              PlayerScore.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      questionIds: List<String>.from(data['questionIds'] ?? []),
      currentQuestionIndex: data['currentQuestionIndex'] ?? 0,
      questionStartTime: data['questionStartTime'] != null
          ? (data['questionStartTime'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'guestId': guestId,
      'category': category,
      'questionCount': questionCount,
      'status': status.toString().split('.').last,
      'scores': scores.map((key, value) => MapEntry(key, value.toMap())),
      'questionIds': questionIds,
      'currentQuestionIndex': currentQuestionIndex,
      'questionStartTime':
          questionStartTime != null ? Timestamp.fromDate(questionStartTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

class PlayerScore {
  final int correctAnswers;
  final int totalAnswered;
  final List<PlayerAnswer> answers;

  PlayerScore({
    this.correctAnswers = 0,
    this.totalAnswered = 0,
    this.answers = const [],
  });

  factory PlayerScore.fromMap(Map<String, dynamic> map) {
    return PlayerScore(
      correctAnswers: map['correctAnswers'] ?? 0,
      totalAnswered: map['totalAnswered'] ?? 0,
      answers: (map['answers'] as List<dynamic>?)
              ?.map((a) => PlayerAnswer.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'correctAnswers': correctAnswers,
      'totalAnswered': totalAnswered,
      'answers': answers.map((a) => a.toMap()).toList(),
    };
  }
}

class PlayerAnswer {
  final int questionIndex;
  final String selectedAnswer;
  final bool isCorrect;
  final DateTime answeredAt;

  PlayerAnswer({
    required this.questionIndex,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory PlayerAnswer.fromMap(Map<String, dynamic> map) {
    return PlayerAnswer(
      questionIndex: map['questionIndex'] ?? 0,
      selectedAnswer: map['selectedAnswer'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
      answeredAt: (map['answeredAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionIndex': questionIndex,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'answeredAt': Timestamp.fromDate(answeredAt),
    };
  }
}

enum GameStatus {
  waiting, // Waiting for opponent to join
  ready, // Both players joined, ready to start
  inProgress, // Game is active
  completed, // Game finished
  cancelled, // Game was cancelled
}
