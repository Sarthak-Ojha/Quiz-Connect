// lib/screens/timer_quiz_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import 'quiz_result_screen.dart';

class TimerQuizScreen extends StatefulWidget {
  final List<Question> questions;
  final int timerSeconds;

  const TimerQuizScreen({
    super.key,
    required this.questions,
    this.timerSeconds = 15,
  });

  @override
  State<TimerQuizScreen> createState() => _TimerQuizScreenState();
}

class _TimerQuizScreenState extends State<TimerQuizScreen>
    with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  final List<String> _userAnswers = [];
  String? _selectedAnswer;
  bool _hasAnswered = false;
  int _score = 0;
  late Timer _timer;
  int _remainingTime = 0;
  late AnimationController _animationController;

  // Power-ups - each can only be used once per game
  bool _fiftyFiftyUsed = false;
  bool _skipUsed = false;
  bool _extraTimeUsed = false;
  List<int> _hiddenOptions = []; // For 50-50 power-up

  Question get _currentQuestion => widget.questions[_currentQuestionIndex];
  bool get _isLastQuestion =>
      _currentQuestionIndex == widget.questions.length - 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: widget.timerSeconds),
      vsync: this,
    );
    _startTimer();
  }

  void _startTimer() {
    _remainingTime = widget.timerSeconds;
    _animationController.reset();
    _animationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0 && !_hasAnswered) {
        setState(() {
          _remainingTime--;
        });
      } else if (_remainingTime <= 0 && !_hasAnswered) {
        _timeUp();
      }
    });
  }

  void _timeUp() {
    _timer.cancel();
    _animationController.stop();
    setState(() {
      _hasAnswered = true;
      _selectedAnswer = ''; // Empty for no answer
    });

    // Auto proceed after showing icons for 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      _proceedToNext();
    });
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;

    _timer.cancel();
    _animationController.stop();
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
      _proceedToNext();
    });
  }

  void _proceedToNext() {
    _userAnswers.add(_selectedAnswer ?? '');

    if (_isLastQuestion) {
      _showResults();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
        _hiddenOptions.clear(); // Reset hidden options for next question
      });
      _startTimer();
    }
  }

  void _showResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          totalQuestions: widget.questions.length,
          correctAnswers: _score,
          questions: widget.questions,
          userAnswers: _userAnswers,
          category: null,
          isTimerMode: true,
        ),
      ),
    );
  }

  Color _getTimerColor() {
    if (_remainingTime <= 3) {
      return Colors.red;
    } else if (_remainingTime <= 7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _useFiftyFifty() {
    if (_fiftyFiftyUsed || _hasAnswered) return;

    setState(() {
      _fiftyFiftyUsed = true;

      // Find two wrong answers to hide
      List<int> wrongIndices = [];
      for (int i = 0; i < _currentQuestion.options.length; i++) {
        if (i != _currentQuestion.correctIndex) {
          wrongIndices.add(i);
        }
      }

      // Randomly select 2 wrong answers to hide
      wrongIndices.shuffle();
      _hiddenOptions = wrongIndices.take(2).toList();
    });
  }

  void _useSkip() {
    if (_skipUsed || _hasAnswered) return;

    setState(() {
      _skipUsed = true;
      _hasAnswered = true;
      _selectedAnswer = ''; // Empty for skipped
    });

    _timer.cancel();
    _animationController.stop();

    // Auto proceed after brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      _proceedToNext();
    });
  }

  void _useExtraTime() {
    if (_extraTimeUsed || _hasAnswered) return;

    setState(() {
      _extraTimeUsed = true;
      _remainingTime += 10; // Add 10 seconds
    });
  }

  Widget _buildPowerUpButton({
    required IconData icon,
    required String label,
    required bool isUsed,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUsed ? Colors.grey.shade300 : color.withValues(alpha: 0.1),
          border: Border.all(color: isUsed ? Colors.grey : color, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isUsed ? Colors.grey : color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isUsed ? Colors.grey : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final correctAnswer =
        _currentQuestion.options[_currentQuestion.correctIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Quick Mode'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress and Enhanced Circular Timer Row
            Row(
              children: [
                // Progress indicator
                Expanded(
                  child: LinearProgressIndicator(
                    value:
                        (_currentQuestionIndex + 1) / widget.questions.length,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Enhanced Circular Timer with Color Indication
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey.shade300,
                        ),
                      ),
                    ),
                    // Animated progress circle
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: 1.0 - _animationController.value,
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getTimerColor(),
                            ),
                          );
                        },
                      ),
                    ),
                    // Timer text with colored background
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getTimerColor(),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getTimerColor().withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_remainingTime',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question counter
            Text(
              'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.orange,
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
                  final isHidden = _hiddenOptions.contains(index);

                  // Don't show hidden options (for 50-50)
                  if (isHidden) {
                    return const SizedBox.shrink();
                  }

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
                    backgroundColor = Colors.orange.withValues(alpha: 0.1);
                    borderColor = Colors.orange;
                    textColor = Colors.orange;
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

            // Power-ups row at bottom
            if (!_hasAnswered) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 50-50 Power-up
                    _buildPowerUpButton(
                      icon: Icons.filter_2,
                      label: '50-50',
                      isUsed: _fiftyFiftyUsed,
                      onTap: _fiftyFiftyUsed ? null : _useFiftyFifty,
                      color: Colors.blue,
                    ),
                    // Skip Power-up
                    _buildPowerUpButton(
                      icon: Icons.skip_next_rounded,
                      label: 'Skip',
                      isUsed: _skipUsed,
                      onTap: _skipUsed ? null : _useSkip,
                      color: Colors.purple,
                    ),
                    // Extra Time Power-up
                    _buildPowerUpButton(
                      icon: Icons.timer_10,
                      label: '+10s',
                      isUsed: _extraTimeUsed,
                      onTap: _extraTimeUsed ? null : _useExtraTime,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16)
          ],
        ),
      ),
    );
  }
}
