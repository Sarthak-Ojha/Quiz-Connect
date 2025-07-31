import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question.dart';
import '../services/database_service.dart';

Future<void> seedQuestionsFromAsset() async {
  final String jsonString = await rootBundle.loadString(
    'assets/questions.json',
  );
  final List<dynamic> jsonList = jsonDecode(jsonString);

  for (final questionMap in jsonList) {
    final question = Question(
      category: questionMap['category'],
      question: questionMap['question'],
      options: List<String>.from(questionMap['options']),
      correctIndex: questionMap['correctIndex'],
    );
    await DatabaseService().insertQuestion(question);
  }
}
