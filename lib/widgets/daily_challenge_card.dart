import 'package:flutter/material.dart';
import '../models/daily_challenge.dart';
import '../models/user_challenge_progress.dart';

class DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final UserChallengeProgress? progress;
  final VoidCallback? onTap;
  final bool isCompleted;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    this.progress,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = progress?.progressPercentage ?? 0.0;
    final questionsRemaining =
        progress?.questionsRemaining ?? challenge.questionIds.length;
    final canAttempt = !isCompleted && !challenge.isExpired;

    return Card(
      elevation: 8,
      shadowColor: _getDifficultyColor().withOpacity(0.3),
      child: InkWell(
        onTap: canAttempt ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getDifficultyColor().withOpacity(0.1),
                _getDifficultyColor().withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Challenge Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getDifficultyColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getChallengeIcon(),
                  color: _getDifficultyColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Challenge Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Daily Challenge',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getDifficultyColor(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            challenge.difficultyText.toUpperCase(),
                            style: TextStyle(
                              color: _getDifficultyColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (progress != null && progressPercentage > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progressPercentage / 100,
                        backgroundColor: _getDifficultyColor().withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(_getDifficultyColor()),
                        minHeight: 4,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Time remaining and button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!challenge.isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.orange,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            challenge.timeRemainingText,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: canAttempt ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAttempt ? _getDifficultyColor() : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: canAttempt ? 2 : 0,
                      minimumSize: const Size(0, 32),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getButtonIcon(), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _getButtonText(),
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
            ],
          ),
        ),
      ),
    );
  }


  Color _getDifficultyColor() {
    switch (challenge.difficulty.toLowerCase()) {
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

  IconData _getChallengeIcon() {
    if (isCompleted) return Icons.check_circle;
    if (challenge.isExpired) return Icons.timer_off;

    switch (challenge.difficulty.toLowerCase()) {
      case 'easy':
        return Icons.emoji_emotions;
      case 'medium':
        return Icons.local_fire_department;
      case 'hard':
        return Icons.flash_on;
      default:
        return Icons.quiz;
    }
  }

  IconData _getButtonIcon() {
    if (isCompleted) return Icons.check_circle;
    if (challenge.isExpired) return Icons.timer_off;
    if (progress != null && progress!.questionsCompleted > 0) {
      return Icons.play_arrow;
    }
    return Icons.rocket_launch;
  }

  String _getButtonText() {
    if (isCompleted) return 'Done';
    if (challenge.isExpired) return 'Expired';
    if (progress != null && progress!.questionsCompleted > 0) {
      return 'Continue';
    }
    return 'Start';
  }
}
