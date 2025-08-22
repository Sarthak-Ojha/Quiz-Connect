// lib/screens/quiz_result_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../models/quiz_category.dart';
import '../models/quiz_result.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final int? totalQuestions;
  final int? correctAnswers;
  final List<Question> questions;
  final List<String>? userAnswers;
  final QuizCategory? category;
  final bool? isTimerMode;
  final int timerSeconds;
  final QuizResult? result;
  final bool isChallenge;
  final Map<String, dynamic>? streakInfo;

  const QuizResultScreen({
    super.key,
    this.totalQuestions,
    this.correctAnswers,
    required this.questions,
    this.userAnswers,
    this.category,
    this.isTimerMode,
    this.timerSeconds = 0,
    this.result,
    this.isChallenge = false,
    this.streakInfo,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _isSaving = false;
  bool _resultSaved = false;

  int get wrongAnswers => (widget.result?.wrongAnswers ?? 
      (widget.totalQuestions! - widget.correctAnswers!));
  double get percentage => widget.result?.percentage ?? 
      ((widget.correctAnswers! / widget.totalQuestions!) * 100);
  int get totalScore => widget.result?.totalScore ?? 
      (widget.correctAnswers! * 10); // 10 points per correct answer
  int get totalQuestions => widget.result?.totalQuestions ?? widget.totalQuestions!;
  int get correctAnswers => widget.result?.correctAnswers ?? widget.correctAnswers!;
  List<String> get userAnswers => widget.result?.userAnswers ?? widget.userAnswers!;
  bool get isTimerMode => widget.result?.isTimerMode ?? widget.isTimerMode!;

  @override
  void initState() {
    super.initState();
    _saveQuizResult();
  }

  Future<void> _saveQuizResult() async {
    if (_resultSaved || widget.result != null) return; // Skip if result already provided

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final quizResult = QuizResult(
          userId: user.uid,
          categoryName: isTimerMode
              ? 'Quick Mode'
              : (widget.category?.name ?? 'Unknown'),
          categoryColor: widget.category?.color.value.toRadixString(16),
          totalQuestions: totalQuestions,
          correctAnswers: correctAnswers,
          wrongAnswers: wrongAnswers,
          totalScore: totalScore,
          percentage: percentage,
          isTimerMode: isTimerMode,
          timerSeconds: widget.timerSeconds,
          completedAt: DateTime.now(),
          userAnswers: userAnswers,
          questions: widget.questions.map((q) => q.question).toList(),
        );

        await DatabaseService().saveQuizResult(quizResult);
        setState(() => _resultSaved = true);
      }
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const buttonColor = Color(0xFF1976D2);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Save Status Indicator
                      if (_isSaving)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Saving result...',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else if (_resultSaved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Result saved!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        isTimerMode
                            ? 'Quick Mode Results'
                            : '${widget.category?.name} Results',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: buttonColor,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Circular Progress Indicator
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          children: [
                            // Background circle
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: 1.0,
                                strokeWidth: 12,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.grey.shade200,
                                ),
                              ),
                            ),
                            // Progress circle
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: percentage / 100,
                                strokeWidth: 12,
                                valueColor: const AlwaysStoppedAnimation(
                                  buttonColor,
                                ),
                              ),
                            ),
                            // Center content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$totalScore pt',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: buttonColor,
                                        ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            context,
                            'Total Questions',
                            widget.totalQuestions.toString(),
                            Icons.quiz,
                            buttonColor,
                          ),
                          _buildStatItem(
                            context,
                            'Correct',
                            widget.correctAnswers.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildStatItem(
                            context,
                            'Wrong',
                            wrongAnswers.toString(),
                            Icons.cancel,
                            Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons in 2x2 Grid Layout
                      Column(
                        children: [
                          // Row 1: Play Again | Review Answer
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Play Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showReviewAnswers(context);
                                  },
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Review Answer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Row 2: Home | My Scores
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  icon: const Icon(Icons.home),
                                  label: const Text('Home'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to My Scores tab with initialTabIndex: 1
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const HomeScreen(
                                          initialTabIndex: 1,
                                        ),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                  icon: const Icon(Icons.history),
                                  label: const Text('My Scores'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showReviewAnswers(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewAnswersScreen(
          questions: widget.questions,
          userAnswers: userAnswers,
          category: widget.category,
        ),
      ),
    );
  }
}

// Review Answers Screen
class ReviewAnswersScreen extends StatelessWidget {
  final List<Question> questions;
  final List<String> userAnswers;
  final QuizCategory? category;

  const ReviewAnswersScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Answers'),
        backgroundColor: category?.color ?? Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final userAnswer = index < userAnswers.length
              ? userAnswers[index]
              : '';
          final correctAnswer = question.options[question.correctIndex];
          final isCorrect = userAnswer == correctAnswer;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: category?.color ?? Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.question,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Show all options with indicators
                  ...question.options.map((option) {
                    final isUserAnswer = option == userAnswer;
                    final isCorrectAnswer = option == correctAnswer;

                    Color? backgroundColor;
                    Color? textColor;
                    IconData? icon;

                    if (isCorrectAnswer) {
                      backgroundColor = Colors.green.withOpacity(0.1);
                      textColor = Colors.green.shade700;
                      icon = Icons.check_circle;
                    } else if (isUserAnswer && !isCorrect) {
                      backgroundColor = Colors.red.withOpacity(0.1);
                      textColor = Colors.red.shade700;
                      icon = Icons.cancel;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: backgroundColor != null
                              ? (isCorrectAnswer ? Colors.green : Colors.red)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (icon != null)
                            Icon(icon, color: textColor, size: 20),
                          if (icon != null) const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: backgroundColor != null
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  if (userAnswer.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.help, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'No answer selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
