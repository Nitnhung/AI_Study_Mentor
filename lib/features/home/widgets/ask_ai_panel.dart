import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';

class AskAiPanel extends StatefulWidget {
  const AskAiPanel({super.key});

  @override
  State<AskAiPanel> createState() => _AskAiPanelState();
}

class _AskAiPanelState extends State<AskAiPanel> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendQuestion() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/ai/answer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'profile': {
            'user_id': 'demo_user',
            'education_level': 'high_school',
            'preferred_style': 'step_by_step',
            'language': 'vi',
          },
          'content_text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // Extract the stable mobile response fields returned by the AI service.
        // Cách lấy dữ liệu an toàn tuyệt đối, tránh lỗi Null
        String answerText = 'AI Mentor hiện không có câu trả lời.';
        // Parse defensively because providers may return partial content.
        try {
          if (data != null && data['answer'] != null) {
            final answer = data['answer'];
            final content = answer['content_data'];
            // Prefer the explanation while keeping a direct-answer fallback.
            if (content != null) {
              answerText = (content['explanation'] ?? content['direct_answer'] ?? answerText).toString();
            }
          }
        } catch (innerError) {
          debugPrint('Lỗi trích xuất dữ liệu AI: $innerError');
          answerText = 'Đã có lỗi khi xử lý câu trả lời từ AI.';
        }
        // Present the parsed answer after the widget is still mounted.
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent, // Làm mờ nền
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'AI Mentor Trả lời:',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        answerText,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đã hiểu'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        throw Exception('Lỗi kết nối AI: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hỏi AI ngay bây giờ',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Nhập câu hỏi... Ví dụ: JWT là gì?',
              hintStyle: const TextStyle(color: AppColors.muted),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.softBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RoundActionButton(icon: Icons.mic_none, onPressed: () {}),
              const SizedBox(width: 10),
              _RoundActionButton(
                icon: Icons.camera_alt_outlined,
                onPressed: () {},
              ),
              const Spacer(),
              _isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      onPressed: _sendQuestion,
                      icon: const Icon(Icons.send),
                      label: const Text('Gửi'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.primary,
      style: IconButton.styleFrom(backgroundColor: AppColors.softPrimary),
    );
  }
}
