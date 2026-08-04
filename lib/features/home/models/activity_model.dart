class QuizResult {
  final String id;
  final String quizId;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime submittedAt;

  QuizResult({
    required this.id,
    required this.quizId,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.submittedAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'] ?? '',
      quizId: json['quizId'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      correctAnswers: json['correctAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
