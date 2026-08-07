import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

class AiAnswerPage extends StatelessWidget {
  final Map<String, dynamic> answer;
  const AiAnswerPage({super.key, required this.answer});

  String _s(dynamic v) => v?.toString() ?? '';
  List<String> _l(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final content = answer;
    final directAnswer = _s(content['directAnswer'] ?? content['direct_answer']);
    final explanation = _s(content['explanation']);
    final steps = _l(content['steps']);
    final formulas = _l(content['formulasOrConcepts'] ?? content['formulas_or_concepts']);
    final simplified = _s(content['simplifiedExplanation'] ?? content['simplified_explanation']);
    final mistakes = _l(content['commonMistakes'] ?? content['common_mistakes']);
    final followUp = _l(content['followUpQuestions'] ?? content['follow_up_questions']);
    final subject = _s(content['subject']);
    final difficulty = _s(content['difficulty']);
    final qId = _s(content['questionId']);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Lời giải AI'), backgroundColor: Colors.white,
        foregroundColor: AppColors.text, actions: [
          if (qId.isNotEmpty) IconButton(icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () async {
              try {
                await ApiService.addBookmark(qId);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã lưu bookmark')));
              } catch (_) {}
            }),
        ]),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        if (subject.isNotEmpty) _tag('$subject • $difficulty'),
        if (directAnswer.isNotEmpty) _section('Đáp án', directAnswer),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Các bước giải', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 26, height: 26, alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(13)),
                child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: const TextStyle(fontSize: 14, height: 1.5))),
            ]))),
        ],
        if (explanation.isNotEmpty) _section('Giải thích', explanation),
        if (formulas.isNotEmpty) _section('Công thức / Khái niệm', formulas.join('\n• ')),
        if (simplified.isNotEmpty) _section('Giải thích đơn giản', simplified),
        if (mistakes.isNotEmpty) _section('Lỗi thường gặp', '• ${mistakes.join('\n• ')}'),
        if (followUp.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Câu hỏi luyện tập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 8),
          ...followUp.map((q) => Card(child: ListTile(title: Text(q), leading: const Icon(Icons.quiz, color: AppColors.primary)))),
        ],
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _section(String title, String content) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
        const SizedBox(height: 8),
        Container(width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.softBorder)),
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6))),
      ]));
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.softPrimary, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)));
}
