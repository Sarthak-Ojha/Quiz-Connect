import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TestDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _leaderboardCollection = 'leaderboard';

  static Future<void> generateTestLeaderboardData() async {
    if (!kDebugMode) return; // Only run in debug mode
    
    try {
      final testUsers = [
        {
          'userId': 'test_user_1',
          'displayName': 'Quiz Master',
          'totalScore': 1500,
          'totalQuizzes': 15,
          'averageScore': 100,
          'photoUrl': 'https://randomuser.me/api/portraits/men/1.jpg',
        },
        {
          'userId': 'test_user_2',
          'displayName': 'Trivia King',
          'totalScore': 1200,
          'totalQuizzes': 12,
          'averageScore': 100,
          'photoUrl': 'https://randomuser.me/api/portraits/women/2.jpg',
        },
        {
          'userId': 'test_user_3',
          'displayName': 'Brainiac',
          'totalScore': 900,
          'totalQuizzes': 9,
          'averageScore': 100,
          'photoUrl': 'https://randomuser.me/api/portraits/men/3.jpg',
        },
      ];

      final batch = _firestore.batch();
      
      for (final user in testUsers) {
        final docRef = _firestore
            .collection(_leaderboardCollection)
            .doc(user['userId'] as String);
            
        batch.set(docRef, {
          ...user,
          'lastActivity': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('✅ Generated test leaderboard data');
    } catch (e) {
      debugPrint('❌ Error generating test data: $e');
      rethrow;
    }
  }
}
