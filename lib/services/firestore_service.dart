import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static const String _leaderboardCollection = 'leaderboard';
  static const String _usersCollection = 'users';

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // Get user document reference
  static DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection(_usersCollection).doc(userId);

  // Get leaderboard document reference
  static DocumentReference<Map<String, dynamic>> _leaderboardDoc(String userId) =>
      _firestore.collection(_leaderboardCollection).doc(userId);

  // Update user's leaderboard data
  static Future<bool> updateLeaderboardData({
    required String userId,
    required String displayName,
    String? photoUrl,
    int scoreToAdd = 0,
    int quizzesToAdd = 0,
    int? currentStreak,
    int? maxStreak,
  }) async {
    try {
      final leaderboardRef = _leaderboardDoc(userId);
      final userData = {
        'userId': userId,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'lastActivity': FieldValue.serverTimestamp(),
      };

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(leaderboardRef);
        
        if (doc.exists) {
          // Update existing document
          transaction.update(leaderboardRef, {
            ...userData,
            'totalScore': FieldValue.increment(scoreToAdd),
            'totalQuizzes': FieldValue.increment(quizzesToAdd),
            if (currentStreak != null) 'currentStreak': currentStreak,
            if (maxStreak != null) 'maxStreak': maxStreak,
            'averageScore': FieldValue.increment(0), // Will be calculated by Cloud Function
          });
        } else {
          // Create new document
          transaction.set(leaderboardRef, {
            ...userData,
            'totalScore': scoreToAdd,
            'totalQuizzes': quizzesToAdd,
            'currentStreak': currentStreak ?? 0,
            'maxStreak': maxStreak ?? 0,
            'averageScore': 0, // Will be calculated by Cloud Function
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
      // Also update user profile if needed
      if (displayName.isNotEmpty || photoUrl != null) {
        await _userDoc(userId).set({
          'displayName': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating leaderboard: $e');
      return false;
    }
  }

  // Get leaderboard stream
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLeaderboardStream({
    required String orderBy,
    int limit = 50,
  }) {
    return _firestore
        .collection(_leaderboardCollection)
        .orderBy(orderBy, descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get user's leaderboard position
  static Future<Map<String, dynamic>?> getUserLeaderboardPosition(
    String userId, {
    required String orderBy,
  }) async {
    try {
      // Get user's score
      final userDoc = await _leaderboardDoc(userId).get();
      if (!userDoc.exists) return null;
      
      final userData = userDoc.data()!;
      final userScore = userData[orderBy] ?? 0;
      
      // Get user's rank
      final countQuery = await _firestore
          .collection(_leaderboardCollection)
          .where(orderBy, isGreaterThan: userScore)
          .count()
          .get();
      
      return {
        ...userData,
        'rank': (countQuery.count ?? 0) + 1,
      };
    } catch (e) {
      debugPrint('Error getting leaderboard position: $e');
      return null;
    }
  }

  // Get top performers (users with highest average score)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getTopPerformersStream({
    int limit = 10,
    int minQuizzes = 5,
  }) {
    return _firestore
        .collection(_leaderboardCollection)
        .where('totalQuizzes', isGreaterThanOrEqualTo: minQuizzes)
        .orderBy('averageScore', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get user's rank in a specific category
  static Future<int> getUserRank(String userId, String orderBy) async {
    try {
      final position = await getUserLeaderboardPosition(
        userId,
        orderBy: orderBy,
      );
      return position?['rank'] ?? 0;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return 0;
    }
  }
}
