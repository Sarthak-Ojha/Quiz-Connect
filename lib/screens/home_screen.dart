// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/quiz_category.dart';
import '../models/question.dart';
import 'quiz_screen.dart';
import 'timer_quiz_screen.dart';

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
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const CategoryPage(),
      const ScoresPage(),
      const LeaderboardPage(),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Quiz Master'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (user?.photoURL != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(user!.photoURL!),
              ),
            ),
          _isSigningOut
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Sign Out',
                  onPressed: _signOut,
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
  final List<String> _modes = ['Category Mode', 'Quick Mode'];
  String _selectedMode = 'Category Mode';

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
    QuizCategory(
      name: 'Current Affairs',
      icon: Icons.newspaper,
      color: Color(0xFF9C27B0),
      description: 'Stay updated with the latest events',
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<UserData> _fetchUserData() async {
    await Future.delayed(const Duration(milliseconds: 1000));
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

  Future<void> _refreshUserData() async =>
      setState(() => _userDataFuture = _fetchUserData());

  void _showStartQuizDialog(BuildContext context, QuizCategory category) {
    int chosenQuestionCount = 15; // Default value

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

              // Question Count Slider
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

  // Fixed method to get exact question count
  Future<void> _startCategoryQuiz(
    BuildContext context,
    QuizCategory category,
    int questionCount,
  ) async {
    try {
      // Get ALL available questions for the category first
      final allQuestions = await DatabaseService().getRandomQuestionsByCategory(
        category.name,
        limit: 100, // Get more questions than needed
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

      // Shuffle and take only the requested number
      allQuestions.shuffle();
      final selectedQuestions = allQuestions.take(questionCount).toList();

      // Check if we have enough questions
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                QuizScreen(questions: selectedQuestions, category: category),
          ),
        );
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

  // Fixed method to get exact question count for quick mode
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
        // Get questions from ALL categories
        for (final category in _categories) {
          final questions = await dbService.getRandomQuestionsByCategory(
            category.name,
            limit: 50, // Get more questions per category
          );
          allQuestions.addAll(questions);
        }
      } else {
        // Get questions from selected categories
        for (final category in selectedCategories) {
          final questions = await dbService.getRandomQuestionsByCategory(
            category.name,
            limit: 50, // Get more questions per category
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

      // Shuffle all questions and take only the requested number
      allQuestions.shuffle();
      final quickQuestions = allQuestions.take(questionCount).toList();

      // Check if we have enough questions
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

      // Quick Mode always goes to TimerQuizScreen with 15 seconds
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
                  Text('Loading your profile...'),
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
            final userData = snapshot.data!;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(context, userData),
                  const SizedBox(height: 20),
                  UserStatsCard(userData: userData),
                  const SizedBox(height: 32),
                  _buildModesSection(context),
                  if (_selectedMode == 'Category Mode') ...[
                    const SizedBox(height: 24),
                    _buildCategoriesSection(context),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildQuickModeOptions(context),
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
    return Card(
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
    );
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

  Widget _buildWelcomeSection(BuildContext context, UserData userData) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              userData.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready for another challenge?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
            ),
          ],
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
  int _questionCount = 15; // Default to 15 instead of 10
  final Set<int> _selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Mode Settings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Smaller timer info design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Timer: 15s per question',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Enhanced Slider for Question Count Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Number of Questions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1976D2)),
                      ),
                      child: Text(
                        '$_questionCount Questions',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Enhanced Slider with Custom Styling
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF1976D2),
                    inactiveTrackColor: const Color(
                      0xFF1976D2,
                    ).withValues(alpha: 0.3),
                    thumbColor: const Color(0xFF1976D2),
                    overlayColor: const Color(
                      0xFF1976D2,
                    ).withValues(alpha: 0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12.0,
                      pressedElevation: 8.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 24.0,
                    ),
                    trackHeight: 6.0,
                    valueIndicatorShape:
                        const PaddleSliderValueIndicatorShape(),
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

                // Min-Max Labels
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '50',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Random/Choose Categories buttons
            Row(
              children: [
                Expanded(
                  child: ToggleButtons(
                    isSelected: [_isRandom, !_isRandom],
                    borderRadius: BorderRadius.circular(8),
                    onPressed: (idx) {
                      setState(() => _isRandom = idx == 0);
                    },
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF1976D2),
                    borderColor: const Color(0xFF1976D2),
                    color: const Color(0xFF1976D2),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Random",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "Choose Categories",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Category selection chips (only show if not random)
            if (!_isRandom) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(widget.categories.length, (i) {
                  final cat = widget.categories[i];
                  final selected = _selectedIndexes.contains(i);
                  return FilterChip(
                    label: Text(cat.name),
                    selected: selected,
                    selectedColor: cat.color.withValues(alpha: 0.2),
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedIndexes.remove(i);
                        } else {
                          _selectedIndexes.add(i);
                        }
                      });
                    },
                    avatar: Icon(
                      cat.icon,
                      color: selected ? cat.color : Colors.grey,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? cat.color : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: Colors.grey.shade100,
                    checkmarkColor: cat.color,
                  );
                }),
              ),
            ],

            const SizedBox(height: 20),

            // Start Quiz button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.timer),
                label: Text(
                  'Start Quick Quiz ($_questionCount Q • 15s per question)',
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
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
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
/* ============================== USER STATS CARD =============================== */
/* =============================================================================== */

class UserStatsCard extends StatelessWidget {
  final UserData userData;

  const UserStatsCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1976D2).withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: Color(0xFF1976D2),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Stats',
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
                  _buildStatColumn(
                    context,
                    Icons.leaderboard,
                    '#${userData.rank}',
                    'Rank',
                    Colors.orange,
                  ),
                  _buildStatColumn(
                    context,
                    Icons.star,
                    '${userData.score}',
                    'Score',
                    const Color.fromARGB(255, 223, 179, 48),
                  ),
                  _buildStatColumn(
                    context,
                    Icons.monetization_on,
                    '${userData.coins}',
                    'Coins',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz, size: 16, color: Color(0xFF1976D2)),
                    const SizedBox(width: 4),
                    Text(
                      '${userData.quizzesCompleted} quizzes completed',
                      style: const TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
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
  }

  Widget _buildStatColumn(
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
}

/* =============================================================================== */
/* ======================== SCORES & LEADERBOARD PAGES =========================== */
/* =============================================================================== */

class ScoresPage extends StatelessWidget {
  const ScoresPage({super.key});

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
              Icon(Icons.history, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'My Scores',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your quiz history will appear here',
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
                          Text('Scores feature coming soon!'),
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
