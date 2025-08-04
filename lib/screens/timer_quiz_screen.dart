// lib/screens/timer_quiz_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';

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
  int _currentIndex = 0;
  int _timeRemaining = 15;
  Timer? _timer;
  int _score = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timeRemaining = widget.timerSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _timeUp();
      }
    });
  }

  void _timeUp() {
    _timer?.cancel();
    if (!_isAnswered) {
      _showTimeUpDialog();
    }
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Time\'s Up!'),
          ],
        ),
        content: Text('The correct answer was: ${_getCorrectAnswer()}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String answer) {
    if (_isAnswered || _timeRemaining <= 0) return;

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;
    });

    _timer?.cancel();

    final isCorrect = answer == _getCorrectAnswer();
    if (isCorrect) {
      _score++;
    }

    _showAnswerDialog(isCorrect);
  }

  void _showAnswerDialog(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(isCorrect ? 'Correct!' : 'Wrong!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCorrect) Text('Correct answer: ${_getCorrectAnswer()}'),
            const SizedBox(height: 8),
            Text('Score: $_score/${_currentIndex + 1}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _nextQuestion();
            },
            child: Text(
              _currentIndex < widget.questions.length - 1 ? 'Next' : 'Finish',
            ),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
      _startTimer();
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Quiz Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Final Score: $_score/${widget.questions.length}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Percentage: ${((_score / widget.questions.length) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to home screen
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor() {
    final percentage = _timeRemaining / widget.timerSeconds;
    if (percentage > 0.6) return Colors.green;
    if (percentage > 0.3) return Colors.orange;
    return Colors.red;
  }

  // Helper methods to get question data
  // ── helper methods that read data from YOUR Question class ──
  String _getQuestionText() => widget.questions[_currentIndex].question;

  String _getCorrectAnswer() => widget
      .questions[_currentIndex]
      .options[widget.questions[_currentIndex].correctIndex];

  List<String> _getOptions() =>
      List<String>.from(widget.questions[_currentIndex].options);

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _timeRemaining / widget.timerSeconds;
    final timerColor = _getTimerColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Question ${_currentIndex + 1} of ${widget.questions.length}',
        ),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Circular Timer
            SizedBox(
              height: 140,
              width: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      valueColor: AlwaysStoppedAnimation(timerColor),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: timerColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: timerColor, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_timeRemaining',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: timerColor,
                            ),
                          ),
                          Text(
                            'sec',
                            style: TextStyle(
                              fontSize: 14,
                              color: timerColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Question
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getQuestionText(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Answer Options
            Expanded(
              child: ListView.builder(
                itemCount: _getOptions().length,
                itemBuilder: (context, index) {
                  final option = _getOptions()[index];
                  final isSelected = _selectedAnswer == option;
                  final isCorrect = option == _getCorrectAnswer();

                  Color cardColor = Colors.white;
                  Color borderColor = Colors.grey.shade300;

                  if (_isAnswered) {
                    if (isCorrect) {
                      cardColor = Colors.green.shade50;
                      borderColor = Colors.green;
                    } else if (isSelected && !isCorrect) {
                      cardColor = Colors.red.shade50;
                      borderColor = Colors.red;
                    }
                  } else if (isSelected) {
                    cardColor = const Color(0xFF1976D2).withValues(alpha: 0.1);
                    borderColor = const Color(0xFF1976D2);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: isSelected || _isAnswered ? 4 : 2,
                      color: cardColor,
                      child: InkWell(
                        onTap: () => _selectAnswer(option),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: borderColor,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(
                                      65 + index,
                                    ), // A, B, C, D
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_isAnswered && isCorrect)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              if (_isAnswered && isSelected && !isCorrect)
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Skip button
            if (!_isAnswered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _isAnswered = true;
                    });
                    _showAnswerDialog(false);
                  },
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
