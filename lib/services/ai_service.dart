// lib/services/ai_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class AIService {
  static const String _apiKey = 'AIzaSyBIww_VLDxEgcxVUI5PGug1q6PHf1hj8E8';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Generate 10 quiz questions for a given topic using Gemini API
  /// Optimized for token efficiency with structured prompt
  Future<List<Question>> generateQuestions(String topic) async {
    try {
      final prompt = _buildEfficientPrompt(topic);
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        return _parseQuestionsFromResponse(content, topic);
      } else {
        debugPrint('❌ Gemini API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ AI Service Error: $e');
      rethrow;
    }
  }

  /// Build token-efficient prompt for generating questions
  String _buildEfficientPrompt(String topic) {
    return '''Generate exactly 10 multiple choice questions about "$topic".

Format each question as:
Q[number]: [question]
A) [option1]
B) [option2] 
C) [option3]
D) [option4]
CORRECT: [A/B/C/D]

Requirements:
- Questions should be educational and varied in difficulty
- Each question must have exactly 4 options
- Clearly mark the correct answer
- Keep questions concise but informative
- Cover different aspects of the topic

Example:
Q1: What is the capital of France?
A) London
B) Berlin
C) Paris
D) Madrid
CORRECT: C

Generate 10 questions now:''';
  }

  /// Parse the AI response into Question objects
  List<Question> _parseQuestionsFromResponse(String response, String topic) {
    final questions = <Question>[];
    final lines = response.split('\n');
    
    Question? currentQuestion;
    List<String> currentOptions = [];
    int correctIndex = 0;
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      // Parse question line
      if (line.startsWith('Q') && line.contains(':')) {
        // Save previous question if exists
        if (currentQuestion != null && currentOptions.length == 4) {
          questions.add(Question(
            id: currentQuestion.id,
            question: currentQuestion.question,
            options: List.from(currentOptions),
            correctIndex: correctIndex,
            category: topic,
          ));
        }
        
        // Start new question
        final questionText = line.substring(line.indexOf(':') + 1).trim();
        currentQuestion = Question(
          id: DateTime.now().millisecondsSinceEpoch + questions.length,
          question: questionText,
          options: [],
          correctIndex: 0,
          category: topic,
        );
        currentOptions.clear();
      }
      // Parse option lines
      else if (line.startsWith(RegExp(r'^[A-D]\)'))) {
        final optionText = line.substring(2).trim();
        currentOptions.add(optionText);
      }
      // Parse correct answer
      else if (line.startsWith('CORRECT:')) {
        final correctLetter = line.substring(8).trim().toUpperCase();
        switch (correctLetter) {
          case 'A':
            correctIndex = 0;
            break;
          case 'B':
            correctIndex = 1;
            break;
          case 'C':
            correctIndex = 2;
            break;
          case 'D':
            correctIndex = 3;
            break;
          default:
            correctIndex = 0;
        }
      }
    }
    
    // Add the last question
    if (currentQuestion != null && currentOptions.length == 4) {
      questions.add(Question(
        id: currentQuestion.id,
        question: currentQuestion.question,
        options: List.from(currentOptions),
        correctIndex: correctIndex,
        category: topic,
      ));
    }
    
    // Ensure we have exactly 10 questions
    if (questions.length < 10) {
      debugPrint('⚠️ Only generated ${questions.length} questions, expected 10');
    }
    
    return questions.take(10).toList();
  }

  /// Determine difficulty level based on question position
  String _getDifficultyLevel(int questionIndex) {
    if (questionIndex < 3) return 'Easy';
    if (questionIndex < 7) return 'Medium';
    return 'Hard';
  }

  /// Validate topic input
  bool isValidTopic(String topic) {
    return topic.trim().isNotEmpty && 
           topic.trim().length >= 2 && 
           topic.trim().length <= 50;
  }

  /// Get suggested topics for user
  List<String> getSuggestedTopics() {
    return [
      'Science',
      'History',
      'Geography',
      'Technology',
      'Sports',
      'Literature',
      'Mathematics',
      'Art',
      'Music',
      'Movies',
      'Food',
      'Nature',
      'Space',
      'Medicine',
      'Business',
    ];
  }
}
