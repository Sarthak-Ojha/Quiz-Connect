import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_challenge.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../services/streak_service.dart';
import '../services/database_service.dart';
import 'quiz_result_screen.dart';
import 'quiz_screen.dart';

class DailyChallengeScreen extends StatefulWidget {
  final DailyChallenge challenge;
  final List<Question> questions;

  const DailyChallengeScreen({
    super.key,
    required this.challenge,
    required this.questions,
  });

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressAnimationController;
  late AnimationController _timerAnimationController;

  final StreakService _streakService = StreakService();
  final DatabaseService _dbService = DatabaseService();

  int _currentQuestionIndex = 0;
  List<String> _userAnswers = [];
  int _correctAnswers = 0;
  bool _isAnswered = false;
  bool _isLoading = false;
  UserChallengeProgress? _progress;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _timerAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _userAnswers = List.filled(widget.questions.length, '');
    _loadProgress();
    _startTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController.dispose();
    _timerAnimationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timerAnimationController.repeat();
  }

  Future<void> _loadProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final progress = await _streakService.getUserChallengeProgress(
        user.uid,
        widget.challenge.challengeId,
      );

      if (progress == null) {
        // Start new challenge
        final newProgress = await _streakService.startChallenge(
          user.uid,
          widget.challenge,
        );
        setState(() {
          _progress = newProgress;
        });
      } else {
        setState(() {
          _progress = progress;
          _currentQuestionIndex = progress.questionsCompleted;
        });
      }
    }
  }

  void _selectAnswer(String answer) {
    if (_isAnswered) return;

    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
      _isAnswered = true;
    });

    final currentQuestion = widget.questions[_currentQuestionIndex];
    final correctAnswer = currentQuestion.options[currentQuestion.correctIndex];

    if (answer == correctAnswer) {
      _correctAnswers++;
    }

    _progressAnimationController.forward();

    // Auto-advance after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _progressAnimationController.reset();
    } else {
      _finishChallenge();
    }
  }

  Future<void> _finishChallenge() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update challenge progress
      await _streakService.updateChallengeProgress(
        user.uid,
        widget.challenge.challengeId,
        widget.questions.length,
        _correctAnswers,
      );

      // Update user streak
      final updatedStreak = await _streakService.updateUserStreak(user.uid);

      // Save quiz result
      final percentage = (_correctAnswers / widget.questions.length) * 100;
      final quizResult = QuizResult(
        userId: user.uid,
        categoryName: 'Daily Challenge',
        categoryColor: _getDifficultyColor().value.toRadixString(16),
        totalQuestions: widget.questions.length,
        correctAnswers: _correctAnswers,
        wrongAnswers: widget.questions.length - _correctAnswers,
        totalScore: _calculateScore(),
        percentage: percentage,
        isTimerMode: false,
        completedAt: DateTime.now(),
        userAnswers: _userAnswers,
        questions: widget.questions.map((q) => q.question).toList(),
      );

      await _dbService.saveQuizResult(quizResult);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              result: quizResult,
              questions: widget.questions,
              isChallenge: true,
              streakInfo: {
                'currentStreak': updatedStreak.streakCount,
                'isNewRecord':
                    updatedStreak.streakCount == updatedStreak.maxStreak,
                'pointsEarned': _calculateChallengePoints(),
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _calculateScore() {
    return _correctAnswers * 20; // Base score per correct answer
  }

  int _calculateChallengePoints() {
    final percentage = (_correctAnswers / widget.questions.length) * 100;
    int points = widget.challenge.rewardPoints;

    if (percentage == 100) {
      points = (points * 1.5).round(); // Perfect bonus
    } else if (percentage >= 80) {
      points = (points * 1.2).round(); // Good performance bonus
    }

    return points;
  }

  Color _getDifficultyColor() {
    switch (widget.challenge.difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'hard':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _getDifficultyColor().withOpacity(0.1),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Completing challenge...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _getDifficultyColor().withOpacity(0.05),
      appBar: AppBar(
        backgroundColor: _getDifficultyColor(),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Daily Challenge ${widget.challenge.difficultyEmoji}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _timerAnimationController,
                  child: const Icon(Icons.timer, size: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  widget.challenge.timeRemainingText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getDifficultyColor(),
              boxShadow: [
                BoxShadow(
                  color: _getDifficultyColor().withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.challenge.rewardPoints} pts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      (_currentQuestionIndex + (_isAnswered ? 1 : 0)) /
                      widget.questions.length,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ],
            ),
          ),

          // Question Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                return _buildQuestionCard(question);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Question Card
          Card(
            elevation: 8,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    _getDifficultyColor().withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.quiz, color: _getDifficultyColor(), size: 32),
                  const SizedBox(height: 16),
                  Text(
                    question.question,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Answer Options
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final option = question.options[index];
                final isSelected =
                    _userAnswers[_currentQuestionIndex] == option;
                final isCorrect = index == question.correctIndex;

                Color cardColor = Colors.white;
                Color borderColor = Colors.grey.shade300;
                Color textColor = Colors.grey.shade800;

                if (_isAnswered) {
                  if (isCorrect) {
                    cardColor = Colors.green.shade50;
                    borderColor = Colors.green;
                    textColor = Colors.green.shade700;
                  } else if (isSelected && !isCorrect) {
                    cardColor = Colors.red.shade50;
                    borderColor = Colors.red;
                    textColor = Colors.red.shade700;
                  }
                } else if (isSelected) {
                  cardColor = _getDifficultyColor().withOpacity(0.1);
                  borderColor = _getDifficultyColor();
                  textColor = _getDifficultyColor();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: isSelected ? 4 : 2,
                    child: InkWell(
                      onTap: () => _selectAnswer(option),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: borderColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (_isAnswered && isCorrect)
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            if (_isAnswered && isSelected && !isCorrect)
                              Icon(Icons.cancel, color: Colors.red, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
