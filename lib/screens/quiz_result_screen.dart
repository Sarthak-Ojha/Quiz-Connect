// lib/screens/quiz_result_screen.dart

import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/quiz_category.dart';
import 'home_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final List<Question> questions;
  final List<String> userAnswers;
  final QuizCategory? category;
  final bool isTimerMode;

  const QuizResultScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.questions,
    required this.userAnswers,
    this.category,
    required this.isTimerMode,
  });

  int get wrongAnswers => totalQuestions - correctAnswers;
  double get percentage => (correctAnswers / totalQuestions) * 100;
  int get totalScore => correctAnswers * 10; // 10 points per correct answer

  @override
  Widget build(BuildContext context) {
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
                      // Title
                      Text(
                        isTimerMode
                            ? 'Quick Mode Results'
                            : '${category?.name} Results',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1976D2),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey.shade200,
                                ),
                              ),
                            ),
                            // Progress circle
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: percentage / 100,
                                strokeWidth: 12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1976D2),
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
                                          color: const Color(0xFF1976D2),
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
                            totalQuestions.toString(),
                            Icons.quiz,
                            const Color(0xFF1976D2),
                          ),
                          _buildStatItem(
                            context,
                            'Correct',
                            correctAnswers.toString(),
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

                      // Action Buttons
                      Column(
                        children: [
                          // Row 1
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Play Again functionality
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Play Again'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1976D2),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
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
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Row 2
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _shareScore();
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share Score'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _generatePDF();
                                  },
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text('Generate PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Row 3
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
                                    backgroundColor: Colors.grey.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showLeaderboard(context);
                                  },
                                  icon: const Icon(Icons.leaderboard),
                                  label: const Text('Leaderboard'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
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
          questions: questions,
          userAnswers: userAnswers,
          category: category,
        ),
      ),
    );
  }

  void _shareScore() {
    // TODO: Implement share functionality
    // You can use packages like share_plus for sharing
  }

  void _generatePDF() {
    // TODO: Implement PDF generation
    // You can use packages like pdf for generating PDFs
  }

  void _showLeaderboard(BuildContext context) {
    // TODO: Implement leaderboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('Leaderboard feature coming soon!'),
          ],
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
                      backgroundColor = Colors.green.withValues(alpha: 0.1);
                      textColor = Colors.green.shade700;
                      icon = Icons.check_circle;
                    } else if (isUserAnswer && !isCorrect) {
                      backgroundColor = Colors.red.withValues(alpha: 0.1);
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
                        color: Colors.grey.withValues(alpha: 0.1),
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
