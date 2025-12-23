// lib/screens/multiplayer_quiz_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/multiplayer_game.dart';
import '../models/question.dart';
import '../services/database_service.dart';

class MultiplayerQuizScreen extends StatefulWidget {
  final String gameId;
  final bool isHost;

  const MultiplayerQuizScreen({
    Key? key,
    required this.gameId,
    required this.isHost,
  }) : super(key: key);

  @override
  State<MultiplayerQuizScreen> createState() => _MultiplayerQuizScreenState();
}

class _MultiplayerQuizScreenState extends State<MultiplayerQuizScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  static const int _questionDurationSeconds = 10;
  
  String? _selectedAnswer;
  bool _hasAnswered = false;
  bool _isSubmittingAnswer = false;
  int? _answeredQuestionIndex;
  List<Question> _questions = [];
  bool _questionsLoaded = false;
  int _timeRemaining = _questionDurationSeconds;
  Timer? _timer;
  bool _isStartingGame = false;
  bool _isAdvancingQuestion = false;
  int _currentQuestionIndex = 0;
  DateTime? _questionStartTime;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(MultiplayerGame game) {
    if (game.questionStartTime == null) {
      return;
    }

    _questionStartTime = game.questionStartTime;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final elapsedSeconds = DateTime.now().difference(game.questionStartTime!).inSeconds;
      final remaining = _questionDurationSeconds - elapsedSeconds;
      final clampedRemaining = remaining.clamp(0, _questionDurationSeconds);

      if (clampedRemaining > 0) {
        if (mounted) {
          setState(() {
            _timeRemaining = clampedRemaining;
          });
        }
        return;
      }

      timer.cancel();
      if (mounted) {
        setState(() {
          _timeRemaining = 0;
        });
      }

      if (!_hasAnswered) {
        _submitAnswer();
      }

      if (widget.isHost && !_isAdvancingQuestion) {
        _isAdvancingQuestion = true;
        _advanceGame(game);
      }
    });
  }

  Future<void> _submitAnswer() async {
    if (_hasAnswered || _isSubmittingAnswer) return;
    if (_answeredQuestionIndex == _currentQuestionIndex) return;
    
    setState(() {
      _hasAnswered = true;
      _isSubmittingAnswer = true;
      _answeredQuestionIndex = _currentQuestionIndex;
    });
    
    // Submit as wrong answer (no selection made)
    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .update({
      'scores.$currentUserId.totalAnswered': FieldValue.increment(1),
    });
    // Debug: Log totalAnswered for both players after update
    final gameDoc = await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .get();
    final game = MultiplayerGame.fromFirestore(gameDoc);
    final opponentId = game.hostId == currentUserId ? game.guestId : game.hostId;
    debugPrint('📝 After auto-submit: my totalAnswered: \\${game.scores[currentUserId]?.totalAnswered}, opponent totalAnswered: \\${game.scores[opponentId]?.totalAnswered}');
    if (mounted) {
      setState(() {
        _isSubmittingAnswer = false;
      });
    }
  }

  Future<void> _loadQuestions() async {
    final gameDoc = await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .get();
    
    if (!gameDoc.exists) return;
    
    final game = MultiplayerGame.fromFirestore(gameDoc);
    final questions = await _databaseService.getQuestionsByIds(game.questionIds);
    
    setState(() {
      _questions = questions;
      _questionsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Game?'),
            content: const Text('Are you sure you want to leave this game?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        return shouldLeave ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('1v1 Quiz Battle'),
          centerTitle: true,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('multiplayer_games')
              .doc(widget.gameId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final game = MultiplayerGame.fromFirestore(snapshot.data!);
            
            debugPrint('🎮 Game status: ${game.status}, isHost: ${widget.isHost}, guestId: ${game.guestId}');

            // Waiting for opponent
            if (game.status == GameStatus.waiting) {
              debugPrint('⏳ Waiting for opponent...');
              return _buildWaitingScreen(game);
            }

            // Auto-start game when ready (only host starts the game)
            if (game.status == GameStatus.ready) {
              debugPrint('✅ Game ready! isHost: ${widget.isHost}, _isStartingGame: $_isStartingGame');
              if (widget.isHost && !_isStartingGame) {
                _isStartingGame = true;
                debugPrint('🚀 Host starting game...');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startGame();
                });
              } else if (!widget.isHost) {
                debugPrint('👤 Guest waiting for host to start...');
              }
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Starting game...', style: TextStyle(fontSize: 18)),
                  ],
                ),
              );
            }

            // Game in progress
            if (game.status == GameStatus.inProgress) {
              if (!_questionsLoaded) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Check if question index changed - reset answer state for both players
              if (game.currentQuestionIndex != _currentQuestionIndex || game.questionStartTime != _questionStartTime) {
                debugPrint('📝 Question changed from $_currentQuestionIndex to ${game.currentQuestionIndex}');
                _currentQuestionIndex = game.currentQuestionIndex;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedAnswer = null;
                      _hasAnswered = false;
                      _isSubmittingAnswer = false;
                      _answeredQuestionIndex = null;
                      _timeRemaining = _questionDurationSeconds;
                    });
                    _startTimer(game);
                  }
                });
              }
              
              // Start timer for new question
              if (!_hasAnswered && (_timer == null || !_timer!.isActive)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startTimer(game);
                });
              }
              return _buildGameScreen(game);
            }

            // Game completed
            if (game.status == GameStatus.completed) {
              return _buildResultsScreen(game);
            }

            return const Center(child: Text('Unknown game state'));
          },
        ),
      ),
    );
  }

  Widget _buildWaitingScreen(MultiplayerGame game) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Waiting for opponent to join...',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Text(
            'Game ID: ${widget.gameId}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (widget.isHost)
            ElevatedButton(
              onPressed: () => _cancelGame(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel Game'),
            ),
        ],
      ),
    );
  }


  Widget _buildGameScreen(MultiplayerGame game) {
    if (game.currentQuestionIndex >= _questions.length) {
      return const Center(child: Text('Loading next question...'));
    }

    final question = _questions[game.currentQuestionIndex];
    final myScore = game.scores[currentUserId];

    return Column(
      children: [
        // Score bar with timer
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreCard('Your Score', myScore?.correctAnswers ?? 0, true),
              Column(
                children: [
                  Text(
                    '${game.currentQuestionIndex + 1}/${game.questionCount}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 3 ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '⏱️ $_timeRemaining s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 80),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Answer options
                Expanded(
                  child: ListView.builder(
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final option = question.options[index];
                      final isSelected = _selectedAnswer == option;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ElevatedButton(
                          onPressed: _hasAnswered
                              ? null
                              : () => _selectAnswer(option, index, question.correctIndex),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: isSelected
                                ? Colors.blue
                                : Colors.grey[300],
                            foregroundColor: isSelected
                                ? Colors.white
                                : Colors.black,
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Waiting indicator
                if (_hasAnswered)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Waiting for question to end...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(String label, int score, bool isMe) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsScreen(MultiplayerGame game) {
    final myScore = game.scores[currentUserId];
    final opponentId = game.hostId == currentUserId ? game.guestId : game.hostId;
    final opponentScore = game.scores[opponentId];
    
    final myCorrect = myScore?.correctAnswers ?? 0;
    final opponentCorrect = opponentScore?.correctAnswers ?? 0;
    
    final isWinner = myCorrect > opponentCorrect;
    final isDraw = myCorrect == opponentCorrect;
    
    String winnerText;
    if (isDraw) {
      winnerText = 'It\'s a Draw!';
    } else if (isWinner) {
      winnerText = '🏆 You Won! 🏆';
    } else {
      winnerText = 'Opponent Won!';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDraw ? Icons.handshake : (isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied),
              size: 100,
              color: isDraw ? Colors.orange : (isWinner ? Colors.amber : Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              winnerText,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDraw ? Colors.orange : (isWinner ? Colors.green : Colors.red),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Game Over',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Final Scores',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isWinner ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$myCorrect',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: isWinner ? Colors.green : Colors.black,
                              ),
                            ),
                            Text(
                              'out of ${game.questionCount}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (isWinner && !isDraw)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                              ),
                          ],
                        ),
                        Container(
                          height: 80,
                          width: 2,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: !isWinner && !isDraw ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Opponent',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '$opponentCorrect',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: !isWinner && !isDraw ? Colors.green : Colors.black,
                              ),
                            ),
                            Text(
                              'out of ${game.questionCount}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!isWinner && !isDraw)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text('Back to Friends', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectAnswer(String answer, int answerIndex, int correctIndex) async {
    if (_hasAnswered || _isSubmittingAnswer) return;
    if (_answeredQuestionIndex == _currentQuestionIndex) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
      _isSubmittingAnswer = true;
      _answeredQuestionIndex = _currentQuestionIndex;
    });

    final isCorrect = answerIndex == correctIndex;

    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .update({
      'scores.$currentUserId.answers': FieldValue.arrayUnion([
        PlayerAnswer(
          questionIndex: (await FirebaseFirestore.instance
                  .collection('multiplayer_games')
                  .doc(widget.gameId)
                  .get())
              .data()!['currentQuestionIndex'],
          selectedAnswer: answer,
          isCorrect: isCorrect,
          answeredAt: DateTime.now(),
        ).toMap(),
      ]),
      'scores.$currentUserId.totalAnswered': FieldValue.increment(1),
      if (isCorrect) 'scores.$currentUserId.correctAnswers': FieldValue.increment(1),
    });
    // Debug: Log totalAnswered for both players after update
    final gameDoc = await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .get();
    final game = MultiplayerGame.fromFirestore(gameDoc);
    final opponentId = game.hostId == currentUserId ? game.guestId : game.hostId;
    debugPrint('📝 After answer: my totalAnswered: \\${game.scores[currentUserId]?.totalAnswered}, opponent totalAnswered: \\${game.scores[opponentId]?.totalAnswered}');

    if (mounted) {
      setState(() {
        _isSubmittingAnswer = false;
      });
    }
  }

  Future<void> _advanceGame(MultiplayerGame game) async {
    try {
      if (game.currentQuestionIndex + 1 >= game.questionCount) {
        debugPrint('🏁 Game completed!');
        await FirebaseFirestore.instance
            .collection('multiplayer_games')
            .doc(widget.gameId)
            .update({
          'status': GameStatus.completed.toString().split('.').last,
          'completedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('➡️ Moving to question ${game.currentQuestionIndex + 2}');
        await FirebaseFirestore.instance
            .collection('multiplayer_games')
            .doc(widget.gameId)
            .update({
          'currentQuestionIndex': FieldValue.increment(1),
          'questionStartTime': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() {
            _selectedAnswer = null;
            _hasAnswered = false;
          });
        }
      }
    } finally {
      _isAdvancingQuestion = false;
    }
  }

  Future<void> _startGame() async {
    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .update({
      'status': GameStatus.inProgress.toString().split('.').last,
      'startedAt': FieldValue.serverTimestamp(),
      'questionStartTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _cancelGame() async {
    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .update({
      'status': GameStatus.cancelled.toString().split('.').last,
    });
    
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
