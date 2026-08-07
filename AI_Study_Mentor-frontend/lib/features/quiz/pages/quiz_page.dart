import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/section_title.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _topicController = TextEditingController();
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() { _topicController.dispose(); super.dispose(); }

  Future<void> _generateQuiz() async {
    if (_topicController.text.trim().isEmpty) {
      setState(() => _error = 'Vui lòng nhập chủ đề');
      return;
    }
    setState(() { _isLoading = true; _questions = []; _error = null; });
    try {
      final result = await ApiService.generateQuiz(_topicController.text.trim());
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final qs = data['questions'] as List? ?? [];
        setState(() => _questions = qs.map((e) => e as Map<String, dynamic>).toList());
        if (_questions.isEmpty) setState(() => _error = 'AI không tạo được câu hỏi. Thử chủ đề khác.');
      } else {
        setState(() => _error = result['message']?.toString() ?? 'Lỗi tạo quiz');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 18), children: [
      const SectionTitle(title: 'Quiz AI'),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.softBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _topicController,
            maxLength: 200,
            decoration: InputDecoration(hintText: 'Nhập chủ đề (VD: Phương trình bậc hai)',
              counterText: '',
              hintStyle: const TextStyle(color: AppColors.muted), filled: true, fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.softBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.2)))),
          const SizedBox(height: 12),
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
          _isLoading
            ? const Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8),
                Text('AI đang tạo câu hỏi...', style: TextStyle(color: AppColors.muted, fontSize: 13))]))
            : FilledButton.icon(onPressed: _generateQuiz,
                icon: const Icon(Icons.auto_awesome), label: const Text('Tạo Quiz'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white, shape: const StadiumBorder())),
        ])),
      const SizedBox(height: 16),
      ..._questions.asMap().entries.map((e) => _QuizCard(index: e.key + 1, question: e.value)),
    ]);
  }
}

class _QuizCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> question;
  const _QuizCard({required this.index, required this.question});
  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  String? _selectedAnswer;
  String? _feedback;
  bool? _isCorrect;
  bool _isGrading = false;
  final _answerController = TextEditingController();

  @override
  void dispose() { _answerController.dispose(); super.dispose(); }

  Future<void> _submit(String answer) async {
    if (answer.trim().isEmpty || _isCorrect != null) return;
    setState(() => _isGrading = true);
    try {
      final qqId = widget.question['qqId']?.toString() ?? '';
      if (qqId.isEmpty) { setState(() { _isGrading = false; _feedback = 'Lỗi: thiếu ID câu hỏi'; }); return; }
      final result = await ApiService.gradeQuiz(qqId, answer);
      if (mounted && result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        setState(() {
          _isCorrect = data['isCorrect'] == true;
          _feedback = data['instantFeedback']?.toString() ?? '';
        });
      } else if (mounted) {
        setState(() => _feedback = result['message']?.toString() ?? 'Lỗi chấm điểm');
      }
    } catch (e) {
      if (mounted) setState(() => _feedback = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isGrading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.question['questionType']?.toString() ?? '';
    final options = (widget.question['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final questionText = widget.question['question']?.toString() ?? '';

    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _isCorrect == null ? AppColors.softBorder
          : _isCorrect! ? Colors.green.shade200 : Colors.red.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Câu ${widget.index}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(questionText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (type == 'multiple_choice' && options.isNotEmpty)
          ...options.map((opt) => RadioListTile<String>(
            value: opt, groupValue: _selectedAnswer, dense: true,
            title: Text(opt), activeColor: AppColors.primary,
            onChanged: _isCorrect != null ? null : (v) {
              setState(() => _selectedAnswer = v);
              if (v != null) _submit(v);
            }))
        else ...[
          TextField(controller: _answerController, enabled: _isCorrect == null,
            decoration: InputDecoration(hintText: 'Nhập câu trả lời...',
              border: const OutlineInputBorder(),
              suffixIcon: _isCorrect == null && !_isGrading
                ? IconButton(icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () => _submit(_answerController.text))
                : null)),
        ],
        if (_isGrading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        if (_feedback != null) Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isCorrect == true ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(_isCorrect == true ? Icons.check_circle : Icons.cancel,
              color: _isCorrect == true ? Colors.green : Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_feedback!, style: const TextStyle(fontSize: 13))),
          ])),
      ]));
  }
}
