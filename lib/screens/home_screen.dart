// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_category.dart';
import '../models/daily_challenge.dart';
import '../models/user_challenge_progress.dart';
import '../models/user_streak.dart';
import '../services/auth_service.dart';
import '../services/streak_service.dart';
import '../services/database_service.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../widgets/daily_challenge_card.dart';
import '../services/user_profile_service.dart';
import 'streak_screen.dart';
import 'ai_mode_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';
import 'timer_quiz_screen.dart';
import 'daily_challenge_screen.dart';

/* -------------------------------- USER DATA MODEL -------------------------------- */

class UserData {
  final String displayName;
  final String email;
  final int rank;
  final int score;
  final int coins;
  final int quizzesCompleted;

  UserData({
    required this.displayName,
    required this.email,
    required this.rank,
    required this.score,
    required this.coins,
    required this.quizzesCompleted,
  });
}

/* -------------------------------- HOME SCREEN -------------------------------- */

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  final AuthService _authService = AuthService();
  final StreakService _streakService = StreakService();
  bool _isSigningOut = false;
  late final List<Widget> _pages;
  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _pages = [
      const CategoryPage(),
      const ScoresPage(),
      const LeaderboardPage(),
    ];
    _loadDisplayName();
    
    // Listen for display name changes
    UserProfileService.displayNameNotifier.addListener(_onDisplayNameChanged);
  }

  @override
  void dispose() {
    UserProfileService.displayNameNotifier.removeListener(_onDisplayNameChanged);
    super.dispose();
  }

  Future<void> _loadDisplayName() async {
    final name = await UserProfileService.getDisplayName();
    if (mounted) {
      setState(() {
        _displayName = name;
      });
    }
  }

  void _onDisplayNameChanged() {
    _loadDisplayName();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  UserStreak? _cachedStreak;
  DateTime? _lastStreakFetch;

  Future<UserStreak?> _getStreakData() async {
    // Cache streak data for 30 seconds to reduce database calls
    if (_cachedStreak != null && _lastStreakFetch != null &&
        DateTime.now().difference(_lastStreakFetch!).inSeconds < 30) {
      return _cachedStreak;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _cachedStreak = await _streakService.getUserStreak(user.uid);
      _lastStreakFetch = DateTime.now();
      return _cachedStreak;
    }
    return null;
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error signing out: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Exit App?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Are you sure you want to exit the app?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'No',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text(
              'Yes',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showExitConfirmationDialog();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: user?.photoURL != null
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(user!.photoURL!),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle network errors silently
                  },
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
        title: Text(_displayName),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Streak icon with number
          FutureBuilder<UserStreak?>(
            future: _getStreakData(),
            builder: (context, snapshot) {
              final streakCount = snapshot.data?.streakCount ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.local_fire_department),
                    tooltip: 'Streak',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StreakScreen()),
                      );
                    },
                  ),
                  if (streakCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$streakCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey.shade600,
        elevation: 8,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Scores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
      ),
    ),
    );
  }
}

