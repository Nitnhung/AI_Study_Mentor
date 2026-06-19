import 'package:flutter/material.dart';

import '../../../core/widgets/info_tile.dart';
import '../../../core/widgets/section_title.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      children: const [
        SectionTitle(title: 'Quiz'),
        SizedBox(height: 14),
        InfoTile(
          icon: Icons.calculate_outlined,
          title: 'Quiz Toán',
          subtitle: '10 câu hỏi luyện tập',
        ),
        InfoTile(
          icon: Icons.translate,
          title: 'Quiz Tiếng Anh',
          subtitle: 'Simple Past Tense',
        ),
      ],
    );
  }
}
