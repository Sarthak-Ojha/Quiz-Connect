// lib/screens/quiz_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../models/quiz_category.dart';
import '../models/quiz_result.dart';
import '../services/database_service.dart';
import '../services/streak_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final QuizCategory? category;
  final bool isAIMode;
  final String? aiTopic;

  const QuizScreen({
    super.key,
    required this.questions,
    this.category,
    this.isAIMode = false,
    this.aiTopic,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  final List<String> _userAnswers = [];
  String? _selectedAnswer;
  bool _hasAnswered = false;
  int _score = 0;
  final StreakService _streakService = StreakService();
  final DatabaseService _dbService = DatabaseService();

  Question get _currentQuestion => widget.questions[_currentQuestionIndex];
  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.questions.length - 1;

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;

      // Check if answer is correct and update score
      if (answer == _currentQuestion.options[_currentQuestion.correctIndex]) {
        _score++;
      }
    });

    // Auto proceed after showing icons for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_selectedAnswer == null) return;

    _userAnswers.add(_selectedAnswer!);

    if (_isLastQuestion) {
      _showResults();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    }
  }

  Future<void> _showResults() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update streak when quiz is completed
        final updatedStreak = await _streakService.updateUserStreak(user.uid);
        
        // Create and save quiz result
        final percentage = (_score / widget.questions.length) * 100;
        final quizResult = QuizResult(
          userId: user.uid,
          categoryName: widget.isAIMode ? widget.aiTopic ?? 'AI Quiz' : widget.category?.name ?? 'Quiz',
          categoryColor: widget.isAIMode ? 'FF6B73' : (widget.category?.color.toARGB32().toRadixString(16) ?? 'FF6B73'),
          totalQuestions: widget.questions.length,
          correctAnswers: _score,
          wrongAnswers: widget.questions.length - _score,
          totalScore: _score * 20, // 20 points per correct answer
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
                streakInfo: {
                  'currentStreak': updatedStreak.streakCount,
                  'isNewRecord': updatedStreak.streakCount == updatedStreak.maxStreak,
                  'pointsEarned': 25, // Base streak points
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to old result screen if there's an error
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              totalQuestions: widget.questions.length,
              correctAnswers: _score,
              questions: widget.questions,
              userAnswers: _userAnswers,
              category: widget.category,
              isTimerMode: false,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final correctAnswer =
        _currentQuestion.options[_currentQuestion.correctIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.isAIMode ? 'AI Quiz: ${widget.aiTopic}' : (widget.category?.name ?? 'Quiz')),
        backgroundColor: widget.isAIMode ? const Color(0xFF6B73FF) : (widget.category?.color ?? const Color(0xFF6B73FF)),
        foregroundColor: Colors.white,
        elevation: 0,
        // Removed score display from app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / widget.questions.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(widget.isAIMode ? const Color(0xFF6B73FF) : (widget.category?.color ?? const Color(0xFF6B73FF))),
            ),
            const SizedBox(height: 16),

            // Question counter
            Text(
              'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: widget.isAIMode ? const Color(0xFF6B73FF) : (widget.category?.color ?? const Color(0xFF6B73FF)),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Question card
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _currentQuestion.question,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Answer options with minimal feedback (only icons)
            Expanded(
              child: ListView.builder(
                itemCount: _currentQuestion.options.length,
                itemBuilder: (context, index) {
                  final option = _currentQuestion.options[index];
                  final isSelected = _selectedAnswer == option;
                  final isCorrectAnswer = option == correctAnswer;

                  // Determine colors and icons based on state
                  Color? backgroundColor;
                  Color? borderColor;
                  Color? textColor;
                  IconData? icon;

                  if (_hasAnswered) {
                    if (isCorrectAnswer) {
                      // Correct answer - always green with ✓
                      backgroundColor = Colors.green.withValues(alpha: 0.1);
                      borderColor = Colors.green;
                      textColor = Colors.green.shade700;
                      icon = Icons.check_circle;
                    } else if (isSelected) {
                      // Wrong selected answer - red with X
                      backgroundColor = Colors.red.withValues(alpha: 0.1);
                      borderColor = Colors.red;
                      textColor = Colors.red.shade700;
                      icon = Icons.cancel;
                    }
                  } else if (isSelected) {
                    // Selected but not answered yet
                    backgroundColor = (widget.isAIMode ? const Color(0xFF6B73FF) : (widget.category?.color ?? const Color(0xFF6B73FF))).withValues(alpha: 0.1);
                    borderColor = widget.isAIMode ? const Color(0xFF6B73FF) : (widget.category?.color ?? const Color(0xFF6B73FF));
                    textColor = widget.isAIMode ? const Color(0xFF6B73FF) : (widget.category?.color ?? const Color(0xFF6B73FF));
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 8 : 2,
                    child: InkWell(
                      onTap: _hasAnswered ? null : () => _selectAnswer(option),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ?? Colors.transparent,
                            width: 2,
                          ),
                          color: backgroundColor,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: borderColor ?? Colors.grey,
                                  width: 2,
                                ),
                                color:
                                    (isSelected ||
                                        (_hasAnswered && isCorrectAnswer))
                                    ? (borderColor ?? Colors.transparent)
                                    : Colors.transparent,
                              ),
                              child: icon != null
                                  ? Icon(icon, color: Colors.white, size: 16)
                                  : (isSelected && !_hasAnswered)
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      (isSelected ||
                                          (_hasAnswered && isCorrectAnswer))
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
