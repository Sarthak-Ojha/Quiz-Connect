import 'dart:convert';

class Question {
  final int? id;
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;

  Question({
    this.id,
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory Question.fromMap(Map<String, dynamic> map) => Question(
    id: map['id'],
    category: map['category'],
    question: map['question'],
    options: List<String>.from(jsonDecode(map['options'])),
    correctIndex: map['correctIndex'],
  );

  Map<String, dynamic> toMap() => {
    'category': category,
    'question': question,
    'options': jsonEncode(options),
    'correctIndex': correctIndex,
  };
}
