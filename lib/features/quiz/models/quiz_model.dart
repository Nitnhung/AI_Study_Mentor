class QuizQuestion {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  String? userAnswer;
  bool? isCorrect;
  String? feedback;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.payload,
    this.userAnswer,
    this.isCorrect,
    this.feedback,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['qq_id'] ?? '',
      type: json['question_type'] ?? 'multiple_choice',
      payload: json['question_payload'] ?? {},
    );
  }

  String get questionText => payload['question'] ?? '';
  List<String> get options => List<String>.from(payload['options'] ?? []);
  bool get isMultipleChoice => type == 'multiple_choice';
  String get typeLabel => switch (type) {
    'fill_in_blank' => 'Điền vào chỗ trống',
    'short_answer' => 'Tự luận ngắn',
    _ => 'Trắc nghiệm',
  };
}
