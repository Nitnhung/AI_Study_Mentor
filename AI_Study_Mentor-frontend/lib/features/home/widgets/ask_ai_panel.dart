import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../pages/ai_answer_page.dart';

class AskAiPanel extends StatefulWidget {
  const AskAiPanel({super.key});
  @override
  State<AskAiPanel> createState() => _AskAiPanelState();
}

class _AskAiPanelState extends State<AskAiPanel> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _sendQuestion() async {
    final q = _controller.text.trim();
    // Validate
    if (q.isEmpty) {
      setState(() => _error = 'Vui lòng nhập câu hỏi.');
      return;
    }
    if (q.length < 3) {
      setState(() => _error = 'Câu hỏi quá ngắn. Hãy nhập rõ hơn.');
      return;
    }
    
    setState(() { _isLoading = true; _error = null; });
    try {
      final result = await ApiService.askAI(q);
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        _controller.clear();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AiAnswerPage(answer: result['data'] as Map<String, dynamic>)));
      } else {
        setState(() => _error = result['message']?.toString() ?? 'Lỗi xử lý câu hỏi.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi kết nối. Thử lại sau.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.softBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Hỏi AI ngay bây giờ',
          style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(controller: _controller, minLines: 3, maxLines: 5,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: 'Nhập câu hỏi học tập...\nVí dụ: Giải phương trình x² - 4 = 0',
            hintStyle: const TextStyle(color: AppColors.muted),
            counterText: '',  // ẩn bộ đếm
            filled: true, fillColor: const Color(0xFFF8FAFC),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.softBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.2)))),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
        const SizedBox(height: 12),
        Row(children: [
          const Spacer(),
          _isLoading
            ? const Row(children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('AI đang xử lý...', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              ])
            : FilledButton.icon(onPressed: _sendQuestion,
                icon: const Icon(Icons.send), label: const Text('Gửi'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white, shape: const StadiumBorder())),
        ]),
      ]),
    );
  }
}
