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

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  bool _isSaving = false;
  bool _resultSaved = false;
  late AnimationController _animationController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

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
    _initAnimations();
    _saveQuizResult();
    _startAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: percentage / 100).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
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

  String get _performanceMessage {
    if (percentage >= 90) return 'Outstanding! 🏆';
    if (percentage >= 80) return 'Excellent! 🌟';
    if (percentage >= 70) return 'Great Job! 👏';
    if (percentage >= 60) return 'Good Work! 👍';
    if (percentage >= 50) return 'Keep Trying! 💪';
    return 'Practice More! 📚';
  }

  Color get _performanceColor {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Header Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _performanceColor.withOpacity(0.1),
                                _performanceColor.withOpacity(0.05),
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              // Performance Icon
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _performanceColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  percentage >= 80 ? Icons.emoji_events :
                                  percentage >= 60 ? Icons.thumb_up :
                                  Icons.trending_up,
                                  size: 40,
                                  color: _performanceColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Performance Message
                              Text(
                                _performanceMessage,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _performanceColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              
                              // Category Name
                              Text(
                                isTimerMode
                                    ? 'Quick Mode Results'
                                    : '${widget.category?.name ?? 'Quiz'} Results',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Score Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Animated Progress Circle
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return SizedBox(
                                    width: 180,
                                    height: 180,
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
                                            value: _progressAnimation.value,
                                            strokeWidth: 12,
                                            valueColor: AlwaysStoppedAnimation(
                                              _performanceColor,
                                            ),
                                          ),
                                        ),
                                        // Center content
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '$totalScore',
                                                style: TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                  color: _performanceColor,
                                                ),
                                              ),
                                              Text(
                                                'POINTS',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[600],
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${percentage.toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),
                              
                              // Stats Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildModernStatItem(
                                    'Total',
                                    totalQuestions.toString(),
                                    Icons.quiz_outlined,
                                    const Color(0xFF1976D2),
                                  ),
                                  _buildModernStatItem(
                                    'Correct',
                                    correctAnswers.toString(),
                                    Icons.check_circle_outline,
                                    Colors.green,
                                  ),
                                  _buildModernStatItem(
                                    'Wrong',
                                    wrongAnswers.toString(),
                                    Icons.cancel_outlined,
                                    Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Primary Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernButton(
                                      'Play Again',
                                      Icons.refresh_rounded,
                                      const Color(0xFF1976D2),
                                      () => Navigator.of(context).popUntil((route) => route.isFirst),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildModernButton(
                                      'Review',
                                      Icons.visibility_outlined,
                                      Colors.orange,
                                      () => _showReviewAnswers(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Secondary Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildModernButton(
                                      'Home',
                                      Icons.home_outlined,
                                      Colors.green,
                                      () => Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                                        (route) => false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildModernButton(
                                      'My Scores',
                                      Icons.analytics_outlined,
                                      Colors.purple,
                                      () => Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                          builder: (context) => const HomeScreen(initialTabIndex: 1),
                                        ),
                                        (route) => false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Save Status
                      if (_isSaving || _resultSaved)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _resultSaved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _resultSaved ? Colors.green : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _isSaving ? 'Saving result...' : 'Result saved!',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _resultSaved ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildModernStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
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
