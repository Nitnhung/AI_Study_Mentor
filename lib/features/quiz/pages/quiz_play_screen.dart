import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/theme/app_colors.dart';
import '../models/quiz_model.dart';

class QuizPlayScreen extends StatefulWidget {
  const QuizPlayScreen({super.key, required this.topic});

  final String topic;

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  static const _aiUrl = 'http://10.0.2.2:8000';
  static const _backendUrl = 'http://10.0.2.2:8080';

  final _answerController = TextEditingController();
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  bool _isGenerating = true;
  bool _isSubmitting = false;
  bool _isFinished = false;
  bool _resultSaved = false;
  String? _selectedAnswer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuiz() async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _questions = [];
      _currentIndex = 0;
      _isFinished = false;
      _resultSaved = false;
    });
    try {
      final response = await http.post(
        Uri.parse('$_aiUrl/ai/quiz/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile': {
            'user_id': 'demo_user',
            'education_level': 'high_school',
            'preferred_style': 'step_by_step',
            'language': 'vi',
          },
          'topic': widget.topic,
          'num_questions': 5,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final rawQuestions = data['questions'] as List<dynamic>? ?? [];
      final questions = rawQuestions
          .map(
            (item) =>
                QuizQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (questions.isEmpty) throw Exception('AI không trả về câu hỏi nào');
      if (!mounted) return;
      setState(() => _questions = questions);
    } catch (error) {
      if (mounted) setState(() => _error = 'Không thể tạo quiz: $error');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _submitCurrentAnswer() async {
    final question = _questions[_currentIndex];
    final answer = question.isMultipleChoice
        ? _selectedAnswer
        : _answerController.text.trim();
    if (answer == null || answer.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('$_aiUrl/ai/quiz/grade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile': {
            'user_id': 'demo_user',
            'education_level': 'high_school',
            'preferred_style': 'step_by_step',
            'language': 'vi',
          },
          'question_type': question.type,
          'question_payload': question.payload,
          'user_answer': answer,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      question
        ..userAnswer = answer
        ..isCorrect = data['is_correct'] == true
        ..feedback = data['instant_feedback']?.toString() ?? '';
      if (!mounted) return;
      await _showFeedback(question);
    } catch (error) {
      if (mounted) _showMessage('Không thể chấm đáp án: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showFeedback(QuizQuestion question) async {
    final correct = question.isCorrect == true;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: correct ? Colors.green : AppColors.danger,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                correct ? 'Chính xác!' : 'Chưa chính xác',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                question.feedback ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    _currentIndex == _questions.length - 1
                        ? Icons.flag_outlined
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _currentIndex == _questions.length - 1
                        ? 'Xem kết quả'
                        : 'Câu tiếp theo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) await _nextQuestion();
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answerController.clear();
      });
      return;
    }
    setState(() => _isFinished = true);
    await _saveFinalResult();
  }

  Future<void> _saveFinalResult() async {
    final correct = _questions
        .where((question) => question.isCorrect == true)
        .length;
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'quizId': widget.topic,
          'score': correct / _questions.length * 10,
          'correctAnswers': correct,
          'totalQuestions': _questions.length,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (mounted) setState(() => _resultSaved = true);
    } catch (error) {
      if (mounted) {
        _showMessage('Đã hoàn thành nhưng chưa lưu được kết quả: $error');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Widget _buildQuestionInput(QuizQuestion question) {
    if (!question.isMultipleChoice) {
      return TextField(
        controller: _answerController,
        enabled: !_isSubmitting,
        minLines: question.type == 'short_answer' ? 3 : 1,
        maxLines: question.type == 'short_answer' ? 5 : 1,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submitCurrentAnswer(),
        decoration: InputDecoration(
          hintText: question.type == 'fill_in_blank'
              ? 'Nhập từ còn thiếu...'
              : 'Nhập câu trả lời...',
          prefixIcon: Icon(
            question.type == 'fill_in_blank'
                ? Icons.edit_note
                : Icons.short_text,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Column(
      children: question.options.map((option) {
        final selected = _selectedAnswer == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: selected ? AppColors.softPrimary : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.softBorder,
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              onTap: _isSubmitting
                  ? null
                  : () => setState(() => _selectedAnswer = option),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? AppColors.primary : AppColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI đang tạo câu hỏi...'),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  size: 72,
                  color: AppColors.muted,
                ),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _fetchQuiz,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_isFinished) return _buildResult();

    final question = _questions[_currentIndex];
    final hasAnswer = question.isMultipleChoice
        ? _selectedAnswer != null
        : _answerController.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: AppColors.softPrimary,
            color: AppColors.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Text(
                  'Câu ${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  question.typeLabel,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 20,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            _buildQuestionInput(question),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, refreshButton) {
                return FilledButton.icon(
                  onPressed: (_isSubmitting || !hasAnswer)
                      ? null
                      : _submitCurrentAnswer,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Kiểm tra đáp án'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final correct = _questions
        .where((question) => question.isCorrect == true)
        .length;
    final percent = (correct / _questions.length * 100).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả quiz')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                percent >= 70
                    ? Icons.emoji_events_rounded
                    : Icons.auto_graph_rounded,
                size: 92,
                color: percent >= 70
                    ? Colors.amber.shade700
                    : AppColors.primary,
              ),
              const SizedBox(height: 18),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                ),
              ),
              Text(
                'Bạn trả lời đúng $correct/${_questions.length} câu',
                style: const TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _resultSaved
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _resultSaved
                        ? 'Đã lưu kết quả'
                        : 'Đang/chưa lưu được kết quả',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _fetchQuiz,
                  icon: const Icon(Icons.replay),
                  label: const Text('Làm quiz mới'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại danh sách'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
