import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../models/activity_model.dart';
import '../../quiz/pages/quiz_play_screen.dart';

class ContinueLearningSection extends StatefulWidget {
  const ContinueLearningSection({super.key});

  @override
  State<ContinueLearningSection> createState() =>
      _ContinueLearningSectionState();
}

class _ContinueLearningSectionState extends State<ContinueLearningSection> {
  List<QuizResult> _recentQuizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecentLearning();
  }

  Future<void> _fetchRecentLearning() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/results'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _recentQuizzes = data.map((a) => QuizResult.fromJson(a)).toList();
          _recentQuizzes.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentQuizzes.isEmpty) {
      return const _ContinueLearningCard(
        icon: Icons.lightbulb_outline,
        title: 'Bắt đầu bài học đầu tiên',
        subtitle: 'Chọn một môn học bên trên để bắt đầu',
      );
    }

    return Column(
      children: _recentQuizzes
          .take(2)
          .map(
            (quiz) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizPlayScreen(topic: quiz.quizId),
                    ),
                  );
                },
                child: _ContinueLearningCard(
                  icon: Icons.history,
                  title: 'Học lại: ${quiz.quizId}',
                  subtitle: 'Điểm cao nhất: ${quiz.score.toStringAsFixed(1)}',
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.softPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
