import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import 'firestore_service.dart';

class LeaderboardService with ChangeNotifier {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Stream subscriptions
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _leaderboardSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _topPerformersSubscription;
  
  // State
  List<LeaderboardEntry> _leaderboardEntries = [];
  List<LeaderboardEntry> _topPerformers = [];
  LeaderboardEntry? _currentUserEntry;
  LeaderboardType _currentType = LeaderboardType.totalScore;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LeaderboardEntry> get leaderboardEntries => _leaderboardEntries;
  List<LeaderboardEntry> get topPerformers => _topPerformers;
  LeaderboardEntry? get currentUserEntry => _currentUserEntry;
  LeaderboardType get currentType => _currentType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> _cancelSubscriptions() async {
    try {
      await _leaderboardSubscription?.cancel();
      await _topPerformersSubscription?.cancel();
      _leaderboardSubscription = null;
      _topPerformersSubscription = null;
    } catch (e) {
      debugPrint('Error cancelling subscriptions: $e');
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  // Initialize leaderboard with real-time updates
  Future<void> initializeLeaderboard({
    LeaderboardType type = LeaderboardType.totalScore,
    int limit = 50,
    String? currentUserId,
  }) async {
    // Skip if already loading to prevent multiple inits
    if (_isLoading) return;
    
    try {
      _currentType = type;
      _isLoading = true;
      _error = null; // Clear any previous errors
      notifyListeners();

      // Cancel any existing subscriptions
      await _cancelSubscriptions();

      // Start new subscriptions
      await Future.wait([
        _startLeaderboardSubscription(type, limit).catchError((e) {
          debugPrint('Leaderboard subscription error: $e');
          _error = 'Failed to load leaderboard';
        }),
        _startTopPerformersSubscription().catchError((e) {
          debugPrint('Top performers subscription error: $e');
        }),
      ]);
      
      if (currentUserId != null) {
        await _updateCurrentUserPosition(currentUserId).catchError((e) {
          debugPrint('Error updating user position: $e');
        });
      }
    } catch (e) {
      _error = 'Failed to initialize leaderboard: $e';
      debugPrint('❌ Leaderboard init error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _startLeaderboardSubscription(LeaderboardType type, int limit) async {
    try {
      await _leaderboardSubscription?.cancel();
      _isLoading = true;
      notifyListeners();
      
      final orderBy = _getOrderByColumn(type);
      
      _leaderboardSubscription = FirestoreService.getLeaderboardStream(
        orderBy: orderBy,
        limit: limit,
      ).handleError((error) {
        debugPrint('Leaderboard stream error: $error');
        _error = 'Failed to load leaderboard';
        _isLoading = false;
        notifyListeners();
      }).listen(
        _processLeaderboardSnapshot,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error in leaderboard subscription: $e');
      _error = 'Error loading leaderboard';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> _startTopPerformersSubscription() async {
    try {
      await _topPerformersSubscription?.cancel();
      
      _topPerformersSubscription = FirestoreService.getTopPerformersStream()
          .handleError((error) {
            debugPrint('Top performers stream error: $error');
          })
          .listen(
            _processTopPerformersSnapshot,
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('Error in top performers subscription: $e');
      rethrow;
    }
  }
  
  void _processLeaderboardSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      if (snapshot.docs.isEmpty) {
        debugPrint('ℹ️ No leaderboard entries found in snapshot');
        _leaderboardEntries = [];
        return;
      }

      _leaderboardEntries = snapshot.docs.asMap().entries.map((entry) {
        try {
          final data = entry.value.data();
          if (data.isEmpty) {
            throw Exception('Empty document data');
          }
          
          return LeaderboardEntry.fromMap({
            ...data,
            'rank': entry.key + 1,
            'lastActivity': (data['lastActivity'] as Timestamp?)?.toDate().toIso8601String() ?? 
                           DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('❌ Error processing leaderboard entry ${entry.key}: $e');
          // Return a default entry to prevent the entire list from failing
          return LeaderboardEntry(
            userId: 'error_${entry.key}',
            displayName: 'User ${entry.key + 1}',
            totalScore: 0,
            totalQuizzes: 0,
            averageScore: 0,
            currentStreak: 0,
            maxStreak: 0,
            rank: entry.key + 1,
            lastActivity: DateTime.now(),
          );
        }
      }).toList();
      
      debugPrint('📊 Updated leaderboard with ${_leaderboardEntries.length} entries');
    } catch (e) {
      _error = 'Error processing leaderboard: $e';
      debugPrint('❌ Leaderboard processing error: $e');
      _leaderboardEntries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _processTopPerformersSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    _topPerformers = snapshot.docs.asMap().entries.map((entry) {
      final data = entry.value.data();
      return LeaderboardEntry.fromMap({
        ...data,
        'rank': entry.key + 1,
        'lastActivity': (data['lastActivity'] as Timestamp?)?.toDate().toIso8601String() ?? 
                        DateTime.now().toIso8601String(),
      });
    }).toList();
  }
  
  Future<void> _updateCurrentUserPosition(String? userId) async {
    if (userId == null) return;
    
    try {
      final orderBy = _getOrderByColumn(_currentType);
      final position = await FirestoreService.getUserLeaderboardPosition(
        userId,
        orderBy: orderBy,
      );
      
      if (position != null) {
        _currentUserEntry = LeaderboardEntry.fromMap({
          ...position,
          'lastActivity': (position['lastActivity'] as Timestamp?)?.toDate().toIso8601String() ?? 
                          DateTime.now().toIso8601String(),
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating current user position: $e');
    }
  }

  // Update leaderboard when user completes a quiz
  static Future<bool> updateUserStats({
    required String userId,
    required String displayName,
    String? photoUrl,
    int scoreToAdd = 0,
    int quizzesToAdd = 1,
    int? currentStreak,
    int? maxStreak,
  }) async {
    return await FirestoreService.updateLeaderboardData(
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      scoreToAdd: scoreToAdd,
      quizzesToAdd: quizzesToAdd,
      currentStreak: currentStreak,
      maxStreak: maxStreak,
    );
  }

  // Get user's rank in specific category
  Future<int> getUserRank(String userId, LeaderboardType type) async {
    try {
      final orderBy = _getOrderByColumn(type);
      final rank = await FirestoreService.getUserRank(userId, orderBy);
      return rank;
    } catch (e) {
      debugPrint('❌ Get user rank error: $e');
      return 0;
    }
  }

  // Change leaderboard sorting
  void changeSorting(LeaderboardType type, {int limit = 50, String? currentUserId}) {
    _currentType = type;
    _startLeaderboardSubscription(type, limit);
    _updateCurrentUserPosition(currentUserId);
  }

  // Helper method to get Firestore field name for ordering
  String _getOrderByColumn(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.totalQuizzes:
        return 'totalQuizzes';
      case LeaderboardType.totalScore:
        return 'totalScore';
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
      return _leaderboardEntries.firstWhere((entry) => entry.userId == userId);
    } catch (e) {
      return null;
    }
  }

  // Get rank emoji (kept for backward compatibility but not used)
  String _getRankEmoji(int rank) {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '${rank}.';
  }

  // Clear data
  void clearData() {
    _leaderboardSubscription?.cancel();
    _topPerformersSubscription?.cancel();
    _leaderboardEntries = [];
    _topPerformers = [];
    _currentUserEntry = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  // Get leaderboard entries with pagination
  Future<List<LeaderboardEntry>> getLeaderboardPage({
    required int page,
    required int pageSize,
    LeaderboardType type = LeaderboardType.totalScore,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final startAfter = page > 0 ? (page - 1) * pageSize : 0;
      final endBefore = startAfter + pageSize;
      
      // If we have enough cached data, return it
      if (_leaderboardEntries.length >= endBefore) {
        return _leaderboardEntries.sublist(startAfter, endBefore);
      }
      
      // Otherwise, fetch from Firestore
      final snapshot = await _firestore
          .collection('users')
          .orderBy(_getOrderByColumn(type), descending: true)
          .limit(pageSize)
          .get();
      
      _processLeaderboardSnapshot(snapshot);
      return _leaderboardEntries.sublist(
        startAfter,
        endBefore < _leaderboardEntries.length ? endBefore : _leaderboardEntries.length,
      );
    } catch (e) {
      _error = 'Failed to load leaderboard page: $e';
      log(_error!);
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
