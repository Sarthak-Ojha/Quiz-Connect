import 'package:flutter/foundation.dart';
import '../models/leaderboard_entry.dart';
import 'database_service.dart';

class LeaderboardService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  List<LeaderboardEntry> _leaderboardEntries = [];
  LeaderboardEntry? _currentUserEntry;
  LeaderboardType _currentType = LeaderboardType.totalScore;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LeaderboardEntry> get leaderboardEntries => _leaderboardEntries;
  LeaderboardEntry? get currentUserEntry => _currentUserEntry;
  LeaderboardType get currentType => _currentType;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get leaderboard data
  Future<void> loadLeaderboard({
    LeaderboardType type = LeaderboardType.totalScore,
    int limit = 50,
    String? currentUserId,
  }) async {
    _isLoading = true;
    _error = null;
    _currentType = type;
    notifyListeners();

    try {
      final orderBy = _getOrderByColumn(type);
      
      // Get leaderboard data
      final leaderboardData = await _databaseService.getLeaderboardData(
        orderBy: orderBy,
        limit: limit,
      );

      // Convert to LeaderboardEntry objects
      _leaderboardEntries = leaderboardData
          .map((data) => LeaderboardEntry.fromMap(data))
          .toList();

      // Get current user's position if provided
      if (currentUserId != null) {
        final userPosition = await _databaseService.getUserLeaderboardPosition(
          currentUserId,
          orderBy: orderBy,
        );
        
        if (userPosition != null) {
          _currentUserEntry = LeaderboardEntry.fromMap(userPosition);
        }
      }

      debugPrint('📊 Loaded ${_leaderboardEntries.length} leaderboard entries');
      
    } catch (e) {
      _error = 'Failed to load leaderboard: $e';
      debugPrint('❌ Leaderboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get top performers (high average percentage)
  Future<List<LeaderboardEntry>> getTopPerformers({
    int limit = 10,
    int minQuizzes = 5,
  }) async {
    try {
      final performersData = await _databaseService.getTopPerformers(
        limit: limit,
        minQuizzes: minQuizzes,
      );

      return performersData.map((data) {
        // Convert averagePercentage to averageScore for LeaderboardEntry
        final modifiedData = Map<String, dynamic>.from(data);
        modifiedData['averageScore'] = data['averagePercentage'] ?? 0.0;
        modifiedData['lastActivity'] = DateTime.now().toIso8601String();
        return LeaderboardEntry.fromMap(modifiedData);
      }).toList();
      
    } catch (e) {
      debugPrint('❌ Top performers error: $e');
      return [];
    }
  }

  // Get user's rank in specific category
  Future<int?> getUserRank(String userId, LeaderboardType type) async {
    try {
      final orderBy = _getOrderByColumn(type);
      final userPosition = await _databaseService.getUserLeaderboardPosition(
        userId,
        orderBy: orderBy,
      );
      
      return userPosition?['rank'];
    } catch (e) {
      debugPrint('❌ Get user rank error: $e');
      return null;
    }
  }

  // Refresh leaderboard
  Future<void> refresh({String? currentUserId}) async {
    await loadLeaderboard(
      type: _currentType,
      currentUserId: currentUserId,
    );
  }

  // Helper method to get SQL column name for ordering
  String _getOrderByColumn(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.totalScore:
        return 'totalScore';
      case LeaderboardType.totalQuizzes:
        return 'totalQuizzes';
    }
  }

  // Get leaderboard entries for a specific range (for pagination)
  List<LeaderboardEntry> getEntriesInRange(int start, int end) {
    if (start < 0 || start >= _leaderboardEntries.length) return [];
    final actualEnd = end.clamp(start, _leaderboardEntries.length);
    return _leaderboardEntries.sublist(start, actualEnd);
  }

  // Find user in current leaderboard
  LeaderboardEntry? findUserInLeaderboard(String userId) {
    try {
      return _leaderboardEntries.firstWhere(
        (entry) => entry.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get medal emoji for rank
  String getMedalForRank(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  // Clear data
  void clearData() {
    _leaderboardEntries.clear();
    _currentUserEntry = null;
    _error = null;
    notifyListeners();
  }
}
