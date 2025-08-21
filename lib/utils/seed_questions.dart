import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/question.dart';
import '../services/database_service.dart';

Future<void> seedQuestionsFromAsset() async {
  final dbService = DatabaseService();

  final seededFlag = await dbService.getSetting('questionsSeeded');
  if (seededFlag == 'true') {
    debugPrint('[SEED] Questions already seeded — skipping.');
    return;
  }

  final db = await dbService.database;
  await db.delete('questions');
  debugPrint('[SEED] Existing rows deleted.');

  try {
    final jsonString = await rootBundle.loadString('assets/questions.json');
    final dynamic jsonData = jsonDecode(jsonString);

    if (jsonData is! List) {
      throw Exception('JSON root must be an array of questions');
    }

    final List<dynamic> jsonList = jsonData;
    debugPrint('[SEED] ${jsonList.length} question objects found in JSON.');

    int inserted = 0;
    for (int i = 0; i < jsonList.length; i++) {
      final dynamic item = jsonList[i];
      if (item is! Map) {
        debugPrint('[SEED] Skipping invalid item at index $i: not a Map');
        continue;
      }

      final Map<String, dynamic> questionData = Map<String, dynamic>.from(item);
      if (!questionData.containsKey('category') ||
          !questionData.containsKey('question') ||
          !questionData.containsKey('options') ||
          !questionData.containsKey('correctIndex')) {
        debugPrint(
          '[SEED] Skipping invalid question at index $i: missing required fields',
        );
        continue;
      }

      try {
        final question = Question(
          category: questionData['category'] as String,
          question: questionData['question'] as String,
          options: List<String>.from(questionData['options'] as List),
          correctIndex: questionData['correctIndex'] as int,
        );
        await dbService.insertQuestion(question);
        inserted++;
      } catch (e) {
        debugPrint('[SEED] Error processing question at index $i: $e');
        continue;
      }
    }

    debugPrint('[SEED] Inserted $inserted rows into SQLite.');

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions',
    );
    final count = countResult.first['count'];
    debugPrint('[SEED] SQLite now reports $count total question rows.');

    await dbService.insertSetting('questionsSeeded', 'true');
    debugPrint('[SEED] Flag set — seeding complete.');
  } catch (e) {
    debugPrint('[SEED] Critical error during seeding: $e');
    // Do not set seeded flag on error
  }
}