/* =============================================================================== */
/* =============================== CATEGORY PAGE ================================= */
/* =============================================================================== */

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with AutomaticKeepAliveClientMixin {
  late Future<UserData> _userDataFuture;
  final List<String> _modes = ['Category Mode', 'Quick Mode', 'AI Mode'];
  String _selectedMode = 'Category Mode';
  final StreakService _streakService = StreakService();
  
  UserStreak? _userStreak;
  DailyChallenge? _dailyChallenge;
  UserChallengeProgress? _challengeProgress;

  static const List<QuizCategory> _categories = [
    QuizCategory(
      name: 'Science',
      icon: Icons.science,
      color: Color(0xFF2196F3),
      description: 'Test your scientific knowledge',
    ),
    QuizCategory(
      name: 'History',
      icon: Icons.history_edu,
      color: Color(0xFFFF9800),
      description: 'Journey through time',
    ),
    QuizCategory(
      name: 'Sports',
      icon: Icons.sports_soccer,
      color: Color(0xFF4CAF50),
      description: 'Sports and athletics',
    ),
    QuizCategory(
      name: 'Geography',
      icon: Icons.public,
      color: Color(0xFF009688),
      description: 'Explore the world',
    ),
    QuizCategory(
      name: 'Technology',
      icon: Icons.computer,
      color: Color(0xFF00BCD4),
      description: 'Tech and innovation',
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
    _loadStreakAndChallengeData();
  }

  Future<UserData> _fetchUserData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');
    return UserData(
      displayName: currentUser.displayName ?? 'Quiz Master',
      email: currentUser.email ?? '',
      rank: 12,
      score: 5800,
      coins: 350,
      quizzesCompleted: 47,
    );
  }

  Future<void> _loadStreakAndChallengeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final streak = await _streakService.getUserStreak(user.uid);
        final challenge = await _streakService.getTodaysChallenge();
        UserChallengeProgress? progress;
        
        progress = await _streakService.getUserChallengeProgress(
          user.uid, 
          challenge.challengeId,
        );
              
        if (mounted) {
          setState(() {
            _userStreak = streak;
            _dailyChallenge = challenge;
            _challengeProgress = progress;
          });
        }
      } catch (e) {
        print('Error loading streak and challenge data: $e');
      }
    }
  }

  Future<void> _refreshUserData() async {
    setState(() => _userDataFuture = _fetchUserData());
    await _loadStreakAndChallengeData();
  }

  void _showStartQuizDialog(BuildContext context, QuizCategory category) {
    int chosenQuestionCount = 15;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(category.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.description),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Questions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: category.color),
                    ),
                    child: Text(
                      '$chosenQuestionCount Questions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: category.color,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: category.color,
                  inactiveTrackColor: category.color.withValues(alpha: 0.3),
                  thumbColor: category.color,
                  overlayColor: category.color.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12.0,
                    pressedElevation: 8.0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24.0,
                  ),
                  trackHeight: 6.0,
                  valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                  valueIndicatorColor: category.color,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: Slider(
                  value: chosenQuestionCount.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: '$chosenQuestionCount',
                  onChanged: (double value) {
                    setStateSB(() {
                      chosenQuestionCount = value.round();
                    });
                  },
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    '50',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Quiz features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Random questions'),
              const Text('• No time limit'),
              const Text('• Earn coins and points'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (mounted) {
                  await _startCategoryQuiz(
                    context,
                    category,
                    chosenQuestionCount,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: category.color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCategoryQuiz(
    BuildContext context,
    QuizCategory category,
    int questionCount,
  ) async {
    try {
      final allQuestions = await DatabaseService().getRandomQuestionsByCategory(
        category.name,
        limit: 100,
      );
      if (!mounted) return;
      if (allQuestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No questions available for this category.'),
            ),
          );
        }
        return;
      }

      allQuestions.shuffle();
      final selectedQuestions = allQuestions.take(questionCount).toList();
      if (selectedQuestions.length < questionCount) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only ${selectedQuestions.length} questions available for this category. Starting with available questions.',
              ),
            ),
          );
        }
      }

      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                QuizScreen(questions: selectedQuestions, category: category),
          ),
        );
        
        // Refresh streak data after completing quiz
        if (result != null) {
          await _loadStreakAndChallengeData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startQuickModeQuiz(
    BuildContext context,
    List<QuizCategory> selectedCategories,
    bool isRandom,
    int questionCount,
  ) async {
    try {
      final dbService = DatabaseService();
      final List<Question> allQuestions = [];

      if (isRandom) {
        for (final category in _categories) {
          final questions = await dbService.getRandomQuestionsByCategory(
            category.name,
            limit: 50,
          );
          allQuestions.addAll(questions);
        }
      } else {
        for (final category in selectedCategories) {
          final questions = await dbService.getRandomQuestionsByCategory(
            category.name,
            limit: 50,
          );
          allQuestions.addAll(questions);
        }
      }

      if (allQuestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No questions available.')),
          );
        }
        return;
      }

      allQuestions.shuffle();
      final quickQuestions = allQuestions.take(questionCount).toList();

      if (quickQuestions.length < questionCount) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Only ${quickQuestions.length} questions available. Starting with available questions.',
              ),
            ),
          );
        }
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TimerQuizScreen(questions: quickQuestions, timerSeconds: 15),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading quiz: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: _refreshUserData,
      color: const Color(0xFF1976D2),
      child: FutureBuilder<UserData>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF1976D2)),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Oops! Something went wrong',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refreshUserData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDailyChallengeSection(context),
                  const SizedBox(height: 32),
                  _buildModesSection(context),
                  if (_selectedMode == 'Category Mode') ...[
                    const SizedBox(height: 24),
                    _buildCategoriesSection(context),
                  ] else if (_selectedMode == 'Quick Mode') ...[
                    const SizedBox(height: 16),
                    _buildQuickModeOptions(context),
                  ] else if (_selectedMode == 'AI Mode') ...[
                    const SizedBox(height: 16),
                    _buildAIModeSection(context),
                  ],
                ],
              ),
            );
          } else {
            return const Center(child: Text('No user data found.'));
          }
        },
      ),
    );
  }


  Widget _buildModesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.gamepad, color: Color(0xFF1976D2), size: 28),
            const SizedBox(width: 8),
            Text(
              'Choose a Mode',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: _modes.map((mode) {
            final isSelected = mode == _selectedMode;
            return ChoiceChip(
              label: Text(mode),
              selected: isSelected,
              selectedColor: const Color(0xFF1976D2),
              onSelected: (_) => setState(() => _selectedMode = mode),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF1976D2)),
              elevation: isSelected ? 2 : 0,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const Icon(Icons.category, color: Color(0xFF1976D2), size: 28),
              const SizedBox(width: 8),
              Text(
                'Choose a Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(context, category);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, QuizCategory category) {
    return RepaintBoundary(
      child: Card(
        elevation: 6,
        shadowColor: category.color.withValues(alpha: 0.2),
        child: InkWell(
          onTap: () => _showStartQuizDialog(context, category),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  category.color.withValues(alpha: 0.1),
                  category.color.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, size: 32, color: category.color),
                ),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    category.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_fire_department, color: Color(0xFFFF6B35), size: 28),
            const SizedBox(width: 8),
            Text(
              'Your Streak',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDailyChallengeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFF1976D2), size: 28),
            const SizedBox(width: 8),
            Text(
              'Daily Challenge',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_dailyChallenge != null)
          DailyChallengeCard(
            challenge: _dailyChallenge!,
            progress: _challengeProgress,
            isCompleted: _challengeProgress?.isCompleted ?? false,
            onTap: () => _startDailyChallenge(context),
          )
        else
          Card(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Loading today\'s challenge...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _startDailyChallenge(BuildContext context) async {
    if (_dailyChallenge == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to start the challenge')),
        );
        return;
      }

      // Update streak when starting challenge
      await _streakService.updateUserStreak(user.uid);
      
      // Get challenge questions
      final questions = await _streakService.getChallengeQuestions(_dailyChallenge!);
      
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyChallengeScreen(
              challenge: _dailyChallenge!,
              questions: questions,
            ),
          ),
        );
        
        // Refresh data after completing challenge
        if (result != null) {
          await _loadStreakAndChallengeData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildQuickModeOptions(BuildContext context) {
    return _QuickModeOptions(
      categories: _categories,
      onStartQuiz: (selectedCategories, isRandom, questionCount) async {
        await _startQuickModeQuiz(
          context,
          selectedCategories,
          isRandom,
          questionCount,
        );
      },
    );
  }

  Widget _buildAIModeSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B73FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Color(0xFF6B73FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Quiz',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6B73FF),
                        ),
                      ),
                      Text(
                        'Generate custom questions on any topic',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B73FF).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6B73FF).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, 
                        color: Color(0xFF6B73FF), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Features:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('10 AI-generated questions'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('Custom topics of your choice'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text('Powered by Google Gemini AI'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.psychology),
                label: const Text('Start AI Quiz'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIModeScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =============================================================================== */
/* ============================== SCORES PAGE =================================== */
/* =============================================================================== */

class ScoresPage extends StatefulWidget {
  const ScoresPage({super.key});

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage>
    with AutomaticKeepAliveClientMixin {
  late Future<List<QuizResult>> _quizResultsFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final dbService = DatabaseService();
      _quizResultsFuture = dbService.getUserQuizResults(user.uid);
      _statsFuture = dbService.getUserStats(user.uid);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view your scores'));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF1976D2),
      child: CustomScrollView(
        slivers: [
          // Stats Overview Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildStatsOverview(context, snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          // Quiz Results Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF1976D2), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Quiz Results',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Quiz Results List
          FutureBuilder<List<QuizResult>>(
            future: _quizResultsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1976D2)),
                        SizedBox(height: 16),
                        Text('Loading your quiz history...'),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Error loading scores',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(24),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Quiz Results Yet',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Take your first quiz to see results here!',
                              style: TextStyle(color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate back to home tab
                                final homeScreenState = context
                                    .findAncestorStateOfType<
                                      _HomeScreenState
                                    >();
                                homeScreenState?._onItemTapped(0);
                              },
                              icon: const Icon(Icons.quiz),
                              label: const Text('Take a Quiz'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              final results = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index < results.length) {
                      return _buildQuizResultCard(context, results[index]);
                    }
                    return null;
                  }, childCount: results.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Color(0xFF1976D2), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Overall Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.quiz,
                  '${stats['totalQuizzes'] ?? 0}',
                  'Total Quizzes',
                  const Color(0xFF1976D2),
                ),
                _buildStatItem(
                  context,
                  Icons.percent,
                  '${(stats['averagePercentage'] ?? 0.0).toStringAsFixed(1)}%',
                  'Average Score',
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  Icons.star,
                  '${stats['bestScore'] ?? 0}',
                  'Best Score',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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

  Widget _buildQuizResultCard(BuildContext context, QuizResult result) {
    final categoryColor = result.categoryColor != null
        ? Color(int.parse('0xFF${result.categoryColor}'))
        : const Color(0xFF1976D2);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () => _showResultDetails(context, result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      result.isTimerMode ? Icons.timer : Icons.category,
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.categoryName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                        ),
                        Text(
                          _formatDate(result.completedAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  // Score Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(
                        result.percentage,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getScoreColor(result.percentage),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${result.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(result.percentage),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultStat(
                    context,
                    Icons.quiz,
                    '${result.totalQuestions}',
                    'Questions',
                  ),
                  _buildResultStat(
                    context,
                    Icons.check_circle,
                    '${result.correctAnswers}',
                    'Correct',
                  ),
                  _buildResultStat(
                    context,
                    Icons.cancel,
                    '${result.wrongAnswers}',
                    'Wrong',
                  ),
                  _buildResultStat(
                    context,
                    Icons.star,
                    '${result.totalScore}',
                    'Points',
                  ),
                ],
              ),
              if (result.isTimerMode) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Quick Mode',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _showResultDetails(BuildContext context, QuizResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildDetailedResult(context, result),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedResult(BuildContext context, QuizResult result) {
    final categoryColor = result.categoryColor != null
        ? Color(int.parse('0xFF${result.categoryColor}'))
        : const Color(0xFF1976D2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Quiz Result Details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: categoryColor,
          ),
        ),
        const SizedBox(height: 20),
        // Category Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.categoryName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed on ${_formatDate(result.completedAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
              if (result.isTimerMode) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Quick Mode - 15 seconds per question',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Performance Summary
        Row(
          children: [
            Expanded(
              child: _buildDetailStat(
                context,
                Icons.quiz,
                '${result.totalQuestions}',
                'Total Questions',
                categoryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailStat(
                context,
                Icons.check_circle,
                '${result.correctAnswers}',
                'Correct Answers',
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailStat(
                context,
                Icons.cancel,
                '${result.wrongAnswers}',
                'Wrong Answers',
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailStat(
                context,
                Icons.star,
                '${result.totalScore}',
                'Total Score',
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Percentage and Grade
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getScoreColor(result.percentage).withValues(alpha: 0.1),
                _getScoreColor(result.percentage).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getScoreColor(result.percentage).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                '${result.percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(result.percentage),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Grade: ${result.grade}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(result.percentage),
                ),
              ),
              Text(
                result.performance,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Action Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to home and take the same type of quiz again
              final homeScreenState = context
                  .findAncestorStateOfType<_HomeScreenState>();
              homeScreenState?._onItemTapped(0);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Take Similar Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
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
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/* =============================================================================== */
/* ============================== LEADERBOARD PAGE ============================== */
/* =============================================================================== */

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.leaderboard, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Leaderboard',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compete with other players',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
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
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =============================================================================== */
/* ========================== QUICK MODE OPTIONS WIDGET ========================== */
/* =============================================================================== */

class _QuickModeOptions extends StatefulWidget {
  final List<QuizCategory> categories;
  final void Function(
    List<QuizCategory> selected,
    bool isRandom,
    int questionCount,
  )
  onStartQuiz;

  const _QuickModeOptions({
    required this.categories,
    required this.onStartQuiz,
  });

  @override
  State<_QuickModeOptions> createState() => _QuickModeOptionsState();
}

class _QuickModeOptionsState extends State<_QuickModeOptions> {
  bool _isRandom = true;
  int _questionCount = 15;
  final Set<int> _selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      Text(
                        'Fast-paced quiz with timer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Timer info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.orange.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timer Challenge',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '15 seconds per question',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Question Count Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Questions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1976D2),
                              const Color(0xFF1976D2).withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$_questionCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF1976D2),
                      inactiveTrackColor: Colors.grey.shade300,
                      thumbColor: const Color(0xFF1976D2),
                      overlayColor: const Color(0xFF1976D2).withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 14.0,
                        pressedElevation: 8.0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 28.0,
                      ),
                      trackHeight: 8.0,
                      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                      valueIndicatorColor: const Color(0xFF1976D2),
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      showValueIndicator: ShowValueIndicator.always,
                    ),
                    child: Slider(
                      value: _questionCount.toDouble(),
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '$_questionCount',
                      onChanged: (double value) {
                        setState(() {
                          _questionCount = value.round();
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 Question',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '50 Questions',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Category Selection Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Selection',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRandom = true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: _isRandom
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF1976D2),
                                        const Color(0xFF1976D2).withValues(alpha: 0.8),
                                      ],
                                    )
                                  : null,
                              color: _isRandom ? null : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isRandom
                                    ? const Color(0xFF1976D2)
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: _isRandom
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shuffle,
                                  color: _isRandom ? Colors.white : Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Random',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isRandom ? Colors.white : Colors.grey.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isRandom = false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: !_isRandom
                                  ? LinearGradient(
                                      colors: [
                                        const Color(0xFF1976D2),
                                        const Color(0xFF1976D2).withValues(alpha: 0.8),
                                      ],
                                    )
                                  : null,
                              color: !_isRandom ? null : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !_isRandom
                                    ? const Color(0xFF1976D2)
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: !_isRandom
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.category,
                                  color: !_isRandom ? Colors.white : Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Choose',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !_isRandom ? Colors.white : Colors.grey.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Category selection chips
                  if (!_isRandom) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Select Categories:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: List.generate(widget.categories.length, (i) {
                        final cat = widget.categories[i];
                        final selected = _selectedIndexes.contains(i);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                _selectedIndexes.remove(i);
                              } else {
                                _selectedIndexes.add(i);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [
                                        cat.color.withValues(alpha: 0.8),
                                        cat.color,
                                      ],
                                    )
                                  : null,
                              color: selected ? null : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: selected ? cat.color : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: cat.color.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  color: selected ? Colors.white : cat.color,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: selected ? Colors.white : cat.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (selected) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // Start Quiz button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 24),
                label: Text(
                  'Start Quick Quiz ($_questionCount Questions)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _isRandom || _selectedIndexes.isNotEmpty
                    ? () {
                        final selected = _isRandom
                            ? List<QuizCategory>.from(widget.categories)
                            : _selectedIndexes
                                  .map((i) => widget.categories[i])
                                  .toList();
                        widget.onStartQuiz(selected, _isRandom, _questionCount);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
