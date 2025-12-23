// lib/screens/streak_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/streak_service.dart';
import '../models/user_streak.dart';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  final StreakService _streakService = StreakService();
  UserStreak? _userStreak;
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  Map<int, bool> _streakDays = {};

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  Future<void> _loadStreakData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final streak = await _streakService.getUserStreak(user.uid);
        final streakDays = await _streakService.getStreakCalendarData(user.uid, _selectedMonth);
        
        setState(() {
          _userStreak = streak;
          _streakDays = streakDays;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint('Error loading streak data: $e');
      }
    }
  }

  void _changeMonth(int direction) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + direction,
        1,
      );
    });
    _loadStreakData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Streak'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share streak functionality
              _shareStreak();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStreakHeader(),
                  const SizedBox(height: 24),
                  _buildAchievementBadges(),
                  const SizedBox(height: 32),
                  _buildStreakCalendar(),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakHeader() {
    final currentStreak = _userStreak?.streakCount ?? 0;
    final maxStreak = _userStreak?.maxStreak ?? 0;
    final isNewRecord = currentStreak == maxStreak && currentStreak > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1976D2).withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentStreak',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                  height: 0.9,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Streak Days',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isNewRecord
                ? "This is the longest Streak you've ever had!"
                : maxStreak > currentStreak
                    ? "Your best streak was $maxStreak days"
                    : "Keep it up! You're doing great!",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadges() {
    final currentStreak = _userStreak?.streakCount ?? 0;
    
    final achievements = [
      {'days': 7, 'icon': Icons.emoji_emotions, 'color': Colors.green, 'name': 'Week Warrior'},
      {'days': 14, 'icon': Icons.star, 'color': Colors.blue, 'name': 'Two Week Champion'},
      {'days': 30, 'icon': Icons.military_tech, 'color': Colors.purple, 'name': 'Month Master'},
      {'days': 100, 'icon': Icons.diamond, 'color': Colors.amber, 'name': 'Century Club'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: achievements.map((achievement) {
            final days = achievement['days'] as int;
            final isUnlocked = currentStreak >= days || (_userStreak?.maxStreak ?? 0) >= days;
            final color = achievement['color'] as Color;
            final icon = achievement['icon'] as IconData;

            return Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isUnlocked ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked ? color : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isUnlocked ? color : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$days',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? color : Colors.grey,
                  ),
                ),
                Text(
                  'days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStreakCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Streak Calendar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildCalendarHeader(),
              const SizedBox(height: 20),
              _buildCalendarGrid(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          monthNames[_selectedMonth.month - 1],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;
    
    final dayNames = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    
    return Column(
      children: [
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: dayNames.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 12),
        // Calendar grid
        ...List.generate((daysInMonth + firstDayOfWeek - 1) ~/ 7 + 1, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstDayOfWeek + 2;
                
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 40));
                }
                
                final hasStreak = _streakDays[dayNumber] ?? false;
                final isToday = dayNumber == DateTime.now().day &&
                    _selectedMonth.month == DateTime.now().month &&
                    _selectedMonth.year == DateTime.now().year;
                
                return Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hasStreak
                          ? Colors.orange
                          : isToday
                              ? const Color(0xFF1976D2).withOpacity(0.2)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: const Color(0xFF1976D2), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasStreak
                              ? Colors.white
                              : isToday
                                  ? const Color(0xFF1976D2)
                                  : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  void _shareStreak() {
    final currentStreak = _userStreak?.streakCount ?? 0;
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔥 I have a $currentStreak day streak on Quiz Connect!'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
