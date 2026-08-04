import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_title.dart';
import 'quiz_play_screen.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    final quizzes =
        <({String topic, String subtitle, IconData icon, Color color})>[
          (
            topic: 'Toán học',
            subtitle: 'Đại số và hình học',
            icon: Icons.functions,
            color: const Color(0xFF2563EB),
          ),
          (
            topic: 'Tiếng Anh',
            subtitle: 'Từ vựng và ngữ pháp',
            icon: Icons.language,
            color: const Color(0xFF16A34A),
          ),
          (
            topic: 'Lập trình',
            subtitle: 'Flutter, Dart và tư duy thuật toán',
            icon: Icons.terminal,
            color: const Color(0xFF7C3AED),
          ),
        ];

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SectionTitle(title: 'Quiz luyện tập'),
        const SizedBox(height: 6),
        const Text(
          'Chọn một chủ đề để AI tạo bài luyện tập và chấm điểm ngay.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        ...quizzes.map(
          (quiz) => _QuizCard(
            topic: quiz.topic,
            subtitle: quiz.subtitle,
            icon: quiz.icon,
            color: quiz.color,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizPlayScreen(topic: quiz.topic),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.topic,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String topic;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.softBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_outline,
                color: AppColors.primary,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
